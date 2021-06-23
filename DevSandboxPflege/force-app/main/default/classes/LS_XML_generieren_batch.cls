/*/****************************************************************************************************************************
// Erstellt 28.08.2015 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// erzeugt XML bzw. bedarf und LS
//
//**************************************************************************************************************************** 
// Test LS_XML_generieren_batch_test.cls
//****************************************************************************************************************************
//Änderungen:
//
// 02.09.2015 AM : Fehler beim Setzen des Lieferdatum (soll today())
// 03.09.2015 AM : Vermeiden der Erstullung von doppelten LB's
// 01.10.2015 BT : Anpassung Straße auf 35 Zeichen
// 16.10.2015 AM : Einbau Lieferanschrift__c in Lieferschein__c 
// 02.11.2015 AM : für 'mon' nur die Genehmigungen PG54
// 09.11.2015 BT : Anpassung Shoplieferanschrift für Status Shop 
// 16.11.2015 BT : #108205070 Abfrage, ob Lieferanschrift null ist.
                              vorname__c = ' ', wenn Kunde Vorname nicht bekannt ist. 
                              Name__c = ' ', wenn Kunde Nachname nicht bekannt ist. 
// 27.11.2015 AM : Wenn LS.Lieferanschrift__c != null dann hat dieser Anschrift das höchste Priorität für createXML  
// 17.02.2016 BT : Bei Shop-Lieferungen wird ein neues Element "OrderOptions" mit value "M" hinzugefügt       
// 02.03.2016 AM : Fehler bei 'Bedarf'   
// 03.03.2016 AM : 35 Zeichen rausgenommen.    
// 15.03.2016 AM : Partnername2 abh. von Art_der_anschrift         
// 26.05.2016 AM : Zusätzliche Prüfung auf LS.id beim Füllen LS-LPOS map   
// 23.06.2016 AM : 'dritteljährlich' war nicht erkannt
// 22.05.2017 AM :  SELECT attachment für Genehmigung mit ORDER BY
// 26.05.2017   AM : GenehmigungAttID__c grundsätzlich aus Genehmigung__r.attachmentID__c
// 17.07.2017   AM : VZ_von/bis IMMER für 1 Monat (Lieferdatum) 
// 31.07.2017   AM : Lieferdatum für Bedarf auf Basis AU:Liefertag__c
// 30.10.2017   AM : 00001314. Bei den Folgelieferungen (aus Bedarf) soll in LS-Liefertext 'Curabox Variante x' stehen. Analog zu 'jetzt liefern'
// 03.11.2017   AM : s.o. In Liefertext soll 'CBx' so wie im Auftrag stehen
// 31.12.2017    AM : run dummy query to weke up db-server
// 05.03.2018   AM : #154436331. Für die KUWV Lieferung aus Bedarf(jährlich, halbjährlich) soll die Zuz.Befreiung geprüft werden
//                   und das Feld LS.Kunde_Zuzahlung_befreit__c gesetzt. 
// 09.08.2018   BT : #158868571 It is checked whether Zuzahlungsbefreit "Nein" is false or true 
// 02.01.2019   AM : 00001859 - LS für 51 und 54 getrennt.
// 31.05.2019   AM   166181552 ( 00002039 ) - Fehler bei der Übertragung der Aufträge.  
//                  Die Liste von LP's wird nach Kunde(VZ_von sortiert. Wenn es zu "gemischten" Lieferungen für einem Kunde kommt 
//                  und die LP 51 wischen den LP's 54 in der Liste steht, wird Gruppenwechsel bei LS falsch ausgelöst.
//                  Lösung: In dem Query "ORDER BY Kunde, Produktgruppe" einsätzen
//****************************************************************************************************************************
*/

