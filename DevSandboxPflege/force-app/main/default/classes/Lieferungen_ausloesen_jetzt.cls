/*/****************************************************************************************************************************
// Erstellt 13.10.2015 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Löst die Lieferungen aus.
//
//
//****************************************************************************************************************************
//Änderungen:   
//        bt    29.04.2016    Anwendung von Custom setting  "curabox Lieferungen ausloesen"                                        
//****************************************************************************************************************************
*/


global class Lieferungen_ausloesen_jetzt implements Database.Batchable<sObject>{
    global String query = 'Select Id from Lieferscheinposition__c LIMIT 1';

    public LS_XML_generieren_batch genXML {get; set;}
    public LS_XML_nachbearbeiten_batch nbXML {get; set;}
    global String[] toAddress {get; set;} 
    global String[] toCcAddress {get; set;}
        
    global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        String toAddr = 'bricenjueya@yahoo.fr'; 
        String toCC = 'bricenjueya@yahoo.fr';
        system.debug('#########################alex000 ');
        genXML = new LS_XML_generieren_batch();

        system.debug('#########################alex100 ');
        genXML.createLS_jetzt_liefern();
        system.debug('#########################alex101 ');
        if(genXML.getErrorListSize() > 0) {
            system.debug('#########################alex102 ');
            list<string> fehler = genXML.getErrorList();
            if((fehler != null) && (fehler.size() > 0)) {
                string kdText = '';
                for(string zeile :fehler) {
                    kdText = kdText + zeile + '\r\n';
                }
                system.debug('#########################alex103 ');
                Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();                
                
                try{
                    toAddress = new String[] {Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse__c};
                    toCcAddress = Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse_CC__c.split(', ');
                }
                catch(System.exception e){
                    toAddress = new String[]{toAddr};
                    toCcAddress = new String[]{toCC};
                }
                
                mail.setToAddresses(toAddress);
                mail.setCcAddresses(toCcAddress);
                mail.setSubject('Fehler in Lieferungen Auslösen Status jetzt liefern');
                // mail.setHtmlBody(kdText);
                // mail.setFileAttachments(new Messaging.Emailfileattachment[] {Attach});
                mail.setPlainTextBody(kdText);
                try {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });         
                }
                catch (System.Exception e)
                {
                    system.debug('#########################Email error ' + e);
                }               
            }
        }
        nbXML = new LS_XML_nachbearbeiten_batch();
        // nbXML.LS_XML_nachbearbeiten_los();
    }

    global void finish(Database.BatchableContext BC){   
                String toAddr = 'bricenjueya@yahoo.fr'; 
                String toCC = 'bricenjueya@yahoo.fr';     
                system.debug('#########################alex201 ');
                Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();                
                
                try{
                    toAddress = new String[] {Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse__c};
                    toCcAddress = Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse_CC__c.split(', ');
                }
                catch(System.exception e){
                    toAddress = new String[]{toAddr};
                    toCcAddress = new String[]{toCC};
                }                
                
                mail.setToAddresses(toAddress);
                mail.setCcAddresses(toCcAddress);
                mail.setSubject('Job Lieferungen Auslösen gelaufen');
                // mail.setHtmlBody(kdText);
                // mail.setFileAttachments(new Messaging.Emailfileattachment[] {Attach});
                mail.setPlainTextBody('Job Lieferungen Auslösen jetzt liefern gelaufen');
                try {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });     
                    setLeereZeilen();                   
                }
                catch (System.Exception e)
                {
                    system.debug('#########################Email error ' + e);
                }         
    }            
    
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

       }            
        
}