//*****************************************************************************************************************************
// Erstellt 19.03.2015 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: keine
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Anzeige PD's für das Generieren der Bedarfsmeldung
//
//
//****************************************************************************************************************************
//Änderungen:
//
//  08.02.2016 AM   #111303950 Einbau vod nechstes Lieferdatum (aus Bedarf) 
//  06.06.2016 wds  #1077 u #1078  Bedarfsmeldung enthält zu viele Kunden  und nicht nur Bedarf sondern auch "jetzt Liefern" einbeziehen!
//                                 'angehalten' als Status im AU wird nicht mehr ausgeschlossen --> 'auf Abruf'  
//  13.07.2016 wds  #1096      Max 20 Pflegedienste werden verabeitet  (setmaxsatz to 20)       
//  26.01.2018 MZ 	#154394914 Bedarfsmeldungen generiert obwohl Kunde auf Kündigung               
//****************************************************************************************************************************

public with sharing class Bedarfsmeldung_method {
    private map<ID, map<string, Auftrag__c>> pdKdAuMap = new map<ID, map<string, Auftrag__c>>();
    private map<string, Lieferscheinposition__c> kdaulpMap = new map<string, Lieferscheinposition__c>();
    private map<string, Lieferscheinposition__c> kdauBedMap = new map<string, Lieferscheinposition__c>();
    private Map<integer, string> monatsName = new Map<integer, string> () ;
    private List<Account> pdListAll {get; set;}
    private List<Account> pdList {get; set;}
    private Map<ID, Contact> mapCont = new Map<ID, Contact>();
    private Map<ID, integer> mapDocs = new Map<ID, integer>();
    private set<ID> pdoutSet = new set<ID>();
    
    private integer vonSatz = 0;
    private integer maxSatz = 1000;
    

  // dummy 
     public Bedarfsmeldung_method(string dummy) {
    }
       
    public Bedarfsmeldung_method() {
        list<AggregateResult> pdkdList = lesenPdMitKunden();

        if((pdkdList != null) && (pdkdList.size() > 0)) {
            for(AggregateResult ar : pdkdList) {
                Zeile bZeile = new Zeile();
                bZeile.pdName = string.valueOf(ar.get('pdname'));                           
                bZeile.anzahl = string.valueOf(ar.get('kunden'));
                Zeilen.add(bZeile); 
                system.debug('#######################WDS 001 AR= ' + ar) ;                                
            }
        }       
    }
    
    public Bedarfsmeldung_method(integer von) {
        if(von < 1000) { 
            setMaxSatz(20);
            setVonSatz(von);
        }
        set<id> pdIdSet = new set<id>();
        list<AggregateResult> pdkdList = lesenPdMitKunden();
        if((pdkdList != null) && (pdkdList.size() > 0)) {
            for(AggregateResult ar : pdkdList) {
                pdIdSet.add(string.valueOf(ar.get('pdid')));    
            }
        }
        pdListAll = lesenAllePD(pdIdSet);
        system.debug('#######################alex401 pdListAll.size()='+pdListAll.size() + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
        pdKdAuMap = createPdkdauMap(pdListAll);
        // pdList = lesenPD(); 
        pdList = pdListAll;
    }
    
    private list<AggregateResult> lesenPdMitKunden() {
        integer minActiveKunde = 3;
        try {
            bedarfsmeldungMinimumKunden__c bmc = bedarfsmeldungMinimumKunden__c.getValues('minKunden');
            minActiveKunde = integer.valueOf(bmc.minKunden__c);
            if(minActiveKunde < 1) minActiveKunde = 1;
        }
        catch(System.Exception e) {}
        list<AggregateResult> pdkdList = [SELECT Pflegedienst__r.name pdname, Pflegedienst__c pdid, COUNT(id) kunden
                    FROM Kunde__c
                    WHERE Pflegedienst__c IN (SELECT id
                                                    FROM Account
                                                    WHERE Kategorie__c = '01 Ambulante Pflegedienste'
                                                    AND Anzahl_der_Patienten__c = 'monatliche Anforderungsliste')
                    AND id IN (SELECT Kunde__c FROM Kundenstatus__c WHERE Status__c IN ('Kunde', 'Kandidat')
                    AND Produktgruppe__c IN ('PG54', 'PG51'))                   
                    GROUP BY Pflegedienst__r.name, Pflegedienst__c
                    HAVING COUNT(id) >= : minActiveKunde
                    ORDER BY Pflegedienst__r.name
                    LIMIT 2000];
                    
                    
        return pdkdList;
    }
    
    public class Zeile {
        public string pdName {get;set;}
        public string anzahl {get;set;}
        public string pbName {get;set;}
        public string lsName {get;set;}
        public string pbVor  {get;set;}
        public string liDate  {get;set;}
    }
    
    public List<Zeile> Zeilen = new List<Zeile>();

    public List<Zeile> getZeilen() {
        return Zeilen;
    }

    public map<ID, map<string, Auftrag__c>> getpdKdAuMap() {
        return pdKdAuMap;
    }
    
    public map<string, Lieferscheinposition__c> getKdAuLpMap() {
        return kdaulpMap;
    }
    
    public map<string, Lieferscheinposition__c> getKdAuBedMap() {
        return kdauBedMap;
    }
    
    public List<Account>  getPdList() {
        return pdList;
    }
    
    public Map<ID, Contact> getMapCont() {
        return mapCont;
    }
    
    public Map<ID, integer> getMapDocs() {
        return mapDocs;
    }
    
    public integer getAnzahlPD() {
        if((zeilen != null) && (zeilen.size() > 0)) {
            return zeilen.size();
        }
        else return 0;
    }   
    
    public void setMaxSatz(integer maxSatz) {
        this.maxSatz = maxSatz;
    }
    public integer getMaxSatz() {
        return maxSatz;
    }
    public void setVonSatz(integer vonSatz) {
        this.vonSatz = vonSatz;
    }
    public integer getVonSatz() {
        return vonSatz;
    }
    
    public map<id, map<string, Auftrag__c>> createPdkdauMap(List<Account> pdList) {
        map<ID, map<string, Auftrag__c>> pdKdAuMap = new map<ID, map<string, Auftrag__c>>();
        map<ID, Account> pdMap = new Map<ID, Account>();
        for(Account pdN : pdList) { 
            pdMap.put(pdN.id, pdN);
        }
        set<ID> pdSet = pdMap.keySet();
            mapCont = createMapCont(pdSet); 
// Alle laufende Aufträge für PD mit dem Key kdID-auID   
            system.debug('#######################alex411 pdSet.size()='+pdSet.size() + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
            map<string, Auftrag__c> kdauMap = lesenKundenAuftrag(pdSet);
            system.debug('#######################alex001 kdauMap.size()='+kdauMap.size()) ;
            if(!kdauMap.isEmpty()) {
                set<string> kdauSet = kdauMap.keySet();
                set<ID> kdSet = new set<ID>();
                set<ID> auSet = new set<ID>();
                for(string keyKomb : kdauSet) {
                    string[] keys = keyKomb.split('-');
                    id kdID = ID.valueOf(keys[0]);
                    id auID = ID.valueOf(keys[1]);
                    kdSet.add(kdID);
                    auSet.add(auID);
                }
// Die letzte Lieferungen mit dem Key kdID-auID 
                kdaulpMap = lesenLp(kdSet, auSet); 
                system.debug('#######################alex002 kdaulpMap.size()='+kdaulpMap.size()) ;
                kdauBedMap = lesenBedarf(kdSet, auSet); 
// Kombinierte map PD - tabelle KdAuMap<Au>             
                id tempPD = null;
                map<string, Auftrag__c> tempKdAuMap = new map<string, Auftrag__c>();
                system.debug('#######################alex004 kdauSet.size()='+kdauSet.size()) ;
                integer curRow = 0;
                for(id pdID : pdSet) {
                    tempKdAuMap = lesenAuKd(pdID, kdauMap);
                    if((tempKdAuMap != null) && (!tempKdAuMap.isEmpty())) {
                    
                    system.debug('#######################alex005 pdkdauMap.size()='+pdkdauMap.size() + ' vonSatz=' + vonSatz + ' maxSatz='+maxSatz) ;   
                        //if((curRow >= vonSatz) && (curRow < (vonSatz + maxSatz))) {
                            pdkdauMap.put(pdID, tempKdAuMap);
                            mapDocs.put(pdID, tatsAnzahlSeiten(tempKdAuMap.size()));
                            pdoutSet.add(pdID);
                        //}
                        curRow++;
                    }
                }
                
        
            }       
        return pdKdAuMap;
    }

    public map<string, Auftrag__c> lesenKundenAuftrag(set<id> pdSet) {
        // if Kundenstatus__c is 'Kündigung' it should not be queried.  26.01.2018 MZ 	#154394914   
        List<Kundenstatus__c> KuendigungList = [select kunde__c, Produktgruppe__c from Kundenstatus__c where Status__c = 'Kündigung' and  Produktgruppe__c in ('PG54','PG51')  AND Kunde__r.Pflegedienst__c IN :pdSet];
        Set<Id> CB_Kuendigung_Set = new Set<Id>();
        Set<Id> KUVW_Kuendigung_Set = new Set<Id>();
        for(Kundenstatus__c ks : KuendigungList){
            if(ks.Produktgruppe__c == 'PG54'){
                CB_Kuendigung_Set.add(ks.kunde__c);
            }
            if(ks.Produktgruppe__c == 'PG51'){
                KUVW_Kuendigung_Set.add(ks.kunde__c);
            }
        }
        
        
        map<string, Auftrag__c> kdauMap = new map<string, Auftrag__c>();
        system.debug('#######################alex412 pdSet.size()='+pdSet.size() + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
        
        list<Auftrag__c> auList = [SELECT id, Bezeichnung__c, Kunde__c,
                                            Kunde__r.Pflegedienst__c, Kunde__r.Name, 
                                            Kunde__r.Vorname__c, Kunde__r.Name__c, 
                                            Kunde__r.Kundennummer__c, Kunde__r.Versichertennummer__c, 
                                            Kunde__r.Ort__c, Kunde__r.PLZ__c, Kunde__r.Stra_e__c, 

                                            Kunde__r.Material_Einmalhandschuhe__c, Kunde__r.Gr_e_Einmalhandschuhe__c
                                FROM Auftrag__c WHERE Kunde__r.Pflegedienst__c IN :pdSet
// Abfrage wieder eingebaut und 'angehalten' ausgebaut!/wds  6.6.16                              
//                                 AND Genehmigungsstatus__c NOT IN ('abgelehnt', 'abgelaufen', 'abbestellt', 'angehalten')
                                 AND Genehmigungsstatus__c NOT IN ('abgelehnt', 'abgelaufen', 'abbestellt')

                       AND (  (Bezeichnung__c LIKE 'CB%' AND Kunde__c NOT IN :CB_Kuendigung_Set)
                           OR (Bezeichnung__c = 'KUWV' AND Kunde__c NOT IN :KUVW_Kuendigung_Set)
                           )  
                                   
                                ORDER BY Createddate DESC];
        if (auList != null && auList.size() != 0) {
            system.debug('#######################alex413 auList.size()='+auList.size() + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
            set<string> tempAuSet = new set<string>();
            for(Auftrag__c au : auList) {
                string key = string.valueOf(au.Kunde__c) + '-' + string.valueOf(au.id); 
                string tkey = string.valueOf(au.Kunde__c) + '-' + au.Bezeichnung__c; 
                if(!tempAuSet.contains(tkey)) {
                    tempAuSet.add(tkey);
                    if(!kdauMap.containsKey(key)) {
                        kdauMap.put(key, au);
                        system.debug('#######################alex414 key='+key + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
                    }
                    else {
                        system.debug('#######################alex415 key='+key + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
                    }
                }
            }
        }       
        return kdauMap;
    }   

    public map<string, Lieferscheinposition__c> lesenLp(set<id> kdSet, set<id> auSet) {
        map<string, Lieferscheinposition__c> kdaulpMap = new map<string, Lieferscheinposition__c>();
        date Heute = date.today(); 
        list<Lieferscheinposition__c> LPlist = [SELECT id, Name, Lieferschein__r.Name, Lieferschein__r.Lieferdatum__c,
                                                        Auftragsposition__r.Auftrag__c,
                                                        Auftragsposition__r.Auftrag__r.Bezeichnung__c, 
                                                        Kunde__c
                                                FROM Lieferscheinposition__c 
                                                WHERE Status__c = 'geliefert'
                                                AND Kunde__c IN :kdSet
                                                AND Auftragsposition__r.Auftrag__c IN :auSet
                                                
                                                ORDER BY Kunde__c, Lieferschein__r.Lieferdatum__c DESC];
        if((LPlist != null) && (LPlist.size() > 0)) {
            system.debug('#########################alex001 lpList.size()=' + lpList.size());
            for(Lieferscheinposition__c LP : LPlist) {
                string key = string.valueOf(LP.Kunde__c) + '-' + string.valueOf(LP.Auftragsposition__r.Auftrag__c);  
                if(!kdaulpMap.containsKey(key)) {
                    kdaulpMap.put(key, LP);
                }
                else {
                    Lieferscheinposition__c LPt = kdaulpMap.get(key);
                    if(LPt.Lieferschein__r.Lieferdatum__c < LP.Lieferschein__r.Lieferdatum__c) {
                        kdaulpMap.put(key, LP);
                    }
                }
            }
        }       
        
        return kdaulpMap;
    }
    
    public map<string, Lieferscheinposition__c> lesenBedarf(set<id> kdSet, set<id> auSet) {
        map<string, Lieferscheinposition__c> kdauBedMap = new map<string, Lieferscheinposition__c>();
        list<Lieferscheinposition__c> LPlist = [SELECT id, Lieferdatum__c,
                                                        Auftragsposition__r.Auftrag__c,
                                                        Kunde__c
                                                FROM Lieferscheinposition__c 
                                                WHERE (Status__c = 'Bedarf' OR Status__c = 'jetzt liefern')
                                                AND Kunde__c IN :kdSet
                                                AND Auftragsposition__r.Auftrag__c IN :auSet                                                
                                                ORDER BY Kunde__c, Lieferdatum__c DESC];
        if((LPlist != null) && (LPlist.size() > 0)) {
            system.debug('#########################alex001 lpList.size()=' + lpList.size());
            for(Lieferscheinposition__c LP : LPlist) {
                string key = string.valueOf(LP.Kunde__c) + '-' + string.valueOf(LP.Auftragsposition__r.Auftrag__c);  
                if(!kdauBedMap.containsKey(key)) {
                    kdauBedMap.put(key, LP);
                }
                else {
                    Lieferscheinposition__c LPt = kdauBedMap.get(key);
                    if(LPt.Lieferdatum__c < LP.Lieferdatum__c) {
                        kdauBedMap.put(key, LP);
                    }
                }
            }
        }       
        
        return kdauBedMap;
    }
    
    public map<string, Auftrag__c> lesenAuKd(id pdID, map<string, Auftrag__c> kdauMap) {
        map<string, Auftrag__c> tempKdAuMap = new map<string, Auftrag__c>();
        set<string> keys = KdAuMap.keySet();
        List<string> keySub = new List<string>();
        for(string key : keys) {
            Auftrag__c au = KdAuMap.get(key);
            if((au != null) && (au.Kunde__r.Pflegedienst__c == pdID)) {
                    keySub.add(au.Kunde__r.Name__c + ':' + key);
            }
        }
        // innerhalb PD sortieren nach Name
        if(keySub.size() > 0) {
            keySub.sort();
            for(string tkey : keySub) {
                string[] tk = tkey.split(':');
                tempKdAuMap.put(tk[1], KdAuMap.get(tk[1])); 
            }
        }
        return tempKdAuMap;
    }

    public List<Account>  lesenPD() {
        if((pdoutSet != null) && (pdoutSet.size() > 0)) {
        List<Account> pdList = [SELECT id, Name, BillingCity, BillingPostalCode,  BillingStreet, Fax
                                FROM Account
                                WHERE id IN : pdoutSet 
                                ORDER BY Name
                                LIMIT 1000];
        return pdList;  
        }
        else return null;
    }
    
    public List<Account>  lesenAllePD() {
        
        List<Account> pdList = [SELECT id, Name, BillingCity, BillingPostalCode,  BillingStreet, Fax
                                FROM Account
                                WHERE Kategorie__c = '01 Ambulante Pflegedienste'
                                AND Anzahl_der_Patienten__c = 'monatliche Anforderungsliste'
                                ORDER BY Name
                                LIMIT 1000];
                                
                                
                                
                                
        return pdList;  
    }

    public List<Account>  lesenAllePD(set<id> pdIdSet) {        
        List<Account> pdList = [SELECT id, Name, BillingCity, BillingPostalCode,  BillingStreet, Fax
                                FROM Account
                                WHERE id IN : pdIdSet
                                ORDER BY Name                               
                                LIMIT : maxSatz
                                OFFSET : vonSatz];                  
        return pdList;  
    }   
    
    private map<ID, Contact> createMapCont(set<id> pdSet) {
        Map<ID, Contact> mapCont = new Map<ID, Contact>();
        list<Contact> ContPD = [SELECT Name, AccountId FROM Contact
              WHERE AccountId IN :pdSet
          //      AND Art_des_Kontakts__c = 'Ansprechpartner' 
          //      AND Level__c = 'Primary'
              ];
        if ((ContPD != null) && (ContPD.size() > 0)) {
          for(Contact ct : ContPD) {
            mapCont.put(ct.AccountId, ct);
          }
        }   
        return mapCont;
    }
    
    private integer tatsAnzahlSeiten(integer tr) {
        integer ttp = 0;
        integer rtp = 0;
        integer tp = 0;
        if (tr <= 26) {
            tp = 2;
        }
        else {
            ttp = tr / 26;
            rtp = tr - (ttp * 26);
            if (rtp > 0) {
              tp = ttp + 2;
            }
            else {
              tp = ttp + 1;
            }
        }       
        return tp;
    }
    
    public Map<integer, string> monatsNamenFuellen() {
        Map<integer, string> monatsName = new Map<integer, string> () ;
        monatsName.put(1, 'Januar');
        monatsName.put(2, 'Februar');
        monatsName.put(3, 'März');
        monatsName.put(4, 'April');
        monatsName.put(5, 'Mai');
        monatsName.put(6, 'Juni');
        monatsName.put(7, 'Juli');
        monatsName.put(8, 'August');
        monatsName.put(9, 'September');
        monatsName.put(10, 'Oktober');
        monatsName.put(11, 'November');
        monatsName.put(12, 'Dezember');
        return monatsName;
    }
    
    // wird nicht aufgerufen! Nur für Testabdeckung!!!  
        public class dummyZeile {
                
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

// wird nicht aufgerufen! Nur für Testabdeckung!!!       
        public void setLeereZeilen() {
            List<dummyZeile> pZeilen = new List<dummyZeile>();
            dummyZeile dZeile = new dummyZeile();
            
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
               
   
        }
}