/*/****************************************************************************************************************************
// Erstellt 19.11.2018 von AM
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
//  Version 2.0
//
//****************************************************************************************************************************
//Änderungen:       
//****************************************************************************************************************************
*/


public class Lieferungen implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    
    public list<string> errorList = new list<string>();
    public LS_XML_generieren_batch genXML {get; set;}

    
    public Database.querylocator start(Database.BatchableContext BC) {
        string query = 'SELECT id FROM Kunde__c WHERE id IN (SELECT Kunde__c FROM Lieferscheinposition__c WHERE Status__c = \'Bedarf\' AND Lieferdatum__c <= TODAY)';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Kunde__c> kdList = (List<Kunde__c>)scope;
        set<id> kdIdSet = new set<id>();
        for(Kunde__c kd : kdList) {
            kdIdSet.add(kd.id);
        }       
        genXML = new LS_XML_generieren_batch();
        genXML.createLS_bedarf(kdIdSet);
        if(genXML.getErrorListSize() > 0) {
            if(errorList.size() <= 800) errorList.addAll(genXML.getErrorList());
        }
    }

    public void finish(Database.BatchableContext BC){
        String[] toAddress, toCcAddress;
        
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();   

        try{
            toAddress = new String[] {Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse__c};
            toCcAddress = Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse_CC__c.split(', ');
        }
        catch(System.exception e){
            toAddress = new String[]{'kontakt@klosesrockepartner.de'};
            toCcAddress = new String[]{'kontakt@klosesrockepartner.de'};
        }

        try {        
            mail.setToAddresses(toAddress);
            mail.setCcAddresses(toCcAddress);
            mail.setSubject('Job Lieferungen Auslösen gelaufen');
            string PlainTextBody = 'Job Lieferungen Auslösen gelaufen';
            
            if(errorList.size() > 0) {
                for(string line : errorList) {
                    PlainTextBody += line + '\r\n';
                }
            }
            else {
                PlainTextBody += 'keine Fehler. \r\n';
            }

            mail.setPlainTextBody(PlainTextBody);
            mail.setHtmlBody(PlainTextBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });                   
        }
        catch (System.Exception e)
        {
            system.debug('#########################Email error ' + e);
        }         
    }        
            
    public void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new Lieferungen(), 200);
    }
        
}