global with sharing class LS_XML_generieren_batch {
    public boolean amTest = false;
    public string lsType = '';
    public String retMsg = '';
    public list<string> errorList = new list<string>();
    
    private List<Lieferscheinposition__c> LSpos {get; set;}
    private List<Lieferscheinposition__c> Bedarf {get; set;}
    
    
    
    private Set<ID> LsSet = new Set<ID>();
    private list<Lieferschein__c> LSList = new list<Lieferschein__c>();
    private map<ID, Lieferschein__c> mapLS54 = new map<ID, Lieferschein__c>();
    private map<ID, Lieferschein__c> mapLS51 = new map<ID, Lieferschein__c>();
    private map<ID, Lieferschein__c> updMapLS = new map<ID, Lieferschein__c>();
    
    private list<Rechnung__c> RGList = new list<Rechnung__c>();
    private map<Id, list<Rechnungsposition__c>> RPMap = new map<Id, list<Rechnungsposition__c>>();
    
    private Map<ID, Anschrift__c> MapKdAnschr = new Map<ID, Anschrift__c> () ;
    private Map<ID, Anschrift__c> MapKdShopAnschr = new Map<ID, Anschrift__c> () ;  
    private Map<String, Anschrift__c> MapliefAn = new Map<string, Anschrift__c>();
    private Map<ID, Anschrift__c> MapKdPdAnschr = new Map<ID, Anschrift__c> () ;
    private Map<ID, Anschrift__c> MapLsAnschr = new Map<ID, Anschrift__c> () ;
    
    
    private Map<ID, list<Lieferscheinposition__c>> MapLsLpos = new Map<ID, list<Lieferscheinposition__c>> () ;
    private CompanyInfo__c FirmenInfo {get; set;}
    private Organization orgDetails {get; set;}
    private Anschrift__c StandardLA ;
    private Lieferschein__c Lieferschein;
    private string kdnrBeiHartmann{get; set;}
    
    public List<Genehmigung__c> GNlist = new List<Genehmigung__c>();
    // public Set<ID> GNset = new Set<ID>(); 
    public map<id, Genehmigung__c> GNmap54 = new map<id, Genehmigung__c>();
    public map<id, Genehmigung__c> GNmap51 = new map<id, Genehmigung__c>();
    
    public List<Attachment> ATTlist{get;set;}
    public map<ID, Attachment> ATmap = new map<ID, Attachment>();
    public map<ID, Attachment> newATmap = new map<ID, Attachment>();
    
    private map<id, string> kdAdNameMap = new map<id, string>();
    
    public List<Attachment> attXMLlist = new list<Attachment>();
    
    private integer maxMonLP = 0;
    
    
    
    private Map<ID, decimal> MapLsAnzPos = new Map<ID, decimal>() ;
    private List<Lieferschein__c> lpCheckList = new List<Lieferschein__c>();


    // #154436331
    private Set<id> kdZuzahlungBefreitSet = new Set<id>();
    
    global LS_XML_generieren_batch() {     
        FirmenInfo = CompanyInfo__c.getValues('Default');
        kdnrBeiHartmann = FirmenInfo.KDNR_bei_Lieferant__c;     
    }

    global LS_XML_generieren_batch(string dummy) {        
    }    
    
    // global LS_XML_generieren(ApexPages.StandardController stdController) {     
    // }

    public void createLS_bedarf() {
        lsType = 'mon'; 
        //if(LSpos != null) LSpos.Clear();
        // 31.12.2017
        list<asMail__c> dummy = [SELECT id FROM asMail__c LIMIT 1];
        
        maxMonLP = bedarfPruefen();
        LSpos = bedarfEinlesen(maxMonLP);
        createLS();
    }

    public void createLS_bedarf(set<id> kdSet) {
        lsType = 'mon';         
        LSpos = bedarfEinlesen(kdSet);
        createLS();
    }
    
    public void createLS_jetzt_liefern() {
        lsType = 'jl';  
        if(LSpos != null) LSpos.Clear();
        LSpos = jetzt_liefernEinlesen(); 
        createLS();
    }
    
    public void createLS() {
        integer anz = 0;
        Set<ID> KundeIDSet = new Set<ID>();
        // 02.01.2019
        Set<ID> Kd51Set = new Set<ID>();
        Set<ID> Kd54Set = new Set<ID>();

        map<id, id> lsAnMap = new map<id, id>();
        if (LSpos != null && LSpos.size() != 0) {
            id tempLsID = null;
            
            list<Lieferscheinposition__c> tempLpList = new list<Lieferscheinposition__c>();
                
                // Erste Durchlauf - Analyse
                for (Lieferscheinposition__c LsP : LSPos) {
                    // Set mit Kunden ID
                    if(!KundeIDset.contains(LsP.Kunde__c)) {                                                                         
                        KundeIDSet.add(LsP.Kunde__c);
                    }
                    // für Monatlich neue LsPos als Bedarf generieren
                    if(lsType == 'mon') {
                        bedarfGenerieren(LsP); 
                    }
                    else {
                        LsSet.add(LsP.Lieferschein__c);
                    }
                    
                    if(LsP.Lieferschein__r.Lieferanschrift__c != null) {
                        lsAnMap.put(LsP.Lieferschein__r.Lieferanschrift__c, LsP.Lieferschein__c);
                    }

                    // 02.01.2019 
                    if(LsP.Artikel__r.v_pos_1_Name__c == '51') {
                        Kd51Set.add(LsP.Kunde__c);
                    }
                    else {
                        Kd54Set.add(LsP.Kunde__c);
                    }
                    // 02.01.2019
                }

                
                
                system.debug('#########################alex800 LsSet.size()='  + LsSet.size());
                // Passende Genehmigung finden
                GNlist = [SELECT unbefristet_genehmigt__c, genehmigt_bis__c, genehmigt_ab__c, 
                            Name__c, Id, Kunde__c, Name, attachmentID__c 
                            FROM Genehmigung__c
                            WHERE (((genehmigt_ab__c <= TODAY) AND (genehmigt_bis__c >= TODAY)) OR (unbefristet_genehmigt__c = true))
                            AND Status__c IN ('Bewilligung', 'Teilbewilligung')
                            AND Name__c = 'PG54'
                            AND Kunde__c IN :KundeIDSet
                            ORDER BY createddate DESC];   
                system.debug('#########################alex801 GNlist.size()='  + GNlist.size());
                if((GNlist != null) && (GNlist.size() > 0)) {
                    for(Genehmigung__c gn : GNlist) {
                        // GNset.add(gn.id);
                        GNmap54.put(gn.Kunde__c, gn);
                    }
                }   
                system.debug('#########################alex802 GNmap54='  + GNmap54);
                
                GNlist = [SELECT unbefristet_genehmigt__c, genehmigt_bis__c, genehmigt_ab__c, 
                            Name__c, Id, Kunde__c, Name, attachmentID__c 
                            FROM Genehmigung__c
                            WHERE (((genehmigt_ab__c <= TODAY) AND (genehmigt_bis__c >= TODAY)) OR (unbefristet_genehmigt__c = true))
                            AND Status__c IN ('Bewilligung', 'Teilbewilligung')
                            AND Name__c = 'PG51'
                            AND Kunde__c IN :KundeIDSet
                            ORDER BY createddate DESC];   
                system.debug('#########################alex801 GNlist.size()='  + GNlist.size());
                if((GNlist != null) && (GNlist.size() > 0)) {
                    for(Genehmigung__c gn : GNlist) {
                        // GNset.add(gn.id);
                        GNmap51.put(gn.Kunde__c, gn);
                    }
                }   
                system.debug('#########################alex802 GNmap54='  + GNmap54);               
                
                // Anschrift finden
                // Lieferschein__c.Lieferanschrift__c
                if(!lsAnMap.isEmpty()) {
                List<Anschrift__c> ListLsAn = [SELECT id, Name, Stra_e__c, PLZ__c, Ort__c, Hausnummer__c, Telefon__c, 
                            interne_Notiz__c, Liefernotiz__c, komb_Adresse__c, Kunde__c
                            FROM Anschrift__c WHERE id IN :lsAnMap.keySet()];   
                    for(Anschrift__c AN : ListLsAn) {
                        MapLsAnschr.put(lsAnMap.get(AN.id), AN);
                    }                           
                }
                                
                // Standardlieferanschrift
                List<Anschrift__c> ListAn = [SELECT id, Name, Stra_e__c, PLZ__c, Ort__c, Hausnummer__c, Telefon__c, 
                            interne_Notiz__c, Liefernotiz__c, komb_Adresse__c, Kunde__c
                            FROM Anschrift__c WHERE Standardlieferanschrift__c = true AND Kunde__c IN :KundeIDset ];
                
                List<Anschrift__c> ListShopAn = [SELECT id, Name, Stra_e__c, PLZ__c, Ort__c, Hausnummer__c, Telefon__c, 
                            interne_Notiz__c, Liefernotiz__c, komb_Adresse__c, Kunde__c
                            FROM Anschrift__c WHERE Shoplieferanschrift__c = true AND Kunde__c IN :KundeIDset ];
                            
                List<Anschrift__c> ListKundeAn = [SELECT Name, Kunde__c
                            FROM Anschrift__c WHERE Art_der_Anschrift__c = 'Kundenadresse'  
                            AND Kunde__c IN :KundeIDset ];              

                system.debug('#########################alex402 ListAn.size()=' + ListAn.size());   
                system.debug('#########################alex402 ListShopAn.size()=' + ListShopAn.size());  
                            
                if (ListAn != null && ListAn.size() != 0) { 
                    for (Anschrift__c LiAn : ListAn)
                        { 
                            MapKdAnschr.put(LiAn.Kunde__c, LiAn);
                        }
                }
                
                if (ListShopAn != null && ListShopAn.size() != 0) { 
                    for (Anschrift__c LiShopAn : ListShopAn)
                        { 
                            MapKdShopAnschr.put(LiShopAn.Id, LiShopAn);
                        }
                }
 
                if (ListKundeAn != null && ListKundeAn.size() != 0) { 
                    for (Anschrift__c LiKundeAn : ListKundeAn)
                        { 
                            kdAdNameMap.put(LiKundeAn.Kunde__c, LiKundeAn.name);
                        }
                }
 
                // Sammelbestellung 
                ListAn = [SELECT Name, Stra_e__c, PLZ__c, Ort__c, Hausnummer__c, Telefon__c, 
                                interne_Notiz__c, Liefernotiz__c, komb_Adresse__c, Kunde__c
                            FROM Anschrift__c WHERE Art_der_Anschrift__c = 'Pflegedienst' 
                            AND Kunde__c IN :KundeIDset ];
                if (ListAn != null && ListAn.size() != 0) { 
                    for (Anschrift__c LiAn : ListAn)
                        { 
                            MapKdPdAnschr.put(LiAn.Kunde__c, LiAn);
                        }
                }  

                // #154436331 Zuzahlung Befreit
                List<Kunde__c> kdZuzahlungBefreitList = [SELECT id
                                                            FROM Kunde__c
                                                            WHERE id IN :KundeIDset
                                                            AND Zuzahlungsbefreit_Nein__c = false
                                                            // AND (Zuzahlung_befreit_von__c != null AND Zuzahlung_befreit_von__c <= TODAY)
                                                            // AND (Zuzahlung_befreit_bis__c != null AND Zuzahlung_befreit_bis__c >= TODAY)
                                                            ];
                if((kdZuzahlungBefreitList != null) && (kdZuzahlungBefreitList.size() > 0)) {
                    for(Kunde__c kd : kdZuzahlungBefreitList) {
                        kdZuzahlungBefreitSet.add(kd.id);
                    }
                } 



                orgDetails = [SELECT Id, Name, Street, PostalCode, City, Country, State, Fax, Phone 
                                FROM Organization 
                                WHERE Id = :UserInfo.getOrganizationId()];              
                
                // Für Monatlich LS erzeugen
                system.debug('#########################alex500 lsType=' + lsType); 
                if(lsType == 'mon') {
                    system.debug('#########################alex501 MapKdAnschr.size()=' + MapKdAnschr.size()); 
                    for(id KdID : MapKdAnschr.keySet()) {
                        ID GnID = null;
                        ID AtID = null;                 
                        if(GNmap54.containsKey(KdID)) {
                            GnID = GNmap54.get(KdID).id;
                            AtID = GNmap54.get(KdID).attachmentID__c;
                        }
                        // 02.01.2019 
                        if(Kd54Set.contains(KdID)) {
                            Lieferschein__c LS = lieferschein_erzeugen ( KdID, 'Lieferschein', '54', GnID, AtID );
                            LSlist.add(LS); 
                        }
                        if(Kd51Set.contains(KdID)) {
                            if(GNmap51.containsKey(KdID)) {
                                GnID = GNmap51.get(KdID).id;
                                AtID = GNmap51.get(KdID).attachmentID__c;
                            }
                            Lieferschein__c LS = lieferschein_erzeugen ( KdID, 'KUWV', '51', GnID, AtID );
                            LSlist.add(LS); 
                        }
                        // 02.01.2019 
                        system.debug('#########################alex502 LSlist.size()=' + LSlist.size());
                    }

                    if ((LSList != null) && (LSList.size()) > 0) { 
                        try
                        {
                            insert LSList;
                        } 
                        catch (system.Dmlexception Liefexc)
                        {
                            system.debug('#########################insert LS Liefexc=' + Liefexc);   
                        }                       
                    }
                    LSList.clear();
                    LSList = [SELECT id, Name, Kunde__c, Lieferschein_logik__c, Lieferschein_text__c, Genehmigung__c, 
                                    Genehmigung__r.attachmentID__c,
                                    GenehmigungAttID__c,
                                    Lieferanschrift__c, Lieferanschrift__r.name,
                                    Liefertext__c,
                                    Lieferadresse__c,                                   
                                    Kunde__r.Kundennummer_abena__c, 
                                    Kunde__r.Vorname__c, 
                                    Kunde__r.Name__c,
                                    Kunde__r.Lieferadresse__c,
                                    Status_DHL__c,
                                    Kunde__r.Kundennummer__c
                                FROM Lieferschein__c 
                                WHERE Lieferschein_logik__c = true];
                    
                    system.debug('#########################alex503 LSlist=' + LSlist);
                }
                else {
                    if(!LsSet.isEmpty()) {
                        LSList = [SELECT id, Name, Kunde__c, Lieferschein_logik__c, Lieferschein_text__c, Genehmigung__c, 
                                    Genehmigung__r.attachmentID__c, 
                                    GenehmigungAttID__c, 
                                    Lieferanschrift__c, Lieferanschrift__r.name,
                                    Liefertext__c,
                                    Lieferadresse__c,
                                    Kunde__r.Kundennummer_abena__c, 
                                    Kunde__r.Vorname__c, 
                                    Kunde__r.Name__c,
                                    Kunde__r.Lieferadresse__c,
                                    Status_DHL__c,
                                    Kunde__r.Kundennummer__c
                                    FROM Lieferschein__c
                                    
                                    WHERE Id IN :LsSet]; 
                        system.debug('#########################alex504 LSlist=' + LSlist);                                  
                    }                   
                }
                
                Set<string> set_addr = new Set<string>();
                if((LSList != null) && (LSList.size() > 0)) {                    
                    for (Lieferschein__c LS : LSList) {
                        if(LS.Lieferschein_text__c == '51') {
                            mapLS51.put(LS.Kunde__c, LS);    
                        }
                        else {
                            mapLS54.put(LS.Kunde__c, LS);
                        }
                        if((LS.Lieferanschrift__c == null) && (LS.Lieferadresse__c != null)) {
                            set_addr.add(LS.Lieferadresse__c);
                        }                        
                        LS.Lieferschein_logik__c = false;
                        // if(LS.Genehmigung__c == null) {
                        //     if(GNmap54.containsKey(LS.Kunde__c)) {
                        //         LS.Genehmigung__c = GNmap54.get(LS.Kunde__c).id;
                        //         LS.GenehmigungAttID__c = GNmap54.get(LS.Kunde__c).attachmentID__c;                                
                        //     }                           
                        // }
                        if(LS.Genehmigung__r.attachmentID__c != null) {
                            LS.GenehmigungAttID__c = LS.Genehmigung__r.attachmentID__c;
                        }
                    }
                    update LSList;                          
                }          
                
                if((set_addr != null) && (set_addr.size() > 0)) {
                List<Anschrift__c> ListliefAn = [SELECT id, Name, Stra_e__c, PLZ__c, Ort__c, Hausnummer__c, Telefon__c, 
                                                  interne_Notiz__c, Liefernotiz__c, komb_Adresse__c, Kunde__c
                                                  FROM Anschrift__c WHERE komb_Adresse__c IN : set_addr];
                 
                     if((ListliefAn != null) && (ListliefAn.size() > 0)) {
                         for(Anschrift__c liefAn : ListliefAn) {
                             String str = String.valueOf(liefAn.Kunde__c) + liefAn.komb_Adresse__c;
                             MapliefAn.put(str, liefAn);
                         }
                     }
                 
                }       
                
                for (Lieferscheinposition__c LsP : LSPos) {
                    // für Monatlich LS zuweisen;
                    if(lsType == 'mon') {
                        if(LsP.Artikel__r.v_pos_1_Name__c == '51') {
                            if(mapLS51.containsKey(LsP.Kunde__c)) { 
                                LsP.Lieferschein__c = mapLS51.get(LsP.Kunde__c).id;
                            }    
                        }
                        else {
                            if(mapLS54.containsKey(LsP.Kunde__c)) { 
                                LsP.Lieferschein__c = mapLS54.get(LsP.Kunde__c).id;
                                if(LsP.Auftragsposition__r.Auftrag__r.Bezeichnung__c != null) {
                                    Lieferschein__c lsCB = mapLS54.get(LsP.Kunde__c);
                                    lsCB.Liefertext__c = LsP.Auftragsposition__r.Auftrag__r.Bezeichnung__c;
                                    mapLS54.put(LsP.Kunde__c, lsCB);
                                }
                            }
                        }

                        // if(mapLS54.containsKey(LsP.Kunde__c)) {                           
                        //     LsP.Lieferschein__c = mapLS54.get(LsP.Kunde__c).id;
                        //     // AM 30.10.2017 
                        //     Lieferschein__c lsCB;
                        //     if(LsP.Auftragsposition__r.Auftrag__r.Bezeichnung__c != null) {

                        //         if(LsP.Auftragsposition__r.Auftrag__r.Bezeichnung__c.Contains('CB')) {
                        //             lsCB =  mapLS54.get(LsP.Kunde__c);
                        //             // lsCB.Liefertext__c = LsP.Auftragsposition__r.Auftrag__r.Bezeichnung__c.Replace('CB', 'Curabox Variante ');
                        //             lsCB.Liefertext__c = LsP.Auftragsposition__r.Auftrag__r.Bezeichnung__c;
                        //             mapLS54.put(LsP.Kunde__c, lsCB);
                        //         } else if(LsP.Auftragsposition__r.Auftrag__r.Bezeichnung__c.Contains('KUWV')) {
                        //             lsCB =  mapLS54.get(LsP.Kunde__c);
                        //             lsCB.Liefertext__c = LsP.Auftragsposition__r.Auftrag__r.Bezeichnung__c;
                        //             mapLS54.put(LsP.Kunde__c, lsCB);                                
                        //         }

                        //     }

                        // }
                    }
                    if((LsP.Lieferschein__c != tempLsID) && (tempLsID != null)) {
                        MapLsLpos.put(tempLsID, tempLpList);
                        tempLpList = new list<Lieferscheinposition__c>();
                        tempLpList.add(LsP);
                    }
                    else { 
                       tempLpList.add(LsP);
                    }
                    tempLsID = LsP.Lieferschein__c;                 
                } 

                MapLsLpos.put(tempLsID, tempLpList);
                try {
                    // update mapLS54.values();
                    Database.SaveResult[] sru1Err = Database.update(mapLS54.values(), false);
                    Database.SaveResult[] sru2Err = Database.update(mapLS51.values(), false);
                }
                catch(System.Exception e) {
                    system.debug(LoggingLevel.ERROR, '######################### Error e=' + e);
                }
        }
        // Produktgruppe bereinigen.
        // if(lsType == 'mon') {
        //     if((LSList != null) && (LSList.size() > 0)) {
        //         set<id> ls51set = new set<id>();
        //         for(Lieferschein__c Ls : LSList) {
        //             if(MapLsLpos.containsKey(Ls.id)) {
        //                 list<Lieferscheinposition__c> tlp = MapLsLpos.get(Ls.id);
        //                 if((tlp != null) && (tlp.size() > 0)) {
        //                     if(tlp[0].Artikel__r.v_pos_1_Name__c == '51') {
        //                         Ls.Lieferschein_text__c = '51';
        //                         if(GNmap51.containsKey(LS.Kunde__c)) {
        //                             LS.Genehmigung__c = GNmap51.get(LS.Kunde__c).id;
        //                             LS.GenehmigungAttID__c = GNmap51.get(LS.Kunde__c).attachmentID__c;                               
        //                         }                                                           
        //                     }
        //                 }
        //             }
        //         }
        //     }
        // }
        
        
        
        system.debug('#########################alex_100 MapLsLpos.size()='  + MapLsLpos.size());
                        
        // XML Generieren
        if((LSList != null) && (LSList.size() > 0)) {           
            // erstellen map mit lsid und Anzahl LP's
            set<id> anzLpSet = new set<id>();
            for(Lieferschein__c Ls : LSList) anzLpSet.add(Ls.id);
            list<AggregateResult> lsAnzPosList = [SELECT Lieferschein__c lsid, COUNT(id) anzahl 
                                                    FROM Lieferscheinposition__c
                                                    WHERE Lieferschein__c IN : anzLpSet
                                                    GROUP BY Lieferschein__c
                                                    ORDER BY Lieferschein__c
                                                    LIMIT 1000];
            if((lsAnzPosList != null) && (lsAnzPosList.size() > 0)) {
            for(AggregateResult ar : lsAnzPosList) {
                MapLsAnzPos.put((id)ar.get('lsid'), (decimal)ar.get('anzahl')); 
            }
        }               
                
            
            
            
            for(Lieferschein__c Ls : LSList) {
                if(!createXML_PH(Ls)) {
                    updMapLS.put(Ls.id, LS);
                }
                //create_invoice(Ls);
                system.debug('#########################Mansi_100 Ls=' + Ls.Id);
            }
            if((attXMLlist != null) && (attXMLlist.size() > 0)) {
                try {
                    insert attXMLlist;
                }
                catch(System.Exception e) {
                    system.debug('#########################alex800 Fehler insert XML e='  + e);
                }
            }
        }
        // insert_invoice();
        
        system.debug('#########################alex800 updMapLS.size()='  + updMapLS.size());
        // Jetzt alle DML durchführen
        
        if(!updMapLS.isEmpty()) {
            list<Attachment> AttXMLlist = [SELECT ParentId, Name, Id, Description 
                                            FROM Attachment 
                                            WHERE ParentID IN : updMapLS.keySet() ]; 
            if((AttXMLlist != null) && (AttXMLlist.size() > 0)) {
                for(Attachment atc : AttXMLlist) {
                    newATmap.put(atc.ParentId, atc);
                }
            }
                
            list<Lieferschein__c> updLSlist = updMapLS.values();
            list<Lieferbest_tigung__c> LBlist = new list<Lieferbest_tigung__c>();
            list<Lieferbest_tigung__c> LBlistU = new list<Lieferbest_tigung__c>();
            map<id, Lieferbest_tigung__c> lbUpdMap = new map<id, Lieferbest_tigung__c>();
            list<Lieferbest_tigung__c> LBlistUpd = [SELECT id, Lieferschein__c, genehmigung_att_id__c,
                                                        Anhang__c, PDFName__c, Gedruckt__c
                                                    FROM Lieferbest_tigung__c
                                                    WHERE Lieferschein__c IN : updMapLS.keySet()];
            if((LBlistUpd != null) && (LBlistUpd.size() > 0)) {
                for(Lieferbest_tigung__c LB : LBlistUpd) {
                    lbUpdMap.put(LB.Lieferschein__c, LB);
                }
            }           
            
            for(Lieferschein__c LS : updLSlist) {
                string anhang = null;
                string pdfname = null;
                if(newATmap.containsKey(LS.id)) {
                    anhang = string.valueOf(newATmap.get(LS.id).id);
                    pdfname = newATmap.get(LS.id).Name;
                }
                if(lbUpdMap.containsKey(LS.id)) {
                    Lieferbest_tigung__c LBU = lbUpdMap.get(LS.id);
                    LBU.Anhang__c = anhang;
                    LBU.genehmigung_att_id__c = LS.Genehmigung__r.attachmentID__c;
                    LBU.Gedruckt__c = false;
                    LBU.PDFName__c = pdfname;
                    LBlistU.add(LBU); 
                }
                else {
                    Lieferbest_tigung__c LB = new Lieferbest_tigung__c(Lieferschein__c = LS.id,
                                                                        genehmigung_att_id__c = LS.Genehmigung__r.attachmentID__c,
                                                                        Kunde__c = LS.Kunde__c,
                                                                        Anhang__c = anhang,
                                                                        Gedruckt__c = false,
                                                                        PDFName__c = pdfname);
                    LBlist.add(LB); 
                }
            }
            
            
            list<Lieferscheinposition__c> updLPlist = new list<Lieferscheinposition__c>();
            if(lsType == 'mon') {
                updLPlist = LSPos;
            }
            else {
                updLPlist = [SELECT id, Status__c, Lieferdatum__c
                            FROM Lieferscheinposition__c
                            WHERE Lieferschein__c IN : updMapLS.keySet()];
            }
            if((updLPlist != null) && (updLPlist.size() > 0)) {
                for(Lieferscheinposition__c LP : updLPlist) {
                    LP.Status__c = 'geliefert';
                    LP.Lieferdatum__c = date.today();
                }
            }

            // insert neue Bedarfe (nur Monatlich)
            if ((Bedarf != null) && (Bedarf.size() > 0)) {
                try {
                    if(!amTest) {insert Bedarf;
                        system.debug('####################### insert Bedarf OK Bedarf.size()=' + Bedarf.size() );
                    }
                    else {
                        system.debug('####################### testmodus!!! kein Bedarf! Bedarf.size()=' + Bedarf.size() );
                    }
                }catch (system.Dmlexception d){
                    system.debug('####################### inser Bedarf error\n'+d);
                } 
            }   
            // insert neue LB 
            if ((LBlist != null) && (LBlist.size() > 0)) {
                try {
                    insert LBlist;
                    system.debug('####################### insert LBlist OK LBlist.size()=' + LBlist.size());
                }catch (system.Dmlexception d){
                    system.debug('####################### insert LBlist error\n'+d);
                } 
            }  
            // update existierende LB 
            if ((LBlistU != null) && (LBlistU.size() > 0)) {
                try {
                    update LBlistU;
                    system.debug('####################### update LBlist OK LBlist.size()=' + LBlistU.size());
                }catch (system.Dmlexception d){
                    system.debug('####################### update LBlistU error\n'+d);
                } 
            }           
            // update Lpos
            if((updLPlist != null) && (updLPlist.size() > 0)) {
                try {
                    update updLPlist;
                    system.debug('####################### update updLPlist OK updLPlist.size()=updLPlist.size()');
                }catch (system.Dmlexception d){
                    system.debug('####################### update updLPlist error\n'+d);
                } 
            } 
            // update checkLpos
            if((lpCheckList != null) && (lpCheckList.size() > 0)) {
                try {
                    update lpCheckList;
                    system.debug('####################### update lpCheckList OK lpCheckList.size()=' + lpCheckList.size());
                }catch (system.Dmlexception d){
                    system.debug('####################### update updLPlist error\n'+d);
                } 
            } 
            
        }
    }
        
    public List<Lieferscheinposition__c> jetzt_liefernEinlesen() {
        date Heute = date.today();
        date vzVon = Heute.toStartOfMonth();
        date vzBis = Heute.addMonths(1).toStartOfMonth();   
        List<Lieferscheinposition__c> LSbed = [SELECT 
                        l.Status__c, l.Name, l.Id, 
                        l.Menge__c, l.VZ_bis__c, l.VZ_von__c,
                        l.Lieferdatum__c, 
                        l.Lieferschein__c,
                        l.Lieferschein__r.Name, 
                        l.Lieferschein__r.Lieferdatum__c, 
                        l.Lieferschein__r.Lieferanschrift__c,
                        l.Lieferschein__r.Status_DHL__c,
                        l.Artikel__r.Name, 
                        l.Artikel__r.PZN__c,
                        l.Artikel__r.a_pac_apo_Langname__c,
                        l.Artikel__r.Artikelnummer_des_Herstellers__c,
                        l.Artikel__r.Anlage_4_Preis__c,
                        l.Artikel__r.EVK__c,  
                        l.Artikel__r.v_pos_1_Name__c,
                        l.Artikel__r.Einheit__c,
                        l.Artikel__r.a_pac_apo_EAN_UPC__c,
                         
                        l.Kunde__c, 
                        l.Kunde__r.Name,                    
                        l.Kunde__r.Pflegedienst__r.Name,
                        l.Kunde__r.Pflegedienst__r.Abena_Sammellieferung__c,
                        l.Kunde__r.Krankenkasse__r.Name, 
                        l.Kunde__r.Liefermodus__c, 
                        l.Kunde__r.Art_der_Bestellung__c,
                        l.Kunde__r.Vorname__c, 
                        l.Kunde__r.Name__c, 
                        l.Kunde__r.Kundennummer_abena__c, 
                        l.Kunde__r.Versichertennummer__c, 
                        l.Kunde__r.Ort__c,
                        l.Kunde__r.PLZ__c,
                        l.Kunde__r.Stra_e__c,
                        l.Kunde__r.Geburtsdatum_text__c,  
                        l.Kunde__r.Material_Einmalhandschuhe__c,
                        l.Kunde__r.Gr_e_Einmalhandschuhe__c,
                        
                        l.Auftragsposition__c,
                        l.Auftragsposition__r.Name, 
                        l.Auftragsposition__r.Restmenge__c, 
                        l.Auftragsposition__r.Gen_Menge_Stk_Mon__c, 
                        l.Auftragsposition__r.Gen_Menge_ges__c,
                        l.Auftragsposition__r.genehmigt_bis__c, 
                        l.Auftragsposition__r.Lieferzeitraum__c,
                        l.Auftragsposition__r.Preis__c,
                        l.Auftragsposition__r.Positionsart__c,

                        l.Auftragsposition__r.Auftrag__r.Bezeichnung__c,
                        l.Auftragsposition__r.Auftrag__r.Magento_order_id_c__c
                                               
                    FROM Lieferscheinposition__c l
                    WHERE l.Status__c = 'jetzt liefern'
                    AND l.Lieferdatum__c <=  : date.today()
                    ORDER BY l.Kunde__c, l.Lieferschein__c
                    LIMIT  2000];      
        return LSbed;
    }

    public integer bedarfPruefen() {
        integer mb = 0;
        id tempKdId = null;
        date Heute = date.today();
        date vzVon = Heute.addMonths(1).toStartOfMonth();
        date vzBis = Heute.addMonths(2).toStartOfMonth().addDays(-1);  
        List<Lieferscheinposition__c> LSbed = [SELECT l.Kunde__c, l.VZ_von__c
                                                FROM Lieferscheinposition__c l
                                                WHERE l.Status__c = 'Bedarf'                                                
                                                AND l.Lieferdatum__c <= : date.today()
                                                ORDER BY l.Kunde__c, l.VZ_von__c
                                                LIMIT 650];  
        if((LSbed != null) && (LSbed.size() > 0)) {
            for(Lieferscheinposition__c lp: LSbed) {                        
                if(mb > 600) {
                    if(tempKdId != lp.Kunde__c) break;
                }
                mb++;       
                tempKdId = lp.Kunde__c;
            }
        }                                               
        return mb;
    }
    
    public List<Lieferscheinposition__c> bedarfEinlesen(integer lim) {
        date Heute = date.today();
        date vzVon = Heute.addMonths(1).toStartOfMonth();
        date vzBis = Heute.addMonths(2).toStartOfMonth().addDays(-1);                      
        List<Lieferscheinposition__c> LSbed = [SELECT 
                        l.Status__c, l.Name, l.Id, 
                        l.Menge__c, l.VZ_bis__c, l.VZ_von__c,
                        l.Lieferschein__c,
                        l.Lieferdatum__c, 
                        l.Lieferschein__r.Name, 
                        l.Lieferschein__r.Lieferdatum__c, 
                        l.Lieferschein__r.Lieferanschrift__c,
                        l.Lieferschein__r.Status_DHL__c,
                        l.Artikel__r.Name, 
                        l.Artikel__r.PZN__c,
                        l.Artikel__r.a_pac_apo_Langname__c,
                        l.Artikel__r.Artikelnummer_des_Herstellers__c,
                        l.Artikel__r.Anlage_4_Preis__c,
                        l.Artikel__r.EVK__c,  
                        l.Artikel__r.v_pos_1_Name__c,
                        l.Artikel__r.Einheit__c,
                        l.Artikel__r.a_pac_apo_EAN_UPC__c,
                         
                        l.Kunde__c, 
                        l.Kunde__r.Name,                    
                        l.Kunde__r.Pflegedienst__r.Name, 
                        l.Kunde__r.Pflegedienst__r.Abena_Sammellieferung__c,
                        l.Kunde__r.Krankenkasse__r.Name, 
                        l.Kunde__r.Liefermodus__c, 
                        l.Kunde__r.Art_der_Bestellung__c,
                        l.Kunde__r.Vorname__c, 
                        l.Kunde__r.Name__c, 
                        l.Kunde__r.Kundennummer_abena__c, 
                        l.Kunde__r.Versichertennummer__c, 
                        l.Kunde__r.Ort__c,
                        l.Kunde__r.PLZ__c,
                        l.Kunde__r.Stra_e__c,
                        l.Kunde__r.Geburtsdatum_text__c,  
                        l.Kunde__r.Material_Einmalhandschuhe__c,
                        l.Kunde__r.Gr_e_Einmalhandschuhe__c,
                        
                        l.Auftragsposition__c,
                        l.Auftragsposition__r.Name, 
                        l.Auftragsposition__r.Restmenge__c, 
                        l.Auftragsposition__r.Gen_Menge_Stk_Mon__c, 
                        l.Auftragsposition__r.Gen_Menge_ges__c,
                        l.Auftragsposition__r.genehmigt_bis__c, 
                        l.Auftragsposition__r.Lieferzeitraum__c,
                        l.Auftragsposition__r.Preis__c,
                        l.Auftragsposition__r.Positionsart__c,

                        l.Auftragsposition__r.Auftrag__r.Bezeichnung__c,
                        l.Auftragsposition__r.Auftrag__r.Magento_order_id_c__c,
                        l.Auftragsposition__r.Auftrag__r.Liefertag__c

                            
                        FROM Lieferscheinposition__c l
                        WHERE l.Status__c = 'Bedarf'                       
                        AND l.Lieferdatum__c <= : date.today()
                        ORDER BY l.Kunde__c, l.VZ_von__c 
                        LIMIT :lim 
                        ];  
        
        return LSbed;
    }  

    public List<Lieferscheinposition__c> bedarfEinlesen(set<id> kdSet) {
        date Heute = date.today();
        date vzVon = Heute.addMonths(1).toStartOfMonth();
        date vzBis = Heute.addMonths(2).toStartOfMonth().addDays(-1);                      
        List<Lieferscheinposition__c> LSbed = [SELECT 
                        l.Status__c, l.Name, l.Id, 
                        l.Menge__c, l.VZ_bis__c, l.VZ_von__c,
                        l.Lieferschein__c,
                        l.Lieferdatum__c, 
                        l.Lieferschein__r.Name, 
                        l.Lieferschein__r.Lieferdatum__c, 
                        l.Lieferschein__r.Lieferanschrift__c,
                        l.Lieferschein__r.Status_DHL__c,
                        l.Artikel__r.Name, 
                        l.Artikel__r.PZN__c,
                        l.Artikel__r.a_pac_apo_Langname__c,
                        l.Artikel__r.Artikelnummer_des_Herstellers__c,
                        l.Artikel__r.Anlage_4_Preis__c,
                        l.Artikel__r.EVK__c,  
                        l.Artikel__r.v_pos_1_Name__c,
                        l.Artikel__r.Einheit__c,
                        l.Artikel__r.a_pac_apo_EAN_UPC__c,
                         
                        l.Kunde__c, 
                        l.Kunde__r.Name,                    
                        l.Kunde__r.Pflegedienst__r.Name, 
                        l.Kunde__r.Pflegedienst__r.Abena_Sammellieferung__c,
                        l.Kunde__r.Krankenkasse__r.Name, 
                        l.Kunde__r.Liefermodus__c, 
                        l.Kunde__r.Art_der_Bestellung__c,
                        l.Kunde__r.Vorname__c, 
                        l.Kunde__r.Name__c, 
                        l.Kunde__r.Kundennummer_abena__c, 
                        l.Kunde__r.Versichertennummer__c, 
                        l.Kunde__r.Ort__c,
                        l.Kunde__r.PLZ__c,
                        l.Kunde__r.Stra_e__c,
                        l.Kunde__r.Geburtsdatum_text__c,  
                        l.Kunde__r.Material_Einmalhandschuhe__c,
                        l.Kunde__r.Gr_e_Einmalhandschuhe__c,
                        
                        l.Auftragsposition__c,
                        l.Auftragsposition__r.Name, 
                        l.Auftragsposition__r.Restmenge__c, 
                        l.Auftragsposition__r.Gen_Menge_Stk_Mon__c, 
                        l.Auftragsposition__r.Gen_Menge_ges__c,
                        l.Auftragsposition__r.genehmigt_bis__c, 
                        l.Auftragsposition__r.Lieferzeitraum__c,
                        l.Auftragsposition__r.Preis__c,
                        l.Auftragsposition__r.Positionsart__c,

                        l.Auftragsposition__r.Auftrag__r.Bezeichnung__c,
                        l.Auftragsposition__r.Auftrag__r.Magento_order_id_c__c,
                        l.Auftragsposition__r.Auftrag__r.Liefertag__c

                            
                        FROM Lieferscheinposition__c l
                        WHERE l.Status__c = 'Bedarf'                       
                        AND l.Lieferdatum__c <= : date.today()
                        AND l.Kunde__c IN :kdSet
                        // AM 31.05.2019
                        ORDER BY l.Kunde__c, l.Artikel__r.v_pos_1_Name__c, l.VZ_von__c 
                        ];  
        
        return LSbed;
    }   
          
    public void bedarfGenerieren(Lieferscheinposition__c lp) {
        date newVZvon;
        date newVZbis;  
        date wunschDatum;
        date preWunschDatum;
        
        integer lZ = 1;
        if (lp.Auftragsposition__r.Lieferzeitraum__c == 'monatlich') {lZ = 1;}
        if (lp.Auftragsposition__r.Lieferzeitraum__c == 'zweimonatlich') {lZ = 2;}
        if (lp.Auftragsposition__r.Lieferzeitraum__c == 'vierteljährlich') {lZ = 3;}
        if (lp.Auftragsposition__r.Lieferzeitraum__c == 'dritteljährlich') {lZ = 4;}
        if (lp.Auftragsposition__r.Lieferzeitraum__c == 'halbjährlich') {lZ = 6;}
        if (lp.Auftragsposition__r.Lieferzeitraum__c == 'jährlich') {lZ = 12;}

        // newVZvon = LP.VZ_bis__c.toStartOfMonth().addMonths(1);
        // newVZbis = LP.VZ_bis__c.toStartOfMonth().addMonths(lZ+1).addDays(-1);
        
        
        preWunschDatum = date.today().addMonths(lZ);
        // AM 17.07.2017 
        // calculate day of week
        // AM 31.07.2017 
        integer wunschMonat = preWunschDatum.month();
        if(lp.Auftragsposition__r.Auftrag__r.Liefertag__c != null) {
            wunschDatum = date.newinstance(preWunschDatum.year(), preWunschDatum.month(), lp.Auftragsposition__r.Auftrag__r.Liefertag__c.intvalue());
        }
        else {
            wunschDatum = preWunschDatum;
        }
        string dayOfWeek = datetime.newInstance(wunschdatum, Time.newInstance(0, 0, 0, 0)).format('E');
        // Zunächst auf Montag
        if(dayOfWeek == 'Sat') {
            wunschDatum = wunschDatum.addDays(2);
        }  
        if(dayOfWeek == 'Sun') {
            wunschDatum = wunschDatum.addDays(1);
        }   
        // Wenn der Monat nicht passt dann auf Freitag        
        if(wunschMonat != wunschDatum.month()) {
            if(lp.Auftragsposition__r.Auftrag__r.Liefertag__c != null) {
                wunschDatum = date.newinstance(preWunschDatum.year(), preWunschDatum.month(), lp.Auftragsposition__r.Auftrag__r.Liefertag__c.intvalue());
            }
            else {
                wunschDatum = preWunschDatum;
            }
            if(dayOfWeek == 'Sat') {
                wunschDatum = wunschDatum.addDays(-1);
            }  
            if(dayOfWeek == 'Sun') {
                wunschDatum = wunschDatum.addDays(-2);
            } 
        }

        newVZvon = wunschDatum.toStartOfMonth();
        newVZbis = newVZvon.addMonths(1).addDays(-1);
        
        
        if (Bedarf == null) {
            Bedarf = new List<Lieferscheinposition__c>();
        }

        system.debug('############ alex8801' + LP.Auftragsposition__r.genehmigt_bis__c);
        if ((LP.Auftragsposition__r.genehmigt_bis__c == null  ) || (LP.Auftragsposition__r.genehmigt_bis__c >= newVZbis  )) {
            system.debug('####################### Bedarf generieren. LP='+ lp.Name);
            Lieferscheinposition__c b = new Lieferscheinposition__c (Kunde__c = lp.Kunde__c,
                                                                     Menge__c = lp.Menge__c,
                                                                     Status__c = 'Bedarf',
                                                                     Artikel__c = lp.Artikel__c,
                                                                     VZ_von__c = newVZvon,
                                                                     VZ_bis__c = newVZbis,
                                                                     Lieferdatum__c = wunschDatum,
                                                                     Auftragsposition__c = LP.Auftragsposition__c                            
                                                                        ); 
            Bedarf.add(b);      
        }       
    }
    
    public Lieferschein__c lieferschein_erzeugen ( ID Kunde, String Txt, String pg, ID GnID, ID AtID ) {
        boolean error = false;
        ID Kd = Kunde ;  
        StandardLA = MapKdAnschr.get(Kd);
        if (!error) {
            date lDate = date.Today();
            // if(lDate.day() > 15) {
                // lDate = date.newinstance(date.Today().year(), date.Today().month(), 15 ); 
            // }
            
            Lieferschein = new Lieferschein__c();
            Lieferschein.Kunde__c = Kd;
            Lieferschein.Lieferdatum__c = lDate;
            Lieferschein.interne_Notiz__c = StandardLA.interne_Notiz__c;
            Lieferschein.Liefernotiz__c = StandardLA.Liefernotiz__c;
            Lieferschein.Lieferadresse__c = StandardLA.komb_Adresse__c;
            Lieferschein.Lieferanschrift__c = StandardLA.id;
            LIeferschein.Liefertext__c = Txt ;
            Lieferschein.Lieferschein_logik__c = true;
            Lieferschein.Lieferschein_text__c = pg;
            Lieferschein.Genehmigung__c = GnID;
            if(AtID != null) {
                Lieferschein.GenehmigungAttID__c = string.valueOf(AtID);
            }
            Lieferschein.Kunde_Zuzahlung_befreit__c = kdZuzahlungBefreitSet.contains(Kd);
        }
        return Lieferschein;      
    }
        
    public boolean createXML_PH(Lieferschein__c Ls) {
        boolean error = false;
        
        if(LS.Kunde__r.Vorname__c == null) LS.Kunde__r.Vorname__c = ' ';
        if(LS.Kunde__r.Name__c == null) LS.Kunde__r.Name__c = ' ';
        
        // try {
        
            Anschrift__c PdAnschr = new Anschrift__c();
            try {
                if(MapLsAnschr.containsKey(Ls.id)) {
                    PdAnschr = MapLsAnschr.get(Ls.id);
                }
                else {
                    if(Ls.Liefertext__c == 'Shop') {
                        if(Ls.Lieferanschrift__c != null) {                
                            if(MapKdShopAnschr.get(Ls.Lieferanschrift__c) != null) {
                                PdAnschr = MapKdShopAnschr.get(Ls.Lieferanschrift__c); 
                            }         
                        }
                        else {
                                PdAnschr  = MapliefAn.get(String.valueOf(Ls.Kunde__c) + Ls.Lieferadresse__c);
                        }
                    }
                    else {            
                        Anschrift__c LiAn = MapKdAnschr.get(ls.Kunde__c); 
                        PdAnschr = LiAn;       
                    }                
                }
            }
            catch(system.Exception e) {
                System.debug('###################create XML error 1:'+ e); 
                errorList.add('Create XML error 1. Lieferschein: ' + Ls.Name);        
                return true;               
            }

            integer posNo = 1;
            string docName = null;
            Datetime curDate = Datetime.now();
            Datetime delDate = Datetime.now();
            if(Ls.Lieferdatum__c != null) {         
                delDate = datetime.newInstance(Ls.Lieferdatum__c, Time.newInstance(0, 0, 0, 0));
            }  
            string lieferdatum = delDate.format('YYYYMMdd');
            string datumHeute = curDate.format('YYYYMMdd');
            string zeitJetzt = curDate.format('HHmmss');
            
            list<Lieferscheinposition__c> lpl = MapLsLpos.get(Ls.ID);
            // 26.05.2016 Prüfen Lpos 
            // System.debug(LoggingLevel.ERROR, '###################alex980 :'+lpl.size() + ' LS=' + Ls.name); 
            if((lpl != null) && (lpl.size() > 0)) {
                list<Lieferscheinposition__c> lpc = new list<Lieferscheinposition__c>();
                for(Lieferscheinposition__c LP : lpl) {
                    if(LP.Lieferschein__c == Ls.ID) lpc.add(LP);                
                }
                if((lpc != null) && (lpc.size() > 0)) {
                    lpl.clear();
                    lpl.addAll(lpc);
                } else {
                    System.debug('###################alex981 LS=' + Ls.name); 
                    return true;
                }
                
            } else {
                System.debug('###################alex982 LS=' + Ls.name); 
                return true;
            }
            // 31.05.2016
            
            if((lpl == null) || (lpl.size() == 0)) {
                if(lpl == null) {
                    System.debug('###################alex990 LS=' + Ls.name); 
                }
                else {
                    System.debug('###################alex991 LS=' + Ls.name); 
                }
                errorList.add('Create XML error. Lieferschein: ' + Ls.Name);                
                return true;
            }
            System.debug('###################alex983 :'+lpl.size() + ' LS=' + Ls.name + ' lsType=' + lsType); 
            if(lsType != 'mon') { 
                if(!MapLsAnzPos.containsKey(Ls.id)) {
                    System.debug('###################alex992 LS=' + Ls.name); 
                    return true;
                }           
                if(lpl.size() != MapLsAnzPos.get(Ls.id)) {
                    System.debug('###################alex993 LS=' + Ls.name); 
                    return true;    
                }
            }
            
            Xmlstreamwriter xmlW = new Xmlstreamwriter();
            xmlW.writeStartDocument('utf-8','1.0');
                xmlW.writeStartElement(null,'PHOrders', null);
                xmlW.writeAttribute(null,null,'xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
                docName = Ls.Name + '.XML';
                
                // PHTransfer
                xmlW.writeStartElement(null,'PHTransfer', null);
                    xmlW.writeStartElement(null,'SenderID', null);
                        xmlW.writeCharacters(kdnrBeiHartmann);
                    xmlW.writeEndElement();               
                    xmlW.writeStartElement(null,'ReceiverID', null);
                        xmlW.writeCharacters('4049500000000');
                    xmlW.writeEndElement();             
                    xmlW.writeStartElement(null,'Date', null);
                        xmlW.writeCharacters(datumHeute);
                    xmlW.writeEndElement();     
                    xmlW.writeStartElement(null,'Time', null);
                        xmlW.writeCharacters(zeitJetzt);
                    xmlW.writeEndElement(); 
                    xmlW.writeStartElement(null,'VersionID', null);
                        xmlW.writeCharacters('1.8.3');
                    xmlW.writeEndElement();                 
                xmlW.writeEndElement();
                // PHTransfer
                
                xmlW.writeStartElement(null,'Order', null);
                xmlW.writeAttribute(null,null,'type','TA');
                // 
                    try {
                    
                        xmlW.writeStartElement(null,'OrderHeader', null);
                            xmlW.writeStartElement(null,'ReferencedOrder', null);
                                xmlW.writeStartElement(null,'BuyerOrderNumber', null);
                                    xmlW.writeCharacters(Ls.Name + ' - ' + Ls.Kunde__r.Kundennummer_abena__c);
                                xmlW.writeEndElement();
                                xmlW.writeStartElement(null,'Date', null);
                                    xmlW.writeCharacters(lieferdatum);
                                xmlW.writeEndElement();
                                xmlW.writeStartElement(null,'ReferenceID', null);
                                    xmlW.writeCharacters(Ls.Name);
                                xmlW.writeEndElement();             
                            //ReferencedOrder 
                            xmlW.writeEndElement(); 
                            
                            xmlW.writeStartElement(null,'BuyerParty', null);
                                xmlW.writeStartElement(null,'PartnerID', null);
                                xmlW.writeAttribute(null,null,'type','Distributor');
                                    xmlW.writeCharacters(kdnrBeiHartmann);
                                xmlW.writeEndElement();
                                xmlW.writeStartElement(null,'PartnerName1', null);
                                    xmlW.writeCharacters(orgDetails.Name);
                                xmlW.writeEndElement(); 
                                xmlW.writeStartElement(null,'PartnerAddress', null);
                                    xmlW.writeCharacters(orgDetails.Street );
                                xmlW.writeEndElement();  
                                xmlW.writeStartElement(null,'PartnerPostalCode', null);
                                    xmlW.writeCharacters(orgDetails.PostalCode);
                                xmlW.writeEndElement();                         
                                xmlW.writeStartElement(null,'PartnerCity', null);
                                    xmlW.writeCharacters(orgDetails.City );
                                xmlW.writeEndElement();     
                                xmlW.writeStartElement(null,'PartnerCountryCode', null);
                                    xmlW.writeCharacters('DE');
                                xmlW.writeEndElement();                         
                                xmlW.writeStartElement(null,'PartnerPhone', null);
                                    xmlW.writeCharacters(FirmenInfo.Telefon__c);
                                xmlW.writeEndElement(); 
                                xmlW.writeStartElement(null,'PartnerFax', null);
                                    xmlW.writeCharacters(FirmenInfo.Fax__c);
                                xmlW.writeEndElement();                         
                            // BuyerParty
                            xmlW.writeEndElement();                 
                            
                            xmlW.writeStartElement(null,'DestinationParty', null);
                                xmlW.writeStartElement(null,'PartnerID', null);
                                xmlW.writeAttribute(null,null,'type','Distributor');
                                    // xmlW.writeCharacters(LS.Kunde__r.Kundennummer_abena__c);
                                    xmlW.writeCharacters('99999951');
                                xmlW.writeEndElement(); 
                                xmlW.writeStartElement(null,'PartnerReferenceID', null);
                                xmlW.writeAttribute(null,null,'type','Customer');
                                    xmlW.writeCharacters(string.valueOf(integer.valueOf(LS.Kunde__r.Kundennummer__c)));
                                xmlW.writeEndElement(); 
                                xmlW.writeStartElement(null,'PartnerName1', null);
                                    xmlW.writeCharacters(PdAnschr.Name);
                                xmlW.writeEndElement();                         
                                if(Ls.Lieferanschrift__c == null) {                       
                                    if(LS.Kunde__r.Lieferadresse__c != 'Adresse Patient') {                                                                
                                        if((!PdAnschr.Name.contains(LS.Kunde__r.Name__c)) && (!PdAnschr.Name.contains(LS.Kunde__r.Vorname__c))) {
                                            xmlW.writeStartElement(null,'PartnerName2', null);
                                                xmlW.writeCharacters(LS.Kunde__r.Vorname__c + ' ' + LS.Kunde__r.Name__c );
                                            xmlW.writeEndElement(); 
                                        }       
                                    }
                                }
                                else {
                                    if(kdAdNameMap.containsKey(LS.Kunde__c)) {
                                        if(LS.Lieferanschrift__r.name != kdAdNameMap.get(LS.Kunde__c))  {
                                            xmlW.writeStartElement(null,'PartnerName2', null);
                                                xmlW.writeCharacters(LS.Kunde__r.Vorname__c + ' ' + LS.Kunde__r.Name__c );
                                            xmlW.writeEndElement(); 
                                        }
                                    }
                                }
                                xmlW.writeStartElement(null,'PartnerAddress', null);
                                // wegen CC rausgenommen
                                // ist wieder da
                            if(PdAnschr.Stra_e__c != null) {
                                    if(PdAnschr.Stra_e__c.length() >= 35) { 
                                        xmlW.writeCharacters(PdAnschr.Stra_e__c.substring(0, 35) );
                                    }
                                    else {
                                        xmlW.writeCharacters(PdAnschr.Stra_e__c);
                                    }
                                }
                                // xmlW.writeCharacters(PdAnschr.Stra_e__c);
                                
                                // CC
                                xmlW.writeEndElement();     
                                xmlW.writeStartElement(null,'PartnerPostalCode', null);
                                    xmlW.writeCharacters(PdAnschr.PLZ__c);
                                xmlW.writeEndElement();     
                                xmlW.writeStartElement(null,'PartnerCity', null);
                                    xmlW.writeCharacters(PdAnschr.Ort__c );
                                xmlW.writeEndElement(); 
                                xmlW.writeStartElement(null,'PartnerCountryCode', null);
                                    xmlW.writeCharacters('DE');
                                xmlW.writeEndElement();                                                 
                            // DestinationParty
                            xmlW.writeEndElement();
                            
                            xmlW.writeStartElement(null,'SellerParty', null);
                                xmlW.writeStartElement(null,'PartnerID', null);
                                xmlW.writeAttribute(null,null,'type','EAN');
                                    xmlW.writeCharacters('4049500000000');
                                xmlW.writeEndElement();
                                xmlW.writeStartElement(null,'PartnerName1', null);
                                    xmlW.writeCharacters('Paul Hartmann AG');
                                xmlW.writeEndElement();             
                                //SellerParty
                            xmlW.writeEndElement();  
                            // OrderOptions  
                            if(Ls.Liefertext__c == 'Shop') {
                                xmlW.writeStartElement(null,'OrderOptions', null);
                                xmlW.writeStartElement(null,'Preisgruppe', null);
                                xmlW.writeCharacters('M');
                                xmlW.writeEndElement(); 
                                xmlW.writeEndElement();  
                            }    
                                    
                        // OrderHeader 
                        xmlW.writeEndElement(); 
                    }
                    catch(system.Exception e) {
                        System.debug('###################createXML orderheader error :'+ e); 
                        errorList.add('Create XML error . Lieferschein: ' + Ls.Name);        
                        return true;               
                    }

                    xmlW.writeStartElement(null,'OrderLines', null);
                    Lieferschein__c cLP = new Lieferschein__c(id=Ls.id, Kunde__c = ls.Kunde__c, Status_DHL__c = ' ');
                    
                    for(Lieferscheinposition__c lp : lpl) {
                        
                        // cLP.Status_DHL__c = cLP.Status_DHL__c + lp.name + ' ';
                        
                        try {
                            xmlW.writeStartElement(null,'OrderLine', null);
                                xmlW.writeStartElement(null,'LineNumber', null);
                                xmlW.writeAttribute(null,null,'type','TA');
                                    xmlW.writeCharacters(string.valueOf(posNo));
                                xmlW.writeEndElement();
                                xmlW.writeStartElement(null,'ProductNumber', null);
                                xmlW.writeAttribute(null,null,'type','EAN');
                                if(lp.Artikel__r.a_pac_apo_EAN_UPC__c != null) {
                                    xmlW.writeCharacters(string.valueOf(lp.Artikel__r.a_pac_apo_EAN_UPC__c));
                                }
                                else {
                                    xmlW.writeCharacters('hier EAN');
                                }
                                xmlW.writeEndElement();
                                xmlW.writeStartElement(null,'Quantity', null);
                                    xmlW.writeCharacters(string.valueOf(lp.Menge__c));
                                xmlW.writeEndElement();             
                                // OrderLine
                            xmlW.writeEndElement(); 
                            posNo++;
                        }
                        catch(system.Exception e) {
                            System.debug('###################createXML orderLine error :'+ e); 
                            errorList.add('Create XML error . Lieferschein: ' + Ls.Name);        
                            return true;               
                        }                        
                    }
                    lpCheckList.add(cLP);
                    // OrderLines
                    xmlW.writeEndElement();
                    
                // Order
                xmlW.writeEndElement();
                // =============================================
            // PHXOrders    
            xmlW.writeEndElement(); 
            xmlW.writeEndDocument();
            string xmlString = xmlW.getXmlString();
            System.debug('###################The XML :'+xmlString); 
            xmlW.close();
            
            Attachment attachment = new Attachment();
            attachment.Body = blob.valueOf(xmlString);
            attachment.Name = docName;
            attachment.ParentId = Ls.ID;
            // insert attachment;
            attXMLlist.add(attachment);
        // }
        // catch (System.Exception e) {
        //     error = true;
        //     System.debug('###################create XML error :'+e); 
        //     errorList.add('Create XML error. Lieferschein: ' + Ls.Name);           
        // }
        return error;
    }
    
    public list<Lieferscheinposition__c> readDirect(id Lsid) {
        list<Lieferscheinposition__c> retList = new list<Lieferscheinposition__c>();
        for (Lieferscheinposition__c LsP : LSPos) {
            if(LsP.Lieferschein__c == Lsid) retList.add(LsP);               
        }       
        return retList;
    }   
    
    public list<string> getErrorList() {
        return errorList;
    }
    
    public integer getErrorListSize() {
        if(errorList != null) {
            return errorList.size();
        }
        else return 0;
    }
    
    // wird nicht aufgerufen! Nur für Testabdeckung!!!  

    // wird nicht aufgerufen! Nur für Testabdeckung!!!       
    public void setLeereZeilen() {
       
    }
}