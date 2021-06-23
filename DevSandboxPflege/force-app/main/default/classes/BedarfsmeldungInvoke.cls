public with sharing class BedarfsmeldungInvoke {
    public BedarfsmeldungHelper bdDaten {get; set;}
    public Map<integer, string> monatsNamen = new Map<integer, string> () ; 
    public boolean pb7 = false;
    public date Heute = date.today();
    public integer anzahlPD = 0;
    public integer currentMon = Heute.Month();  
    public integer currentJahr = Heute.Year(); 
    public integer bedarfMon = Heute.addMonths(1).Month();  
    public integer bedarfJah = Heute.addMonths(1).Year();   
    public string bedarfMonat = null;
    public string currentMonat = null;
    public string bedarfJahr = null;
    public integer gesendet {get; set;}
    public integer nochZuSenden {get; set;}
    public string currentJahrStr = null;
    // AM 08.10.2019
    private set<id> selectedPD = new set<id>();

    public List<BedarfsmeldungHelper.complettDok> allList {get; set;}
    
    public CompanyInfo__c FirmenInfo {get; set;}

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
    
    public List<Zeile> Zeilen = new List<Zeile>();

    public BedarfsmeldungInvoke() {
        FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
            if(FirmenInfo.GF__c.contains(', ')) {
                String[] GF = FirmenInfo.GF__c.split(', ',2);
                FirmenInfo.GF__c = GF[0] + '<br />'+GF[1];
            }
        }    
       integer minActiveKunde = 3;
        try {
            bedarfsmeldungMinimumKunden__c bmc = bedarfsmeldungMinimumKunden__c.getValues('minKunden');
            minActiveKunde = integer.valueOf(bmc.minKunden__c);
            if(minActiveKunde < 1) minActiveKunde = 1;
        }
        catch(System.Exception e) {

        }
        list<AggregateResult> pdkdList = [SELECT Pflegedienst__r.name pdname, Pflegedienst__c pdid, COUNT(id) kunden
                                        FROM contact 
                                        WHERE Pflegedienst__c IN (SELECT id FROM account WHERE Bedarfsmeldung__c = true) 
                                        AND id IN (SELECT contact__c FROM contact_status__c WHERE (status__c = 'Kunde' OR Status__c = 'Kandidat') AND Productgroup__c = 'PG54')
                                        GROUP BY  Pflegedienst__r.name, Pflegedienst__c
                                        HAVING COUNT(id) >= :minActiveKunde
                                        ORDER BY Pflegedienst__r.name];
        if((pdkdList != null) && (pdkdList.size() > 0)) {
            for(AggregateResult ar : pdkdList) {
                selectedPD.add(id.valueOf(string.valueOf(ar.get('pdid'))));
            }
        }
        System.debug('######################alex ' + selectedPD.size());
        bdDaten = new BedarfsmeldungHelper();
        monatsNamen = bdDaten.monatsNamenFuellen();
        currentMonat = readBedarfMonat(currentMon); 
        bedarfMonat = readBedarfMonat(bedarfMon);
        bdDaten.setPdAllSet(selectedPD);
        bdDaten.makeComplettList(); 
        allList = bdDaten.getallList();
        System.debug('##### alex1290 ' + allList.size());
    }

    public BedarfsmeldungInvoke(ApexPages.StandardController stdController) {

        integer minActiveKunde = 3;
        try {
            bedarfsmeldungMinimumKunden__c bmc = bedarfsmeldungMinimumKunden__c.getValues('minKunden');
            minActiveKunde = integer.valueOf(bmc.minKunden__c);
            if(minActiveKunde < 1) minActiveKunde = 1;
        }
        catch(System.Exception e) {

        }
        list<AggregateResult> pdkdList = [SELECT Pflegedienst__r.name pdname, Pflegedienst__c pdid, COUNT(id) kunden
                                        FROM contact 
                                        WHERE Pflegedienst__c IN (SELECT id FROM account WHERE Bedarfsmeldung__c = true) 
                                        AND id IN (SELECT contact__c FROM contact_status__c WHERE status__c = 'Kunde' OR Status__c = 'Kandidat')
                                        GROUP BY  Pflegedienst__r.name, Pflegedienst__c
                                        HAVING COUNT(id) >= :minActiveKunde
                                        ORDER BY Pflegedienst__r.name];
        if((pdkdList != null) && (pdkdList.size() > 0)) {
            integer counter = 0;
            for(AggregateResult ar : pdkdList) {
                Zeile bZeile = new Zeile();
                bZeile.pdName = string.valueOf(ar.get('pdname'));                           
                bZeile.anzahl = string.valueOf(ar.get('kunden'));
                bZeile.pdid = string.valueOf(ar.get('pdid'));
                selectedPD.add(id.valueOf(bZeile.pdid));
                counter++;
                bZeile.lfnr = string.valueOf(counter);
                bZeile.send = false;
                Zeilen.add(bZeile);                          
            }
            anzahlPD = Zeilen.size();
        }
    }

    public PageReference createNow() {    
        
        PageReference bmPDF = new PageReference('/apex/apex/BedarfsmeldungPrint');        
        return bmPDF;
    }

    public PageReference perEmail(){ 
         String Addr = '';           
         string plaintext = 'S. Anhang.\n ';
         Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();         
         asMAil__c asMail = asMail__c.getValues('Bedarfsmeldung');
         mail.setSubject(asMail.subject__c);   
         String[] toAddress =  asMail.toAddr__c.split(',');                   
         String[] toCcAddress =  asMail.toCC__c.split(',');   
         mail.setToAddresses(toAddress);
         mail.setBccAddresses(toCcAddress);            
         transient Messaging.EmailFileAttachment [] pdfList = new List<Messaging.EmailFileAttachment>(); 
         
        Integer i= 0;
        Integer s= 0;
        system.debug('#########################alex2000 Zeilen[0].pdid=' + Zeilen[0].pdid);
         
        //  do {
        for(Zeile z : Zeilen) { 
            if(!z.send)  {   
                if(s == 50) {
                    break;
                    s = 0;
                }  
                Blob pdf;
                //  PageReference fmPDF = new PageReference('/apex/apex/BedarfsmeldungPdf?von=' + i);
                PageReference fmPDF = new PageReference('/apex/apex/BedarfsmeldungPdf?von=0' + '&pdid=' + z.pdid);
                try {
                    pdf = fmPDF.getContent();
                    Messaging.EmailFileAttachment pdfAttc = new Messaging.EmailFileAttachment();
                    pdfAttc.setContentType('application/pdf');
                    pdfAttc.setInline(false);
                    pdfAttc.setFileName('Bedarfsmeldung_' + z.lfnr + '.pdf');
                    pdfAttc.setBody(pdf);
                    pdfList.add(pdfAttc);
                    i++; 
                    s++;
                    z.send = true;
                }
                catch (VisualforceException e) {
                    system.debug('#########################alex200 Error getContent e=' + e);
                } 
            }
        }  
        //   }
        //  while (i < anzahlPD);
         mail.setFileAttachments(pdfList);
         mail.setPlainTextBody(plaintext);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         for(String str: toAddress)
         {
             str = str + ' ';
             Addr = Addr + str;
         }
         ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Mail mit PDF-Anhang gesendet an ' + Addr)); 
         return null;                  
    }

    public PageReference abbrechen () {
        PageReference returnPage = new PageReference('/');
        returnPage.setRedirect(true);
        return returnPage;
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
    
    public boolean getPb7() {
        return pb7;
    }
    
    public integer getAnzahlPD () {
        return anzahlPD;
    }

    public List<BedarfsmeldungHelper.complettDok> getallList() {
        return allList;
    }
}