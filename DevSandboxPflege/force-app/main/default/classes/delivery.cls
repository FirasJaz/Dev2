/*/****************************************************************************************************************************
// Erstellt 29.05.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: keine - batch
// 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//  Löst die Lieferungen aus.
//  
//
//****************************************************************************************************************************
//Änderungen:       
//****************************************************************************************************************************
*/
public class delivery implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    public list<string> errorList = new list<string>();
    public integer totalDN = 0;
 
    public Database.querylocator start(Database.BatchableContext BC) {
        //string query = 'SELECT id FROM contact WHERE id IN (SELECT Contact__c FROM Delivery_Line__c WHERE Delivery_Status__c = \'Bedarf\' AND Delivery_date__c <= TODAY)';
        string query = 'SELECT id FROM contact WHERE id IN (SELECT Contact__c FROM Delivery_Line__c WHERE Delivery_Status__c = \'Bedarf\' AND Delivery_date__c <= TODAY) AND id in (\'0035800000UFdTWAA1\',\'0031i00000Kwv0gAAB\',\'0031i00000QoXNgAAN\',\'0031i00000QoXIQAA3\',\'0031i00000QoFtjAAF\')';
        Database.QueryLocator ql = Database.getQueryLocator(query);
        limitInfo.limitImage(limitInfo.getCurrentClassMethod());  
        return ql;
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<contact> ctList = (List<contact>)scope;
        set<id> ctIdSet = new set<id>();
        for(contact ct : ctList) {
            ctIdSet.add(ct.id);
        }  
        delivery_xml dxml = new delivery_xml();
        dxml.processBedarf(ctIdSet);             
        if(dxml.getErrorListSize() > 0) {
            if(errorList.size() <= 800) errorList.addAll(dxml.getErrorList());
        }
        totalDN += dxml.getTotalDN();
        limitInfo.limitImage(limitInfo.getCurrentClassMethod());
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
            String subject = 'Job Lieferungen Auslösen gelaufen. ' + string.valueOf(totalDN) + ' erstellt.';

            string PlainTextBody = 'Job Lieferungen Auslösen gelaufen</br>';
            
            if(errorList.size() > 0) {
                subject += ' Es gab Fehler';
                for(string line : errorList) {
                    String v1 = '\r\n' + '</br>';
                    PlainTextBody += line + v1;
                }
            }
            else {
                PlainTextBody += 'keine Fehler. \r\n';
            }

            mail.setPlainTextBody(PlainTextBody);
            mail.setHtmlBody(PlainTextBody);
            mail.setSubject(subject);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });                   
        }
        catch (System.Exception e)
        {
            system.debug('#########################Email error ' + e);
        }       
        limitInfo.limitImage(limitInfo.getCurrentClassMethod());  
    }        
            
    public void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new delivery(), 200);
    }

}