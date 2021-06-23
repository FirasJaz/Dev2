//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//      Autor:          HK
//      Stand:          22.8.2011
//      Version:        0.1
//      geändert:       HK
//      Beschreibung:   alle Routinen um Lieferscheine und Lieferscheinpositionen zu bearbeiten
//
//  erstellt am 1.1.2011
//  geändert am 22.8.2011 am 23.08.2011 deployed 
//                  -   Abrechnungszeiträume müssen ohne Lücke sein! deshalb neue Routine Abrechnugszeiten_anpassen
//  geändert am 12.9.2011 am 12.9.2011 deployed
//                  -   updateUnterschriftenLiPos eingefügt sorgt Für Unterschriften bei den Lieferpos, wenn der LS unterschrieben ist
//  geändert am 19.9.2011 am 22.10.2011 deployed !!!!!!!!!!!!
//                  -   Krankenkassenabrechnungsfeld updaten wenn nötig 
//                      (bisher wird dies nur vom LSUnterschriftTrigger gerufen, muss noch bei LiPos- und APos-Änderungen gerufen werden)
//  geändert am 18.10.2011 22.10.2011 deployed !!!!!!!!!!
//                  -   auch wenn Lieferpositionen geändert werden müssen die entsprechenden LS und Abrechnungsfelder upgedated werden
//  geändert am 30.4.2012 am 10.5.2012 deployed!
//                  - neue Funktionen hole_menge und get AZ_VZ
//  geändert am 7.9.2012 am 11.9.12 deployed!
//                  - Abfrage Positionsart auf FP contains geändert statt "Fallpauschale" in der entsprechenden Funktion
//  
//  geändert am 24.9.12 am 24.9.12. deployed (wds)
//                  - Abfrage auf 'Anl4' erweitert!
//  geändert am 16.08.2014 wds
//                  - Anpassung Für CM keine Abfrage auf Doku etc und Abfrage Positionsart__= 'privat' miteingebaut
//  geändert am 04.06.2015 wds #144 Abrechenbar nur, wenn Status 'Kunde' beim Kunden vorliegt
//
//  geändert am 21.08.2015 wds #101101224 Status "abrechenbar" muss gesetzt werden, 
//                                        wenn Status "Kündigung" und Grund "Kündigung eines bestehenden Kunden" vorliegt
//  geändert am 25.08.2015 wds #101102186 Status "Nachträgliche Ablehnung" wenn Status"Kündigung" und Grund 
//                                        "Ablehnung durch Pflegekasse"
//  geändert am 26.08.2015 BT  #100636896. Anpassung Kundenstatus
//  geändert am 22.02.2016 bt  #107705482 Nur Lieferscheinpositionen mit Status 'nicht abrechenbar' werden auf 'abrechenbar' gesetzt
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public with sharing class Lieferscheinclass {

    private static Lieferschein__c Lieferschein;
    private static List<Anschrift__c> andere_Adressen ;
    private static Anschrift__c StandardLA ;
    private static Account Versender ;
    private static String ParNameVSP = 'Standard Versandpartner';
    public  static String StandardVPName;
    private static boolean error = False;
    private static ID Kd;
    public static date aeltester_VZ_von = date.Today();
    public static date juengster_VZ_bis = date.Today();
    public static date aeltester_AZ_von = date.Today();
    public static date juengster_AZ_bis = date.Today();   
    
    public static List<Lieferscheinposition__c> Abrechnugszeiten_anpassen(ID APID){
        List <Lieferscheinposition__c> LPList = new List<Lieferscheinposition__c>{};
        Auftragsposition__c AP;
        Integer Listlen = 0;
        set<String> Statusset = new set <String>{'Bedarf', 'jetzt liefern'};
        Try {
           LPList = [Select l.VZ_von__c, l.VZ_bis__c, l.Status__c, l.Name, l.Menge__c, l.Lieferschein__c, 
                            l.Lieferdatum__c, l.LastModifiedDate, l.Kunde__c, l.Id, l.Auftragsposition__c, 
                            l.Artikel__c, l.Abrechnungsstatus_Kunde__c, l.Abrechnungsstatus_Krankenkasse__c, l.AZ_von__c, l.AZ_bis__c 
                            From Lieferscheinposition__c l 
                            Where Auftragsposition__c =: APID AND
                            Status__c in : Statusset  
                            order by Lieferdatum__c ASC Nulls Last];
             /*
             LPList = [Select l.VZ_von__c, l.VZ_bis__c, l.Status__c, l.Name, l.Menge__c, l.Lieferschein__c, 
                            l.Lieferdatum__c, l.LastModifiedDate, l.Kunde__c, 
                            l.kunde__r.status__c,l.Id, l.Auftragsposition__c, 
                            l.kunde__r.K_ndigungsgrund__c,
                            l.Artikel__c, l.Abrechnungsstatus_Kunde__c, l.Abrechnungsstatus_Krankenkasse__c, l.AZ_von__c, l.AZ_bis__c 
                            From Lieferscheinposition__c l 
                            Where Auftragsposition__c =: APID AND
                            Status__c in : Statusset  
                            order by Lieferdatum__c ASC Nulls Last];
             */                            
            AP = [Select Name, Genehmigt_ab__c, genehmigt_bis__c from Auftragsposition__c where ID =: APID];
            }
        Catch (System.listexception lexcp){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 
                'Es konnten keine weiteren Bedarfe gefunden werden ' + lexcp);
            ApexPages.addMessage(myMsg);
            error = True;
        }
            
        if (!error){
            Listlen = LPList.size();
            system.debug('Abrechnungszeiten_anpassen L�nge der zu �ndernden LP Liste '+ Listlen);
            For (integer i = 1; i < Listlen; i++){
                system.debug('Abrechnungszeiten_anpassen zu untersuchender Eintrag ' + LPList[i]);
                system.debug('Abrechnungszeiten_anpassen Eintrag vorher            ' + LPList[i-1]);
                If (LPList[i].AZ_von__c.daysbetween(LPList[i-1].AZ_bis__c) != 1){
                    system.debug('Abrechnungszeiten_anpassen zu �ndernder Eintrag ' + LPList[i]);
                    LPList[i].AZ_von__c = LPList[i-1].AZ_bis__c.adddays(1);
                    if (LPList[i].AZ_von__c > LPList[i].AZ_bis__c){
                        LPList[i].AZ_bis__c = LPList[i].AZ_von__c.addMonths(1).addDays(-1);
                        if (LPList[i].AZ_bis__c > AP.genehmigt_bis__c){
                            LPList[i].AZ_bis__c = AP.genehmigt_bis__c;
                        }
                        if (LPList[i].AZ_von__c > AP.genehmigt_bis__c){
                            LPList[i].AZ_von__c = AP.genehmigt_bis__c;
                        }
                    }
                    system.debug('Abrechnungszeiten_anpassen geänderter Eintrag ' + LPList[i]);
                }
            }
        }
        
        return LPList;  
    }

    public static List<Anschrift__c> getAdressen() {
        If ( andere_Adressen == null || andere_Adressen.size() == 0) {
            Try {
                andere_Adressen = [Select a.komb_Adresse__c, a.interne_Notiz__c, a.Standardlieferanschrift__c, a.Name, a.Liefernotiz__c, 
                                    a.Art_der_Anschrift__c 
                                    From Anschrift__c a Where Kunde__c = :Kd];
            }
            catch (System.Listexception Ansexc) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                    'Für diesen Kunden konnte keine Lieferanschrift gefunden werden! Versuchen Sie es später erneut!  ' + Ansexc);
                ApexPages.addMessage(myMsg);
                error = True;
                return null;
            }
        }       
        system.debug ('############################### Lieferschein_erzeugen Adressen ' + andere_Adressen);
        
        return andere_Adressen.clone();
    }
    
    public static Anschrift__c getStandard_Anschrift() {
        If ( StandardLA == null) {
            If (!error){
                For (Anschrift__c A : andere_Adressen) {
                    If (A.Standardlieferanschrift__c){
                        StandardLA = A;
                    }
                }
            }
        }
        system.debug ('############################### Lieferschein_erzeugen Adressen StandardLA ' + StandardLA);

        IF (StandardLA == null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                'Für diesen Kunden konnte keine Standardieferanschrift gefunden werden! Versuchen Sie es später erneut!  ');
            ApexPages.addMessage(myMsg);
            error = True;
            return null;
        }

        return StandardLA.clone();
    }
    
    public static Account getStandard_Versender() {
        If ( StandardVPName == null || StandardVPName.length() == 0 ) {
            StandardVPName = Parameterlesenclass.read_string_param (ParNameVSP);
        }
        
        If ( Versender == null ) {
            Try {
                Versender = [Select a.Name, a.Industry, a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCity, a.ID 
                                From Account a Where Industry = 'Spediteure/Logistikdienstleister' And Name = :StandardVPName];
            }
            catch (System.Listexception VSexc) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                    'Für diesen Kunden konnte kein Standardversandpartner gefunden werden! Versuchen Sie es später erneut!  ' + VSexc);
                ApexPages.addMessage(myMsg);
                error = True;
                return null;
            }       
        }
        system.debug ('############################### Lieferschein_erzeugen Versender ' + Versender);

        return Versender.clone();
    }
    
    
    public static Lieferschein__c lieferschein_erzeugen ( ID Kunde, String Txt ) {
    
        Kd = Kunde ;
        andere_Adressen = getAdressen();    
/*      If ( andere_Adressen == null || andere_Adressen.size() == 0) {
            Try {
                andere_Adressen = [Select a.komb_Adresse__c, a.interne_Notiz__c, a.Standardlieferanschrift__c, a.Name, a.Liefernotiz__c, 
                                    a.Art_der_Anschrift__c 
                                    From Anschrift__c a Where Kunde__c = :Kd];
            }
            catch (System.Listexception Ansexc) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                    'Für diesen Kunden konnte keine Lieferanschrift gefunden werden! Versuchen Sie es später erneut!  ' + Ansexc);
                ApexPages.addMessage(myMsg);
                error = True;
            }
        }       
        system.debug ('############################### Lieferschein_erzeugen Adressen ' + andere_Adressen); */
    
        StandardLA = getStandard_Anschrift();
/*      If ( StandardLA == null) {
            If (!error){
                For (Anschrift__c A : andere_Adressen) {
                    If (A.Standardlieferanschrift__c){
                        StandardLA = A;
                    }
                }
            }
        }
        system.debug ('############################### Lieferschein_erzeugen Adressen StandardLA ' + StandardLA);

        IF (StandardLA == null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                'Für diesen Kunden konnte keine Standardieferanschrift gefunden werden! Versuchen Sie es später erneut!  ');
            ApexPages.addMessage(myMsg);
            error = True;
        } */

        // Versender = getStandard_Versender();
/*      If ( StandardVPName == null || StandardVPName.length() == 0 ) {
            StandardVPName = Parameterlesenclass.read_string_param (ParNameVSP);
        }
        
        If ( Versender == null ) {
            Try {
                Versender = [Select a.Name, a.Industry, a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCity, a.ID 
                                From Account a Where Industry = 'Spediteure/Logistikdienstleister' And Name = :StandardVPName];
            }
            catch (System.Listexception VSexc) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                    'Für diesen Kunden konnte kein Standardversandpartner gefunden werden! Versuchen Sie es später erneut!  ' + VSexc);
                ApexPages.addMessage(myMsg);
                error = True;
            }       
        }
        system.debug ('############################### Lieferschein_erzeugen Versender ' + Versender); */
        
        if (!error) {
            Lieferschein = new Lieferschein__c();
            Lieferschein.Kunde__c = Kd;
            Lieferschein.Lieferdatum__c = date.Today();
            Lieferschein.interne_Notiz__c = StandardLA.interne_Notiz__c;
            Lieferschein.Liefernotiz__c = StandardLA.Liefernotiz__c;
            Lieferschein.Lieferadresse__c = StandardLA.komb_Adresse__c;
            // Lieferschein.Versandpartner__c = Versender.ID;
            LIeferschein.Liefertext__c = Txt ;

            Try
            {
                insert Lieferschein;
            } 
            catch (system.Dmlexception Liefexc)
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                    'Es konnte kein Lieferschein eingef�gt werden! Versuchen Sie es später erneut!  ' + Liefexc);
                ApexPages.addMessage(myMsg);
                error = True;
            }
        }

        return Lieferschein;
        
    }

