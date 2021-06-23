public with sharing class BedarfsmeldungPdf {
    public string vonS = ApexPages.currentPage().getParameters().get('von');
    public List<Delivery_Line__c> LSpos {get; set;}
    public List<Delivery_Line__c> LSall {get; set;}
    public List<Delivery_Line__c> LSsort {get; set;}
  
    public List<Contact> ContPD {get; set;}
    public date Heute = date.today();
    public integer curMon = Heute.month();
    public integer curJahr = Heute.year();
    public integer currentMon = Heute.Month(); 
    public integer currentJahr = Heute.Year(); 
    public integer bedarfMon = Heute.addMonths(1).Month();  
    public integer bedarfJah = Heute.addMonths(1).Year();   
    public string bedarfMonat = null;
    public string currentMonat = null;
    public string bedarfJahr = null;
    
    public string currentJahrStr = null;
    public Map<integer, string> monatsNamen = new Map<integer, string> () ;
    public string pdName = null;
    public boolean seitenKopf = false;
    public boolean seitenBrief = false;
    public boolean seitenFuss = false;
    public integer totalDocs = 0;
    public boolean pb7 = false;
    public CompanyInfo__c FirmenInfo {get; set;}
    
    
    public Map<ID, integer> mapDocs = new Map<ID, integer>();
    public Map<ID, Contact> mapCont = new Map<ID, Contact>();
// neu  
    private map<ID, map<string, Order__c>> pdKdAuMap = new map<ID, map<string, Order__c>>();
    private map<string, Delivery_Line__c> kdaulpMap = new map<string, Delivery_Line__c>();
    private map<string, Delivery_Line__c> kdauBedMap = new map<string, Delivery_Line__c>();
    public List<Account> pdList {get; set;} 
 
     // CC
    // public ksgCCdecodingWrapper decrypt {get;set;}       
    // public List<String> encryptedValueList= new List<String>();
    // ende CC 
 
    public class Zeile {
        public String pos {get;set;}
        public String nachname {get;set;}
        public String vorname {get;set;}
        public String kd_nr {get;set;}
        public String bsMonat {get;set;}
        public String pbVormonat {get;set;}
        public string abwBs {get;set;}
        public string gr_hs {get;set;}
        public string anmerkung {get;set;}
        public string seitenw {get;set;}
        public string th {get; set;}
        public string cssClass {get; set;}
        public string cssClass1 {get; set;}
        public string Jahr {get; set;}        
        
        public string pbAdr {get;set;}
        public string pbStr {get;set;}
        public string pbPlzOrt {get;set;}
        public string pbFax {get;set;}
        public string pbCont {get;set;}
    
        public boolean kopf {get; set;}
        public boolean fuss {get; set;}
        public boolean brief {get; set;}
        public boolean pb7 {get; set;}
    
        public string curPage {get; set;}
        public string totPages {get; set;}
        public string pbName {get;set;}
    }
    public List<Zeile> Zeilen = new List<Zeile>();

    public BedarfsmeldungPdf() {

    }

    public BedarfsmeldungPdf(ApexPages.StandardController stdController) {
        integer vonI = 500;
        if(vonS != null) {
            try {
                vonI = integer.valueOf(vonS);
            }
            catch (System.exception e) {
                vonI = 500;
            }
            
        }
        system.debug('#######################alex000 vonI='+vonI ) ;
        BedarfsmeldungHelper bdDaten = new BedarfsmeldungHelper(vonI);
        monatsNamen = bdDaten.monatsNamenFuellen();
        FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
                        if(FirmenInfo.GF__c.contains(', ')){
                    String[] GF = FirmenInfo.GF__c.split(', ',2);
                    FirmenInfo.GF__c = GF[0] + '<br />'+GF[1];
                        }
        }
        currentMonat = readBedarfMonat(currentMon); 
        bedarfMonat = readBedarfMonat(bedarfMon);
        Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=Bedarfsmeldung_' + bedarfMonat + '.pdf' );
        BedarfJahr = string.valueOf(bedarfJah);
        integer p = 0;
        integer d = 0;
        ID tempID = null;
        // 23.01.2015       
        pdList = bdDaten.getPdList();
        system.debug('#######################alex200 pdList.size()='+pdList.size() ) ;
        if (pdList != null && pdList.size() != 0) {
                
            mapDocs = bdDaten.getMapDocs();
            system.debug('#######################alex201 mapDocs.size()='+mapDocs.size() ) ;
            pdkdauMap = bdDaten.getpdCtOdMap();
            system.debug('#######################alex202 pdkdauMap.size()='+pdkdauMap.size() ) ;
            kdaulpMap = bdDaten.getKdAuLpMap();
            system.debug('#######################alex203 kdaulpMap.size()='+kdaulpMap.size() ) ;
            kdauBedMap = bdDaten.getkdauBedMap();
            system.debug('#######################alex204 kdauBedMap.size()='+kdauBedMap.size() ) ;
            mapCont = bdDaten.getMapCont();
            system.debug('#######################alex205 mapCont.size()='+mapCont.size() ) ;

            // Jetzt Anzahl docs = pdList.size()
            totalDocs = pdList.size();   
            system.debug('#######################alex206 totalDocs='+totalDocs) ;
            
            seitenKopf = true;
            seitenBrief = true;  
            tempID = null;  
            string tempName = null;  
            boolean tempPB7 = false;
            // Positionen pro PD
            integer currentRow = 0;
            // Positionen pro Seite (26)
            integer currentLine = 0;
            // Seite pro PD
            integer currentPage = 1;
            // Gesamt Seiten pro PD
            integer totalPages = 0;
            // Laufende doc
            integer currentDoc = 0;     
            
            for(Account pd : pdList) {
                system.debug('#######################alex201 pd.Name='+pd.Name ) ;
                seitenKopf = true;
                seitenBrief = true;  
                currentPage = 1;
                currentRow = 0;
                currentLine = 0;
                currentDoc++;   
                tempPB7 = false;  
                    
                totalPages = mapDocs.get(pd.id);
                
                // Kopf drucken
                try {
                    pdKopf(seitenKopf, seitenBrief, totalPages, currentPage, pd);
                }
                catch (System.exception e) {
                    system.debug('#######################alex294 ErrorKopf='+e ) ;
                }
                currentPage++;
                tempName = pd.Name;

                // Die Tabelle mit den Kunden
                map<string, Order__c> tempKdAuMap = pdkdauMap.get(pd.id);
                map<id, Contact_Status__c> kdksMap = new map<id, Contact_Status__c>();
                
                if (tempKdAuMap == null) {
                        system.debug('#######################alex296 Error. pd.id='+pd.id ) ;
                }
                else {
                    system.debug('#######################alex202 pdkdauMap.size()='+pdkdauMap.size() ) ;
                    list<Order__c> tempKdAuList = tempKdAuMap.values();
                    set<id> kdSet = new set<id>();
                    for(Order__c au : tempKdAuList) {
                        kdSet.add(au.Contact__c);
                    }
                    list<Contact_Status__c> ksList = [SELECT id, Status__c, Contact__c 
                                              FROM Contact_Status__c 
                                              WHERE Contact__c IN : kdSet 
                                              ]; 
                    //  28.07.2017  AM 
                    if((ksList != null) && (ksList.size() > 0)) {
                        for(Contact_Status__c ks : ksList) kdksMap.put(ks.Contact__c, ks);
                    }   

                    for(Order__c au : tempKdAuList) {
                        
                        currentRow++;
                        currentLine++;
                        // Seitenwechsel innerhalb PD                 
                        if (currentLine == 24) {
                            system.debug('#######################alex210 currentLine='+currentLine + ' totalPages=' + totalPages + ' currentPage=' + currentPage ) ;
                            pdFuss(currentLine, tempName, currentDoc, totalPages, currentPage, tempPB7);
                            seitenFuss = false;
                            seitenKopf = true;                              
                            currentLine = 0;
                            currentPage++;
                            pdKopf(seitenKopf, seitenBrief, totalPages, currentPage, pd);
                        }                   
                        Zeile bZeile = new Zeile(); 
                        bZeile.pbName = pd.Name;
                        
                        try {                       
                        bZeile.totPages = string.valueOf(totalPages);
                        bZeile.curPage = string.valueOf(currentPage);
                        bZeile.pos = string.valueOf(currentRow);    
                                             
                        if(kdksMap.containsKey(au.Contact__c)) {
                            Contact_Status__c ks = kdksMap.get(au.Contact__c);
                            if(ks.Status__c != 'Kunde') {
                                // MZ 26.01.2018 #154394914 no * is needed #154394914
                                //bZeile.nachname = '*' + au.Contact__rlastname;
                                //bZeile.nachname = '*' + au.Contact__rlastname;
                                //tempPB7 = true;
                                
                                bZeile.nachname = au.Contact__r.lastname;
                                
                            }
                            else {
                                bZeile.nachname = au.Contact__r.lastname;
                            } 
                            bZeile.vorname = au.Contact__r.firstname;
                        }

                        
                        bZeile.kd_nr = string.valueOf(au.Contact__r.Kundennummer__c);

                        bZeile.bsMonat = bedarfMonat;
                        bZeile.pbVormonat = ' ';
                        string key = string.valueOf(au.Contact__c) + '-' + string.valueOf(au.id);     
                        if(kdaulpMap.containsKey(key)) {
                            bZeile.pbVormonat = kdaulpMap.get(key).Order_line__r.Order__r.Description__c.replace('CuraBox Variante', '');
                            bZeile.pbVormonat = bZeile.pbVormonat.replace('PflegeBox Variante', '');
                            //bZeile.lsName = kdaulpMap.get(key).Lieferschein__r.Name;
                            //bZeile.liDate = string.valueOf(kdaulpMap.get(key).Lieferschein__r.Delivery_date__c);
                            if(bZeile.pbVormonat.trim() == '7') {
                                //tempPB7 = true;                               
                                //bZeile.pbVormonat += ' *';
                            }
                        }
                      
                        bZeile.abwBs = ' ' ;
                        string abwBest = au.Description__c.replace('CuraBox Variante', ''); 
                        abwBest = abwBest.replace('PflegeBox Variante', ''); 
                        if(abwBest != bZeile.pbVormonat) {
                            bZeile.abwBs = abwBest ;    
                            if(abwBest.trim() == '7') {
                                //tempPB7 = true;
                                //bZeile.abwBs += ' *';
                            }       
                            
                        if(bZeile.abwBs != ' ') {
                           bZeile.pbVormonat =  bZeile.abwBs;
                           bZeile.abwBs = ' ';
                           }                
                        }
                    
                        

                        //bZeile.gr_hs = au.Contact__r.Gr_e_Einmalhandschuhe__c; 
                        bZeile.gr_hs = 'Auf Abruf';   
                        
                        if(kdauBedMap.containsKey(key)) {
                            try {
                                bZeile.gr_hs = kdauBedMap.get(key).Delivery_date__c.format();
                            }
                            catch (System.Exception e) { 
                                bZeile.gr_hs = key;
                            }
                        }   
                                        
                        bZeile.anmerkung = '';          
                        bZeile.cssClass = 'bs_td';
                        bZeile.cssClass1 = 'bs_th';
                        bZeile.seitenw = ''; 
                        bZeile.Jahr = string.valueOf(Date.today().year());                       
                        }
                        catch (System.exception e) {
                            system.debug('#######################alex293 Error='+e ) ;
                        }
                        system.debug('#######################alex204 bZeile.pbVormonat='+bZeile.pbVormonat ) ;
                        Zeilen.add(bZeile);                 
                    }
                }               
                try {
                    pdFuss(currentLine, tempName, currentDoc, totalPages, currentPage, tempPB7);
                }
                catch (System.exception e) {
                    system.debug('#######################alex294 ErrorFuss='+e ) ;
                }               
                tempID = pd.id;                 
                
            }
        }
        // Ende 23.01.2015      
        
     
    }

  public List<Zeile> getZeilen(){
        return Zeilen;
    }
    
    
    public string fillBedarfMonat(integer m) {
        return monatsNamen.get(m);
    }
    
    public string readBedarfMonat(integer m) {
        return monatsNamen.get(m);
    }
      
    public string getBedarfJahr() {
        return BedarfJahr;
    }
    
    public string getBedarfMonat() {
        return BedarfMonat;
    }
    
    public string getCurrentMonat() {
        return currentMonat;
    }
        
    public string getCurrentJahrStr() {
        return string.valueOf(currentJahr);
    }
    
    public string getPdName() {
        return pdName;
    }
    
    public boolean getSeitenKopf() {
        return seitenKopf;
    }

    public boolean getPb7() {
        return pb7;
    }
        
        public CompanyInfo__c getFirmenInfo(){
            return FirmenInfo;
    }

    public void pdFuss(integer cL, string pdName, integer cD, integer tP, integer cP, boolean pb7) {
        // Jede Seite hat 24 Zeilen (ohne Überschrift)
        integer x = 24 - cL - 2;
        for(integer i=0; i < x; i++) {
            seitenFuss = false;
            Zeile bZeile = new Zeile(); 
            bZeile.pos = '- ';
            bZeile.cssClass = 'bs_ll';
            bZeile.cssClass1 = 'bs_ll'; 
            bZeile.pbName = pdName;
            bZeile.totPages = string.valueOf(tP);
            bZeile.curPage = string.valueOf(cP);
            bZeile.fuss = seitenFuss;
            Zeilen.add(bZeile); 
        }
        seitenFuss = true;
        Zeile bZeile = new Zeile(); 
        bZeile.pb7 = pb7;
        bZeile.pos = '- ';
        bZeile.cssClass = 'bs_ll';
        bZeile.cssClass1 = 'bs_ll'; 
        bZeile.pbName = pdName;
        bZeile.totPages = string.valueOf(tP);
        bZeile.curPage = string.valueOf(cP);    

        bZeile.fuss = seitenFuss;       
        
        if (cD < totalDocs) {
            bZeile.seitenw = 'page-break-after:always;';
        }
        Zeilen.add(bZeile);
    }
    
    public void pdKopf(boolean kopf, boolean brief, integer tP, integer cP, account pd) {
        Zeile bZeile = new Zeile();
        bZeile.pos = 'Nr.';
        bZeile.nachname = 'Name';
        bZeile.vorname = 'Vorname';
        bZeile.kd_nr = 'Kd-Nr.';
        bZeile.bsMonat = 'Bestellung für (Monat)';
        bZeile.pbVormonat = 'aktuelle curabox';
        bZeile.abwBs = 'Abweichende Bestellung' ;
        bZeile.gr_hs = 'Nächster Liefertermin';    
        bZeile.anmerkung = 'Anmerkungen';
        bZeile.th = 'color: #fff; background-color : #02AADC;';
        bZeile.kopf = kopf;
        bZeile.brief = brief;
        bZeile.pbName = pd.Name;
        bZeile.cssClass1 = 'bs_th';
        bZeile.cssClass = 'bs_th';
        bZeile.pbAdr = pd.BillingStreet + ', ' + pd.BillingPostalCode + ' ' + pd.BillingCity;
        bZeile.pbStr = pd.BillingStreet;
        bZeile.pbPlzOrt = pd.BillingPostalCode + ' ' + pd.BillingCity;
        bZeile.pbFax = pd.Fax;
        if(mapCont.get(pd.id) != null) {
            bZeile.pbCont = mapCont.get(pd.id).Name;
        }
        else {
            bZeile.pbCont = 'Nicht vergeben';
        }
        bZeile.totPages = string.valueOf(tP);
        bZeile.curPage = string.valueOf(cP);
        Zeilen.add(bZeile); 
        pdName = pd.Name;   
        seitenKopf = false;
        seitenBrief = false;    
    }
}