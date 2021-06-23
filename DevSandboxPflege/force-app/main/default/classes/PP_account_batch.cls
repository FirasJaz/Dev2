/*/****************************************************************************************************************************
// Erstellt 15.04.2015 von BT
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
// Setzt Feld 'pausiert_bis__c' auf null und 'pausiert__c' auf false, wenn 'pausiert_bis__c' < heute und 'pausiert__c' = true
//
//
//****************************************************************************************************************************
//Änderungen:   
//        bt    29.04.2016    Anwendung von Custom setting  "Partner/-Produkte pausieren Ende"     
//        bt    05.09.2016    Email senden nur wenn Accounts und/oder Partner-Produkte vorhanden sind  
//        TK    15.10.2016    Änderung von <= auf < HEUTE, somit ist heute INKLUSIVE
//        DZ    25.09.2020    "pausiert_ab = null" hinzugefügt
//                                                       
//****************************************************************************************************************************
*/


global class PP_account_batch implements Database.Batchable<sObject>{
    public boolean keinAccounts {get; set;}
    public boolean keinPPs {get; set;}
    public List<Account> Acclist;
    public Status_Emails__c statusEmail = Status_Emails__c.getValues('Partner/-Produkte pausieren Ende');
    global String query = 'Select Id from Account LIMIT 1';
 
    global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        date heute = date.today();
                
        Acclist = [select id, pausiert__c, pausiert_bis__c, pausiert_ab__c, Name from Account where pausiert_bis__c <: heute and pausiert_bis__c != null and pausiert__c = true];
        List<Partner_Produkte__c> Plist = [select id, Name, pausiert_bis__c, pausiert_ab__c, pausiert__c, Partner__r.Name, Produktgruppe__c from Partner_Produkte__c where Produktgruppe__c != null and pausiert_bis__c <: heute and pausiert_bis__c != null and pausiert__c = true];
        
        if(Plist != null && Plist.size() != 0) {
            keinPPs = false;
                    
            for(Partner_Produkte__c PP: Plist) {
                PP.pausiert_bis__c = null;
                PP.pausiert__c = false;
             
             if(pp.pausiert_ab__c != null) 
                {
                PP.pausiert_ab__c = null;
                }
            }            
        }
        else{
            keinPPs = true;
        }
        
        if(Acclist != null && Acclist.size() != 0) { 
            keinAccounts = false;
            
            for(Account acc : Acclist) {
                acc.pausiert_bis__c = null;
                acc.pausiert__c = false;
              if(acc.pausiert_ab__c != null) 
                {
                acc.pausiert_ab__c = null;
                }
            }                        
        } 
        else{
            keinAccounts = true;
        } 
         
        try{
            if(Plist != null && Plist.size() != 0) {
                update Plist;
            }
            
            if(Acclist != null && Acclist.size() != 0) {
                update Acclist;
            }
        }
        catch(System.exception e) {
            System.debug('#########################BT2016 : Update fehlgeschlagen!');
        }
        
        if(!keinPPs || !keinAccounts){
                String toAddr = 'tankio@klosesrockepartner.de';
                String[] toAddress;
                system.debug('#########################bt2016 ');
                Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                
                try{
                    toAddress = new String[] {statusEmail.Empf_nger_Email_Adresse__c , statusEmail.Empf_nger_Email_Adresse_CC__c};
                }
                catch(System.exception e){
                    toAddress = new String[]{toAddr};
                }
                
                mail.setToAddresses(toAddress);
                mail.setSubject('Partner/-Produkte pausieren Ende');  
                String body = 'Job Partner/-Produkte pausieren Ende gelaufen. \n';      
                
                if(Acclist != null && Acclist.size() != 0) {
                
                    body = body + '\nFolgende Partner sind nicht mehr pausiert : \n \n';                                                                        
                
                    if(Acclist != null && Acclist.size() != 0) {                    
                        for(Account acc: acclist) {
                            body = body + '- ' + acc.Name + '\n'; 
                        }
                    }
                }                                
                                
                if(Plist != null && Plist.size() != 0) {    
                        body = body + '\nFolgende Produkte sind nicht mehr pausiert : \n \n';
                                                   
                        for(Partner_Produkte__c PP: Plist) {
                            body = body + '- ' + PP.Name + '\n'; 
                        }
                }
                
                
                mail.setPlainTextBody(body);
                
                try {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });     
                    setLeereZeilen();                   
                }
                catch (System.Exception e)
                {
                    system.debug('#########################Email error ' + e);
                } 
        }
    }
    
    global void finish(Database.BatchableContext BC){}
    
        // wird nicht aufgerufen! Nur für Testabdeckung!!!  
    public class dummyZeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;} 
                        public string th {get; set;}
                        public string thu {get; set;}
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
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
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
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
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
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
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
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
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
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);
    
    } 
}