//  kümmert sich um das Feld Abrechenbar gg�. Krankenkasse
    public static boolean updateKrankenkassenabrechnung(List<Lieferscheinposition__c> LiPos){
        error = False;
        set<ID> APIdSet = new Set<ID>{};
        List<Auftragsposition__c> APList;
        set<ID> AuftragSet = new set<id>{};
        map<id, Auftrag__c> AuftragMap;
        map<ID,Auftragsposition__c> APosMap = new map<ID,Auftragsposition__c>{};
        map<id,List<Auftragsposition__c>> AuftragPosiMap = new map<id,list<Auftragsposition__c>>{};
        map<id,Kunde__c> KundenMap;
        set<id> KundenSet = new set<id>{};
        list<Auftragsposition__c> tempList;
        Auftragsposition__c AP = new Auftragsposition__c();
    integer GenMenge = 0;
        For (Lieferscheinposition__c LP : LiPos){
            APIdSet.add(LP.Auftragsposition__c);
        }
        system.debug ('###################  updateKrankenkassenabrechnung hat folgende LiPos: ' + LiPos);
        system.debug ('###################  updateKrankenkassenabrechnung hat folgende APIDs: ' + APIdSet);
        
        if (APIdSet.size() != 0){
            try {
                APList = [Select ID, Name, Positionsart__c, Genehmigungsstatus__c, Originalgenehmigung__c,
                                    Originalrezept__c, R_ckantwort__c, Dokumentation__c, Auftrag__c, Kunde__c,
                                    Artikel__c, Artikel__r.Artikelgruppe__c, Gen_Menge_Stk_Mon__c 
                                From Auftragsposition__c
                                Where ID in :APIDSet];
                For (Auftragsposition__c A : APList){
                    APosMap.put(A.ID,A);
                    if (!AuftragSet.contains(ap.Auftrag__c)){
                      auftragSet.add(ap.auftrag__c);
                    }
                }
                AuftragMap = new map<id,auftrag__c>([select id, name, genehmigt_ab__c, 
                      genehmigt_bis__c, unbefristet_genehmigt__c, kunde__c
                      from Auftrag__c where id in :AuftragSet]);
        For (Auftragsposition__c A : APList){
          if (!KundenSet.contains(A.Kunde__c)){
            Kundenset.add(A.Kunde__c);
          }
          if (AuftragPosiMap.containskey(A.Auftrag__c)){
            tempList = AuftragPosiMap.get(A.Auftrag__c);
          }
          else{
            tempList = new List<Auftragsposition__c>{};
          }
          tempList.add(a);
          AuftragPosiMap.put(A.Auftrag__c,tempList);
        }
        KundenMap = new Map<id, Kunde__c>([select id, name from kunde__c where id in :KundenSet]);
            }
            catch (system.Listexception APosSelExc){
                system.debug ('###################  updateKrankenkassenabrechnung konnte Apos nicht lesen: ' + APOSSelExc);
                error = True;
            }
        }
// Abfrage auf privat Für CM eingef�gt und die Abfragen auf Dok und ... auskommentiert!
//
/*
        for (Lieferscheinposition__c LP : LiPos){
      system.debug('############### updateKrankenkassenabrechnung LP ' + LP );
            if (APosMap.containskey(LP.Auftragsposition__c)){
                AP = APosMap.get(LP.Auftragsposition__c);
                if (AP.Positionsart__c == 'Rezept' || 
                    AP.Positionsart__c == 'privat' || 
                    AP.Positionsart__c.contains('FP')|| 
                    AP.Positionsart__c.contains('Anl4')){
//                    if (    AP.Genehmigungsstatus__c == 'genehmigt' &&
//                            AP.Originalgenehmigung__c &&
//                            AP.Originalrezept__c &&
//                            AP.R_ckantwort__c &&
//                            AP.Dokumentation__c &&
          system.debug('########### rufe PBChckCustMonth mit Kunde ' + KundenMap.get(ap.Kunde__c));
          system.debug('########### rufe PBChckCustMonth mit Auftrag ' + AuftragMap.get(AP.Auftrag__c));
          system.debug('########### rufe PBChckCustMonth mit AuftragPosi ' + AuftragPosiMap.get(AP.Auftrag__c));
          system.debug('########### rufe PBChckCustMonth mit Lieferdatum ' + LP.Lieferdatum__c);
          system.debug('########### rufe PBChckCustMonth mit LiPos ' + LP);

          GenMenge = Genehmigung.PflegeboxcheckCustomerThisMonth(KundenMap.get(Ap.Kunde__c), AuftragMap.get(AP.Auftrag__c), 
                  AuftragPosiMap.get(AP.Auftrag__c), LP.Lieferdatum__c, integer.valueOF(LP.Menge__c));
//
//      hier wird übrerprüft, ob status abrechenbar berechtigt oder nicht:
//      Vor.: Genehmigung liegt vor,
//      Statsus des Kunden = "Kunde" oder "Kündigung" mit entsprechendem Grund
//      und Unterschrift liegt vor
//
          if (genMenge > 0 
            && LP.Unterschrift__c && (LP.kunde__r.status__c == 'Kunde'||
            (LP.kunde__r.status__c == 'Kündigung' && LP.kunde__r.K_ndigungsgrund__c == 'Kündigung eines bestehenden Kunden'))
             ){
              system.debug('########### PBChckCustMonth sagt abrechenbar ');
                            LP.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
                            LP.abrechenbare_Menge__c = genMenge;           
                    }
                    else {
                    if (LP.kunde__r.status__c == 'Kündigung' && LP.kunde__r.K_ndigungsgrund__c == 'Ablehnung durch Pflegekasse'){
                       LP.Abrechnungsstatus_Krankenkasse__c = 'Nachträgliche Ablehnung';
                       }
                       else { 
                        system.debug('########### PBChckCustMonth sagt nicht abrechenbar ');
                        LP.Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar';         
                    }
                }
            }
            else{
                system.debug ('###################  updateKrankenkassenabrechnung konnte AposID nicht in Map finden: ' + LP.Auftragsposition__c);
                error = true;
            }
        }
        */
        return error;
    }

