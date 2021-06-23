/****************************************************************************************************************************
// Erstellt 17.07.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: keine
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//             Batch/Schedule - prüft ob eine Genehmigung abgelaufen und sendet e-Mail
//
//****************************************************************************************************************************
// Test:  
//*****************************************************************************************************************************
// Änderungen:   
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class ApprovalExpires implements Database.Batchable<sObject>, Schedulable, Database.Stateful  {

    public Database.querylocator start(Database.BatchableContext BC) {
        date dueDate;
        try {
            dueDate = date.today().addDays(integer.valueOf((Due_Date__c.getValues('Genehmigung abgelaufen').Follow_Up_Task_Due_Date__c) * (-1)));
        }
        catch (System.Exception e) {
            dueDate = date.today().addDays(-14);
        }
        string query = 'SELECT id, Contact__c, Contact__r.email FROM Curabox_Genehmigung__c WHERE unbefristet_genehmigt__c = false AND Status__c = \'Bewilligung\' AND genehmigt_bis__c <= : dueDate AND Contact__r.email != null';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  
                                              from EmailTemplate 
                                              where DeveloperName = 'Genehmigung_laeuft_aus' limit 1];
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Curabox_Genehmigung__c> gnList = (List<Curabox_Genehmigung__c>)scope;
        for(Curabox_Genehmigung__c gn : gnList) {
            Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            String[] toAddress = new String[]{gn.Contact__r.email};
            String[] toCcAddress = new String[]{'kontakt@klosesrockepartner.de'};
            mail.setToAddresses(toAddress);
            mail.setCcAddresses(toCcAddress);
            mail.setTargetObjectId(gn.Contact__c);
            mail.setTemplateId(etList[0].id);
            mails.add(mail);   
        }
        Messaging.sendEmail(mails); 
    }

    public void finish(Database.BatchableContext BC){
        // String[] toAddress, toCcAddress;
        
        // Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();   

        // try{
        //     toAddress = new String[] {Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse__c};
        //     toCcAddress = Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse_CC__c.split(', ');
        // }
        // catch(System.exception e){
        //     toAddress = new String[]{'kontakt@klosesrockepartner.de'};
        //     toCcAddress = new String[]{'kontakt@klosesrockepartner.de'};
        // }

        // try {        
        //     mail.setToAddresses(toAddress);
        //     mail.setCcAddresses(toCcAddress);
        //     mail.setSubject('Job Lieferungen Auslösen gelaufen');
        //     string PlainTextBody = 'Job Lieferungen Auslösen gelaufen';
            
        //     if(errorList.size() > 0) {
        //         for(string line : errorList) {
        //             String v1 = '\r\n';
        //             PlainTextBody += line + v1;
        //         }
        //     }
        //     else {
        //         PlainTextBody += 'keine Fehler. \r\n';
        //     }

        //     mail.setPlainTextBody(PlainTextBody);
        //     mail.setHtmlBody(PlainTextBody);
            // Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });                   
        // }
        // catch (System.Exception e)
        // {
        //     system.debug('#########################Email error ' + e);
        // }         
    }        
            
    public void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new ApprovalExpires(), 200);
    }    
}