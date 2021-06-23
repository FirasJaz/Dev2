/*/****************************************************************************************************************************
// Erstellt 06.12.2015 von MZ
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
// Setzt Feld 'pausiert__c' auf true, wenn 'pausiert_ab__c' <= heute
//
//
//****************************************************************************************************************************
//Änderungen:   
                                                       
//****************************************************************************************************************************
*/


global class PP_account_pausieren_batch implements Database.Batchable<sObject>{
    public boolean keinAccounts {get; set;}
    public boolean keinPPs {get; set;}
    public List<Account> Acclist;
    public Status_Emails__c statusEmail = Status_Emails__c.getValues('Partner/-Produkte pausieren Starte');
    global String query = 'Select Id from Account LIMIT 1';
 
    global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        date heute = date.today();
                
        Acclist = [select id, pausiert__c, pausiert_ab__c, pausiert_bis__c, Name from Account where pausiert_ab__c != null and pausiert_ab__c <= :heute and pausiert__c = false];
        List<Partner_Produkte__c> Plist = [select id, Name, pausiert_ab__c, pausiert_bis__c, pausiert__c, Partner__r.Name, Produktgruppe__c from Partner_Produkte__c where Produktgruppe__c != null and pausiert_ab__c != null and pausiert_ab__c <= :heute and pausiert__c = false];
        
        if(Plist != null && Plist.size() != 0) {
            keinPPs = false;
                    
            for(Partner_Produkte__c PP: Plist) {
                PP.pausiert__c = true;
            }            
        }
        else{
            keinPPs = true;
        }
        
        if(Acclist != null && Acclist.size() != 0) { 
            keinAccounts = false;
            
            for(Account acc : Acclist) {
                acc.pausiert__c = true;
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
            System.debug('#########################Mansi 2016 : Update fehlgeschlagen!');
        }
        
        if(!keinPPs || !keinAccounts){
                String toAddr = 'ziaei@klosesrockepartner.de';
                String[] toAddress;
                Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                
                try{
                    toAddress = new String[] {statusEmail.Empf_nger_Email_Adresse__c , statusEmail.Empf_nger_Email_Adresse_CC__c};
                }
                catch(System.exception e){
                    toAddress = new String[]{toAddr};
                }
                
                mail.setToAddresses(toAddress);
                mail.setSubject('Partner/-Produkte pausieren Starte ');  
                String body = 'Job Partner/-Produkte pausieren Starte gelaufen. \n';      
                
                if(Acclist != null && Acclist.size() != 0) {
                
                    body = body + '\nFolgende Partner sind pausiert : \n \n';                                                                        
                
                    if(Acclist != null && Acclist.size() != 0) {                    
                        for(Account acc: acclist) {
                            body = body + '- ' + acc.Name + '\n'; 
                        }
                    }
                }                                
                                
                if(Plist != null && Plist.size() != 0) {    
                        body = body + '\nFolgende Produkte sind pausiert : \n \n';
                                                   
                        for(Partner_Produkte__c PP: Plist) {
                            body = body + '- ' + PP.Name + '\n'; 
                        }
                }
                
                
                mail.setPlainTextBody(body);
                
                try {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });    
                }
                catch (System.Exception e)
                {
                    system.debug('#########################Email error ' + e);
                } 
        }
    }
    
    global void finish(Database.BatchableContext BC){}
}