//  macht ein update auf die Unterschrift der entsprechende LiPos und ruft update Für Abrechnugsfelder auf      
    public static boolean updateUnterschriftenLiPos(List<Lieferschein__c> newLS, List<Lieferschein__c> oldLS){
        error = false;
        List<Lieferscheinposition__c> updLiPosList = new List<Lieferscheinposition__c>{};
        List<Lieferscheinposition__c> tempList ;
        Set<ID> LSIDs = new set<ID>{};
        set<ID> KdIDset = new set<ID>{};
        set<string> HmStrset = new set<string>{};
        map<ID, Lieferschein__c> LSMap = new map<ID, Lieferschein__c>{};
        map<string, Kundenstatus__c> ksMap = new map<string, Kundenstatus__c>();
        map<id, Lieferschein__c> lsMapOld = new map<id, Lieferschein__c>();
        integer lv = 0;
        for (Lieferschein__c LS : oldLS) {
            lsMapOld.put(LS.id, LS);
        }
        
        for (Lieferschein__c LS : newLS) {
        system.debug('######################## WDS LS' + LS);
            if (LS.Unterschrift__c != lsMapOld.get(LS.id).Unterschrift__c){
                LSIDs.add(LS.ID);
                KdIDset.add(LS.Kunde__c);
                if (!LSMap.containskey(LS.ID)){
                    LSMap.put(LS.ID, LS);
                }
            }
        }
        try {
            updLiPosList = [Select  Unterschrift__c, Lieferschein__c, Kunde__c,
                                    Auftragsposition__c, Lieferdatum__c, Menge__c, Artikel__r.v_pos_1_Name__c,
                                    Auftragsposition__r.Auftrag__r.Bezeichnung__c,  Abrechnungsstatus_Krankenkasse__c
                                    FROM Lieferscheinposition__c 
                                    WHERE Lieferschein__c IN :LSIDs
                                    AND Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar'];                              
        }
        catch (System.Listexception updliPosselexc){
            error = True;
            system.debug('######################## updateUnterschriftenLiPos meldet Fehler beim select der LiPos' + updLiPosselexc);
        }
        If (!error){
            if (updLiPosList.size() != 0) {
                system.debug('########################alex001 updLiPosList.size()=' + updLiPosList.size());
                for (Lieferscheinposition__c LP : updLiPosList) {
                    if(( LP.Artikel__r.v_pos_1_Name__c == '51') || ( LP.Artikel__r.v_pos_1_Name__c == '54')) {
                        HmStrset.add('PG' + LP.Artikel__r.v_pos_1_Name__c);
                    }
                    else {
                        HmStrset.add(LP.Artikel__r.v_pos_1_Name__c);
                    }
                }
                system.debug('########################alex002 HmStrset=' + HmStrset);
                list<Kundenstatus__c> ksList = [SELECT id, Status__c, Produktgruppe__c, K_ndigungsgrund__c, Kunde__c 
                                                 FROM Kundenstatus__c 
                                                 WHERE Kunde__c IN :KdIDset
                                                 AND Produktgruppe__c IN :HmStrset];
                if((ksList != null) && (ksList.size() > 0)) {
                    for(Kundenstatus__c KS : ksList) {
                        string key = string.valueOf(KS.Kunde__c) + KS.Produktgruppe__c;
                        ksMap.put(key, KS);
                    }
                }
                system.debug('########################alex003 ksMap=' + ksMap);
                for (Lieferscheinposition__c LP : updLiPosList) {
                    system.debug('########################alex011 LP.Auftragsposition__r.Auftrag__r.Bezeichnung__c=' + LP.Auftragsposition__r.Auftrag__r.Bezeichnung__c + ' ' + LP.Auftragsposition__c);
                    if(!LP.Auftragsposition__r.Auftrag__r.Bezeichnung__c.contains('Muster')) {
                        LP.Unterschrift__c = LSMap.get(LP.Lieferschein__c).Unterschrift__c;  
                        system.debug('########################alex001 LP.Unterschrift__c=' + LP.Unterschrift__c);
                        string key = string.valueOf(LP.Kunde__c) + LP.Artikel__r.v_pos_1_Name__c;
                        if(( LP.Artikel__r.v_pos_1_Name__c == '51') || ( LP.Artikel__r.v_pos_1_Name__c == '54')) {
                            key = string.valueOf(LP.Kunde__c) + 'PG' + LP.Artikel__r.v_pos_1_Name__c;
                        }
                        system.debug('########################alex004 key=' + key);
                        if(ksMap.containskey(key)) {
                            Kundenstatus__c KS = ksMap.get(key);
                            system.debug('########################alex005 ks.status__c=' + ks.status__c);
                            if(LP.Unterschrift__c && (ks.status__c == 'Kunde'||
                                (ks.status__c == 'Kündigung'&& ks.K_ndigungsgrund__c == 'Kündigung eines bestehenden Kunden'))) {
                                LP.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
                            }   
                            else {                    
                                if (ks.status__c == 'Kündigung' && ks.K_ndigungsgrund__c == 'Ablehnung durch Pflegekasse' ) {                    
                                    LP.Abrechnungsstatus_Krankenkasse__c = 'Nachträgliche Ablehnung';
                                }
                                else {
                                    LP.Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar';
                                }
                            } 
                        }
                    } else {
                        LP.Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar'; 
                    }
                }
                // error = updateKrankenkassenabrechnung(updLiPosList);
                try {
                    system.debug('######################## updateUnterschriftenLiPos' + updLiPosList);
                    update updLiPosList;
                }
                catch (System.dmlexception updLiPosexc) {
                    error = True;
                    system.debug('######################## updateUnterschriftenLiPos meldet Fehler beim update der LiPos' + updLiPosexc);
                }
            }
        }
        return error;
    }   
//  macht ein update auf die Unterschrift der Lieferscheine (tut es nicht! s.u.) und ruft update Abrechnungsfelder auf      
    public static boolean updateabrechenbareLPs(List<Lieferscheinposition__c> LPList){
        error = False;
        system.debug(logginglevel.error, '########### updateabrechenbareLPs mit LiPos ' + LPList);

//      ACHTUNG: man ist geneigt jetzt auch auf die Lieferscheine die Unterschriften zu �bertragen (alle LPs mit Unterschr. -> Unterschr. LS
//                  und mind. eine LP ohne Unterschr. -> LS ohne Unterschr.) Das w�rde aber wiederum dazu f�hren, dass der LSTrigger 
//                  anl�uft und alle LPs wieder ver�ndert, was mind. im Falle einer LP mit keiner Unterschrift zu dem Fehler f�hren w�rde
//                  dass alle LPs dieses Lieferscheines nicht abrechenbar w�ren. 

        error = Lieferscheinclass.updateKrankenkassenabrechnung(LPList);

        If (!error){
            if (LPList.size() != 0){
                Try {
                    update LPList;
                }
                catch (System.dmlexception updLPexc) {
                    error = True;
                    system.debug('######################## updateabrechenbareLPs meldet Fehler beim update der LiPos' + updLPexc);
                }
            }
        }
        return error;
    }   
    
// sucht Für eine Auftragsposition die bisher gelieferte Menge

    public static Integer hole_gelieferte_Menge(Auftragsposition__c Apos){
        Integer Menge = 0;
        List <Lieferscheinposition__c> LiPosList;
        Try{
            LiposList = [Select VZ_von__c, VZ_bis__c, Unterschrift__c, Status__c, Menge__c, Lieferdatum__c, Kunde__c, Id, Auftragsposition__c, 
                        Artikel__c, AZ_von__c, AZ_bis__c From Lieferscheinposition__c l];
        }
        Catch (system.listexception LiPosexc){
            system.debug('######################## hole_gelieferte_Menge meldet Fehler beim select der LiPos' + LiPosexc);
            Menge = -1;     
        }
        For (Lieferscheinposition__c LP : LiPosList){
            if ( LP.Status__c == 'geliefert'){
                Menge = Menge + Integer.valueOf(LP.Menge__c);
                if ( juengster_VZ_bis < LP.VZ_bis__c ){
                    juengster_VZ_bis = LP.VZ_bis__c;
                }                   
                if ( aeltester_VZ_von > LP.VZ_von__c ){
                    aeltester_VZ_von = LP.VZ_von__c;
                }                   
                if ( juengster_AZ_bis < LP.AZ_bis__c ){
                    juengster_AZ_bis = LP.AZ_bis__c;
                }                   
                if ( aeltester_AZ_von > LP.AZ_von__c ){
                    aeltester_AZ_von = LP.AZ_von__c;
                }                   
            }
        }
        return Menge;
    }
    
// holt juengster bzw. aeltester VZ

    public static date getAZVZ (string AZ_VZ, string von_bis){
        date Datum = date.Today();
        if ( AZ_VZ == 'VZ'){
            If ( von_bis == 'von' ){
                Datum = aeltester_VZ_von;
            }
            else{
                Datum = juengster_VZ_bis;
            }
        }
        else {
            If ( von_bis == 'von' ){
                Datum = aeltester_AZ_von;
            }
            else{
                Datum = juengster_AZ_bis;
            }
        }
        return Datum;
    }    
    
     // wird nicht aufgerufen! Nur Für Testabdeckung!!!       
      public class Zeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;}
                        public String LsNr {get;set;}
                        public String Positionsnummer_PZN {get;set;}
                        public String Artikel {get;set;}
                        public String Menge {get;set;}
                        public String Me2 {get;set;}
                        public string ME {get;set;}
                        public string Brutto {get;set;}
                        public string seitenw {get;set;}
                        public string th {get; set;}
                        public string thu {get; set;}
                        public string trs {get; set;}
                        public string lDatum {get; set;}
                        public string stern {get; set;}
        }    
     
        public static void setLeereZeilen() {
            List<Zeile> pZeilen = new List<Zeile>();
            Zeile dZeile = new Zeile();
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);          
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);   
                            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);          
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);          
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);   
                            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);          
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);
               
        }
}