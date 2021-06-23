/****************************************************************************************************************************
// Erstellt 18.07.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//              helper for Bedarfsmeldung
//
//****************************************************************************************************************************
// Test:  test_Bedarfsmeldun
//*****************************************************************************************************************************
// Änderungen: 
//  30.10.2019  AM #168986198.  Spalte "Nächster Liefertermin" hat Format dd-mm-yyyy
//                              Die leere Spalte als "Abweichende Lieferung" bezeichnet. 
//                              fix Fehler beim Auswahl contacts für den Ausdruck (fehle die Abfrage contact_status) 
//  01.11.2019  AM #168986198. Nur eine früherste Lieferung beim gleichen Produkten 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class BedarfsmeldungHelper {
    private integer vonSatz = 0;
    private integer maxSatz = 1000;
    private List<Account> pdListAll {get; set;}
    private List<Account> pdList {get; set;}
    private Map<ID, Contact> mapCont = new Map<ID, Contact>();
    private Map<ID, integer> mapDocs = new Map<ID, integer>();
    private map<string, Delivery_Line__c> kdaulpMap = new map<string, Delivery_Line__c>();
    private map<string, Delivery_Line__c> kdauBedMap = new map<string, Delivery_Line__c>();
    private set<ID> pdoutSet = new set<ID>();
    private map<ID, map<string, Order__c>> pdCtOdMap = new map<ID, map<string, Order__c>>();

    // AM 08.10.2019
    private set<ID> pdAllSet = new set<ID>();
    public class bedarf {
        public string liDate {get;set;}
        public string CB  {get;set;}
    }
    public List<bedarf> bdList;

    public class kundenTabelle {
        public string lfnr {get;set;}
        public string ln {get;set;}
        public string fn {get;set;}
        public string kdnr {get;set;}
        public string cb {get;set;}
        public string ab {get;set;}
        public string lt {get;set;}
        public string trStyle {get; set;}
        public string cssClass {get; set;}
        public string cssClass1 {get; set;}    
        public boolean seitenwechsel {get; set;}   
        public string currentPage {get;set;} 
    }

    public List<kundenTabelle> kdList = new List<kundenTabelle>();

    public class complettDok {
        public account pd {get;set;}
        public List<kundenTabelle> kdList;
        public integer anzahlKunden {get;set;}
        public integer anzahlSeiten {get;set;}
        // public account getPd() {
        //     return pd; 
        // }

        public List<kundenTabelle> getkdList() {
            return kdList; 
        }
    }

    public List<complettDok> allList = new List<complettDok>();



    // deprecated
    public class Zeile {
        public string pdName {get;set;}
        public string anzahl {get;set;}
        public string pbName {get;set;}
        public string lsName {get;set;}
        public string pbVor  {get;set;}
        public string liDate  {get;set;}
        public id pdid  {get;set;}
        public boolean send {get;set;}
        public string lfnr  {get;set;}
    }
    // deprecated
    public List<Zeile> Zeilen = new List<Zeile>();

    // Constructor
    public BedarfsmeldungHelper() {      
    }

    // deprecated
    public BedarfsmeldungHelper(integer von) {
        if(von < 1000) { 
            setMaxSatz(20);
            setVonSatz(von);
        }
        system.debug('#######################alex000 von='+von) ;
        set<id> pdIdSet = new set<id>();
        list<AggregateResult> pdkdList = readCareServiceWithContacts();
        if((pdkdList != null) && (pdkdList.size() > 0)) {
            for(AggregateResult ar : pdkdList) {
                pdIdSet.add(string.valueOf(ar.get('pdid')));    
            }
        }
        system.debug('#######################alex002 pdIdSet.size()='+pdIdSet.size()) ;
        // pdListAll = lesenAllePD(pdIdSet);
        // pdCtOdMap = createPdCtOdMap(pdListAll);
        // pdList = pdListAll;
        system.debug('#######################alex002a pdIdSet='+pdIdSet) ;
        pdList = lesenAllePD(pdIdSet);
        system.debug('#######################alex003 pdList.size()='+pdList.size()) ;
        pdCtOdMap = createPdCtOdMap(pdList);
        // pdList = pdListAll;
    }

    // deprecated
    // AM 23.09.2019
    public BedarfsmeldungHelper(id pdid) {
       
            setMaxSatz(20);
            setVonSatz(0);
        
        pdList = [SELECT id, Name, BillingCity, BillingPostalCode,  BillingStreet, Fax
                                        FROM Account
                                        WHERE id = : pdId];   
        pdCtOdMap = createPdCtOdMap(pdList);
    }


    // deprecated
    @TestVisible private list<AggregateResult> readCareServiceWithContacts() {
        integer minActiveKunde = 3;
        Set<id> pdSet = new Set<id>();
        Set<id> ksSet = new Set<id>();
        try {
            bedarfsmeldungMinimumKunden__c bmc = bedarfsmeldungMinimumKunden__c.getValues('minKunden');
            minActiveKunde = integer.valueOf(bmc.minKunden__c);
            if(minActiveKunde < 1) minActiveKunde = 1;
        }
        catch(System.Exception e) {}
        List<account> pdList =[SELECT id
                                FROM Account
                                WHERE Kategorie__c = '01 Ambulante Pflegedienste'
                                AND Anzahl_der_Patienten__c = 'monatliche Anforderungsliste'];
        if((pdList != null) && (pdList.size() > 0)) {
            for(Account a :pdList) {
                pdSet.add(a.id);
            }
            List<Contact_Status__c> ksList = [SELECT Contact__c 
                                                FROM Contact_Status__c 
                                                WHERE Status__c IN ('Kunde', 'Kandidat')
                                                AND Contact__r.Pflegedienst__c IN : pdSet];
                if((ksList != null) && (ksList.size() > 0)) {
                    for(Contact_Status__c ks : ksList) {
                        ksSet.add(ks.Contact__c);
                    }
                }                                                

            list<AggregateResult> pdkdList = [SELECT Pflegedienst__r.name pdname, Pflegedienst__c pdid, COUNT(id) kunden
                        FROM Contact
                        WHERE Pflegedienst__c IN : pdSet
                        AND id IN :ksSet                  
                        GROUP BY Pflegedienst__r.name, Pflegedienst__c
                        HAVING COUNT(id) >= : minActiveKunde
                        ORDER BY Pflegedienst__r.name
                        LIMIT 2000];
                        
                        
            return pdkdList;
        }
        return null;
    }

    public void makeComplettList() {
        set<id> allContactSet = new Set<id>();
        set<id> contactsInList = new Set<id>(); 
        map<id, List<contact>> pdContactMap = new map<id, List<contact>>();
        map<id, List<string>> aufAbrufMap = new map<id, List<string>>();
        map<id, List<bedarf>> nextMap = new map<id, List<bedarf>>();

        List<contact> pdContactList = [SELECT Pflegedienst__c, id, firstname, lastname, Kundennummer__c, account.Familien_ID__c 
                                        FROM contact 
                                        WHERE Pflegedienst__c IN : pdAllSet
                                        AND id IN (SELECT contact__c FROM contact_status__c WHERE status__c = 'Kunde' OR Status__c = 'Kandidat')
                                        ORDER BY Pflegedienst__c, lastname];
        for(contact c : pdContactList) {
            List<contact> ctList;
            if(pdContactMap.containsKey(c.Pflegedienst__c)) {
                ctList = pdContactMap.get(c.Pflegedienst__c);
                ctList.add(c);
                pdContactMap.put(c.Pflegedienst__c, ctList);
            }
            else {
                ctList = new List<contact>();
                ctList.add(c);
                pdContactMap.put(c.Pflegedienst__c, ctList);        
            }
            allContactSet.add(c.id);
        }

        // Füllen Order pausiert
        List<Order__c> odList = [SELECT id, Contact__c, Description__c 
                                FROM Order__c 
                                WHERE Contact__c IN : allContactSet
                                    AND Status__c = 'pausiert'];
        if((odList != null) && (odList.size() > 0)) {
            List<string> cbList;
            for(Order__c od : odList) {
                if(aufAbrufMap.containsKey(od.Contact__c)) {
                    cbList = aufAbrufMap.get(od.Contact__c);
                    cbList.add(od.Description__c);
                    aufAbrufMap.put(od.Contact__c, cbList);     
                }
                else {
                    cbList = new List<string>();
                    cbList.add(od.Description__c);
                    aufAbrufMap.put(od.Contact__c, cbList);
                    system.debug('##### ' + od.Contact__c + ' ' + cbList);
                }
                contactsInList.add(od.Contact__c);
            }
        }

        // Füllen Bedarf
        set<string> produktProKunde = new set<string>(); 
        List<AggregateResult> dlList = [SELECT Delivery_date__c dd, Order_line__r.Order__r.Description__c  cb, Contact__c ct
                                        FROM Delivery_Line__c 
                                        WHERE Contact__c IN :allContactSet
                                                AND Delivery_status__c = 'Bedarf' 
                                                GROUP BY Delivery_date__c, Order_line__r.Order__r.Description__c, Contact__c];
        
        for(AggregateResult ar : dlList) {
            // nur 1 CBxx oder KUWV pro Kunde 
            string produktKey;
            if(string.valueOf(ar.get('cb')).contains('KUWV')) {
                produktKey = string.valueOf(ar.get('ct')) + 'KUWV';
            }
            else {
                produktKey = string.valueOf(ar.get('ct')) + 'CB';
            }
            
            if(!produktProKunde.contains(produktKey)) {
                produktProKunde.add(produktKey);
                bedarf b = new bedarf();
                if(nextMap.containsKey(id.valueOf(string.valueOf(ar.get('ct'))))) {
                    bdList = nextMap.get(id.valueOf(string.valueOf(ar.get('ct'))));
                    // b.liDate = string.valueOf((date)ar.get('dd'));
                    b.liDate = datetime.newInstance(((date)ar.get('dd')), Time.newInstance(0, 0, 0, 0)).Format('dd-MM-yyyy');
                    b.CB = string.valueOf(ar.get('cb'));
                    bdList.add(b);
                    nextMap.put(id.valueOf(string.valueOf(ar.get('ct'))), bdList);      
                }
                else {
                    bdList = new List<bedarf>();
                    b.liDate = datetime.newInstance(((date)ar.get('dd')), Time.newInstance(0, 0, 0, 0)).Format('dd-MM-yyyy');
                    b.CB = string.valueOf(ar.get('cb'));
                    bdList.add(b);
                    nextMap.put(id.valueOf(string.valueOf(ar.get('ct'))), bdList);
                }
                contactsInList.add(id.valueOf(string.valueOf(ar.get('ct'))));
            }
        }


        List<Account> pdList = [SELECT id, Name, BillingCity, BillingPostalCode,  BillingStreet, Fax
                                FROM Account
                                WHERE id IN : pdAllSet
                                ORDER BY Name
                                LIMIT 1000];  
        for(account a : pdList) {
            complettDok cd = new complettDok();
            cd.pd = a;
            List<contact> pdKunden = pdContactMap.get(a.id);
            cd.anzahlKunden = pdKunden.size();
            cd.anzahlSeiten = numberOfPages(cd.anzahlKunden);
            kdList = new List<kundenTabelle>();
            integer count = 0;
            integer currentRow = 0;
            integer currentPage = 2;
            kundenTabelle kth = makeTableHeader();
            kdList.add(kth);
            for(contact ct : pdKunden) {
                // alle bedarfe
                if(nextMap.containsKey(ct.id)) {
                    bdList = nextMap.get(ct.id);
                    for(bedarf b : bdList) {
                        kundenTabelle kt = new kundenTabelle();
                        count++;
                        kt.currentPage = string.valueOf(currentPage);
                        kt.lfnr = string.valueOf(count);
                        kt.ln = ct.lastname;
                        kt.fn = ct.firstname;
                        kt.kdnr = string.valueOf(ct.account.Familien_ID__c);
                        kt.cb = b.CB;
                        kt.lt = b.liDate;
                        kt.cssClass1 = 'bs_th';
                        kt.cssClass = 'bs_td';
                        kdList.add(kt); 
                        currentRow++;
                        if(currentRow >= 22) {
                            currentRow = 1;
                            
                            kt = makeTableHeader();
                            kt.seitenWechsel = true;
                            kt.currentPage = string.valueOf(currentPage);
                            kdList.add(kt);
                            currentPage++;
                        }
                        

                    }
                }
                // order pausiert
                if(aufAbrufMap.containsKey(ct.id)) {
                    List<string> cbList = aufAbrufMap.get(ct.id);
                    for(string cb :cbList) {
                        kundenTabelle kt = new kundenTabelle();
                        count++;
                        kt.currentPage = string.valueOf(currentPage);
                        kt.lfnr = string.valueOf(count);
                        kt.ln = ct.lastname;
                        kt.fn = ct.firstname;
                        kt.kdnr = string.valueOf(ct.account.Familien_ID__c);
                        kt.cb = cb;
                        kt.lt = 'Auf Abruf';
                        kt.cssClass1 = 'bs_th';
                        kt.cssClass = 'bs_td';
                        kdList.add(kt); 
                        currentRow++;
                        if(currentRow >= 22) {
                            
                            currentRow = 1;
                            kt = makeTableHeader();
                            kt.seitenWechsel = true;
                            kt.currentPage = string.valueOf(currentPage);
                            kdList.add(kt); 
                            currentPage++;  
                        }
                                
                    }
                }
                // Kunden ohne "Auftrag pausiert" und ohne "Bedarf" - Status "nicht aktiv". 
                if((!nextMap.containsKey(ct.id)) && (!aufAbrufMap.containsKey(ct.id))) {
                    kundenTabelle kt = new kundenTabelle();
                    count++;
                    kt.currentPage = string.valueOf(currentPage);
                    kt.lfnr = string.valueOf(count);
                    kt.ln = ct.lastname;
                    kt.fn = ct.firstname;
                    kt.kdnr = string.valueOf(ct.account.Familien_ID__c);
                    kt.cb = '';
                    kt.lt = 'Auf Abruf';
                    kt.cssClass1 = 'bs_th';
                    kt.cssClass = 'bs_td';
                    kdList.add(kt); 
                    currentRow++;
                    if(currentRow >= 22) {                       
                        currentRow = 1;
                        kt = makeTableHeader();
                        kt.seitenWechsel = true;
                        kt.currentPage = string.valueOf(currentPage);
                        kdList.add(kt); 
                        currentPage++;  
                    }                    
                }


            }
            cd.kdList = kdList;
            allList.add(cd);
        }

    }

    public kundenTabelle makeTableHeader() {
        kundenTabelle kt = new kundenTabelle();

        kt.lfnr = 'Nr.';
        kt.ln = 'Name';
        kt.fn = 'Vorname';
        kt.kdnr = 'Kd-Nr.';
        kt.cb = 'aktuelle curabox';
        kt.ab = 'Abweichende Lieferung';
        kt.lt = 'Nächster Liefertermin';      
        kt.cssClass1 = 'bs_th';
        kt.cssClass = 'bs_th';
        return kt;     
    } 

    // deprecated
    public map<id, map<string, Order__c>> createPdCtOdMap(List<Account> pdList) {
        map<ID, map<string, Order__c>> pdCtOdMap = new map<ID, map<string, Order__c>>();
        map<ID, Account> pdMap = new Map<ID, Account>();
        for(Account pdN : pdList) { 
            pdMap.put(pdN.id, pdN);
        }
        set<ID> pdSet = pdMap.keySet();
        mapCont = createMapCont(pdSet); 

                // Alle laufende Aufträge für PD mit dem Key kdID-auID   
            system.debug('#######################alex411 pdSet.size()='+pdSet.size() + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
            map<string, Order__c> kdauMap = readContactOrders(pdSet);
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
                kdaulpMap = readDL(kdSet, auSet); 
                system.debug('#######################alex002 kdaulpMap.size()='+kdaulpMap.size()) ;
                kdauBedMap = readBedarf(kdSet, auSet); 
                // Kombinierte map PD - tabelle KdAuMap<Au>             
                id tempPD = null;
                map<string, Order__c> tempKdAuMap = new map<string, Order__c>();
                system.debug('#######################alex004 kdauSet.size()='+kdauSet.size()) ;
                integer curRow = 0;
                for(id pdID : pdSet) {
                    tempKdAuMap = lesenAuKd(pdID, kdauMap);
                    if((tempKdAuMap != null) && (!tempKdAuMap.isEmpty())) {
                    
                          
                        //if((curRow >= vonSatz) && (curRow < (vonSatz + maxSatz))) {
                            pdCtOdMap.put(pdID, tempKdAuMap);
                            mapDocs.put(pdID, tatsAnzahlSeiten(tempKdAuMap.size()));
                            pdoutSet.add(pdID);
                        //}
                        curRow++;
                    }
                }
                system.debug('#######################alex005 pdCtOdMap.size()='+pdCtOdMap.size() + ' vonSatz=' + vonSatz + ' maxSatz='+maxSatz) ; 
        
            }
            system.debug('#######################alex005a ') ;         
        return pdCtOdMap;
    }

    // deprecated
    public map<string, Order__c> lesenAuKd(id pdID, map<string, Order__c> kdauMap) {
        map<string, Order__c> tempKdAuMap = new map<string, Order__c>();
        set<string> keys = KdAuMap.keySet();
        List<string> keySub = new List<string>();
        for(string key : keys) {
            Order__c au = KdAuMap.get(key);
            if((au != null) && (au.Contact__r.Pflegedienst__c == pdID)) {
                    keySub.add(au.Contact__r.lastname + ':' + key);
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

    // deprecated
    public map<string, Order__c> readContactOrders(set<id> pdSet) {
        List<Contact_Status__c> KuendigungList = [select Contact__c, Productgroup__c from Contact_Status__c where Status__c = 'Kündigung'  AND Contact__r.Pflegedienst__c IN :pdSet];
        Set<Id> CB_Kuendigung_Set = new Set<Id>();
        Set<Id> KUVW_Kuendigung_Set = new Set<Id>();
        for(Contact_Status__c ks : KuendigungList){
            if(ks.Productgroup__c == 'PG54'){
                CB_Kuendigung_Set.add(ks.Contact__c);
            }
            if(ks.Productgroup__c == 'PG51'){
                KUVW_Kuendigung_Set.add(ks.Contact__c);
            }
        }
        
        
        map<string, Order__c> ctOdMap = new map<string, Order__c>();
        system.debug('#######################alex412cbr pdSet.size()='+pdSet.size() + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
        
        list<Order__c> auList = [SELECT id, Description__c, Contact__c,
                                            Contact__r.Pflegedienst__c, Contact__r.Name, 
                                            Contact__r.firstname, Contact__r.lastname, 
                                            Contact__r.Kundennummer__c, Contact__r.account.Familien_ID__c, Contact__r.Versicherungsnummer__c, 
                                            Contact__r.MailingCity, Contact__r.MailingPostalCode, Contact__r.MailingStreet
                                FROM Order__c WHERE Contact__r.Pflegedienst__c IN :pdSet
                                 AND Genehmigungsstatus__c NOT IN ('abgelehnt', 'abgelaufen', 'abbestellt')

                       AND (  (Description__c LIKE 'CB%' AND Contact__c NOT IN :CB_Kuendigung_Set)
                           OR (Description__c = 'KUWV' AND Contact__c NOT IN :KUVW_Kuendigung_Set)
                           )  
                                   
                                ORDER BY Createddate DESC];
        if (auList != null && auList.size() != 0) {
            system.debug('#######################alex413 auList.size()='+auList.size() + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
            set<string> tempAuSet = new set<string>();
            for(Order__c au : auList) {
                string key = string.valueOf(au.Contact__c) + '-' + string.valueOf(au.id); 
                string tkey = string.valueOf(au.Contact__c) + '-' + au.Description__c; 
                if(!tempAuSet.contains(tkey)) {
                    tempAuSet.add(tkey);
                    if(!ctOdMap.containsKey(key)) {
                        ctOdMap.put(key, au);
                        system.debug('#######################alex414 key='+key + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
                    }
                    else {
                        system.debug('#######################alex415 key='+key + ' maxSatz=' + maxSatz + ' vonSatz=' + vonSatz) ;
                    }
                }
            }
        }       
        return ctOdMap;
    } 

    
    private map<ID, Contact> createMapCont(set<id> pdSet) {
        Map<ID, Contact> mapCont = new Map<ID, Contact>();
        list<Contact> ContPD = [SELECT Name, AccountId FROM Contact
              WHERE AccountId IN :pdSet
              ];
        if ((ContPD != null) && (ContPD.size() > 0)) {
          for(Contact ct : ContPD) {
            mapCont.put(ct.AccountId, ct);
          }
        }   
        return mapCont;
    }

    public map<string, Delivery_Line__c> readDL(set<id> kdSet, set<id> auSet) {
        map<string, Delivery_Line__c> kdaulpMap = new map<string, Delivery_Line__c>();
        date Heute = date.today(); 
        list<Delivery_Line__c> LPlist = [SELECT id, Name, Delivery_note__r.Name, Delivery_note__r.Delivery_date__c,
                                                        Order_line__r.Order__c,
                                                        Order_line__r.Order__r.Description__c, 
                                                        Contact__c
                                                FROM Delivery_Line__c 
                                                WHERE Delivery_Status__c = 'geliefert'
                                                AND Contact__c IN :kdSet
                                                AND Order_line__r.Order__c IN :auSet
                                                
                                                ORDER BY Contact__c, Delivery_note__r.Delivery_date__c DESC];
        if((LPlist != null) && (LPlist.size() > 0)) {
            system.debug('#########################alex001 lpList.size()=' + lpList.size());
            for(Delivery_Line__c LP : LPlist) {
                string key = string.valueOf(LP.Contact__c) + '-' + string.valueOf(LP.Order_line__r.Order__c);  
                if(!kdaulpMap.containsKey(key)) {
                    kdaulpMap.put(key, LP);
                }
                else {
                    Delivery_Line__c LPt = kdaulpMap.get(key);
                    if(LPt.Delivery_note__r.Delivery_date__c < LP.Delivery_note__r.Delivery_date__c) {
                        kdaulpMap.put(key, LP);
                    }
                }
            }
        }       
        
        return kdaulpMap;
    }

    public map<string, Delivery_Line__c> readBedarf(set<id> kdSet, set<id> auSet) {
        map<string, Delivery_Line__c> kdauBedMap = new map<string, Delivery_Line__c>();
        list<Delivery_Line__c> LPlist = [SELECT id, Delivery_date__c,
                                                        Order_line__r.Order__c,
                                                        Contact__c
                                                FROM Delivery_Line__c 
                                                WHERE Delivery_status__c = 'Bedarf'
                                                AND Contact__c IN :kdSet
                                                AND Order_line__r.Order__c IN :auSet                                                
                                                ORDER BY Contact__c, Delivery_date__c DESC];
        if((LPlist != null) && (LPlist.size() > 0)) {
            system.debug('#########################alex001 lpList.size()=' + lpList.size());
            for(Delivery_Line__c LP : LPlist) {
                string key = string.valueOf(LP.Contact__c) + '-' + string.valueOf(LP.Order_line__r.Order__c);  
                if(!kdauBedMap.containsKey(key)) {
                    kdauBedMap.put(key, LP);
                }
                else {
                    Delivery_Line__c LPt = kdauBedMap.get(key);
                    if(LPt.Delivery_date__c < LP.Delivery_date__c) {
                        kdauBedMap.put(key, LP);
                    }
                }
            }
        }       
        
        return kdauBedMap;
    }

    // deprecated
    public List<Account>  lesenAllePD() {        
        List<Account> pdList = [SELECT id, Name, BillingCity, BillingPostalCode,  BillingStreet, Fax
                                FROM Account
                                WHERE Kategorie__c = '01 Ambulante Pflegedienste'
                                AND Anzahl_der_Patienten__c = 'monatliche Anforderungsliste'
                                ORDER BY Name
                                LIMIT 1000];                                        
        return pdList;  
    }

    // deprecated
    public List<Account>  lesenAllePD(set<id> pdIdSet) {  
        system.debug('#######################alex1003 pdIdSet='+pdIdSet + ' maxSatz=' + maxSatz + ' vonSatz='+vonSatz) ;      
        List<Account> pdList = [SELECT id, Name, BillingCity, BillingPostalCode,  BillingStreet, Fax
                                FROM Account
                                WHERE id IN : pdIdSet
                                ORDER BY Name                               
                                LIMIT : maxSatz
                                OFFSET : vonSatz];                  
        return pdList;  
    } 

    // deprecated
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

    private integer numberOfPages(integer tr) {
        integer ttp = 0;
        integer rtp = 0;
        integer tp = 0;
        if (tr <= 22) {
            tp = 2;
        }
        else {
            ttp = tr / 22;
            rtp = tr - (ttp * 22);
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

    public List<Zeile> getZeilen() {
        return Zeilen;
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

    public map<ID, map<string, Order__c>> getpdCtOdMap() {
        return pdCtOdMap;
    }
    
    public map<string, Delivery_Line__c> getKdAuLpMap() {
        return kdaulpMap;
    }
    
    public map<string, Delivery_Line__c> getKdAuBedMap() {
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
    
    // AM08.10.2019
    public void setPdAllSet(set<id> pdAllSet) {
        this.pdAllSet = pdAllSet;
    }

    public List<complettDok> getallList() {
        return allList;
    }

}