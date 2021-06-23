/****************************************************************************************************************************
// Created 14.08.2019 von  AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// 
//
//****************************************************************************************************************************
//
// Description:       
// convert attachment XML Lieferschein and Ablieferbeleg to files
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class Curabox_Migrate_AttachmentDNcurrent implements Database.Batchable<sObject>, Database.Stateful {
    public integer totalAttachments = 0;

    public Database.querylocator start(Database.BatchableContext BC) {
        string query = 'SELECT id, old_LS_Name__c FROM Delivery_Note__c WHERE old_LS_Name__c != null';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<id, id> lsDnMap = new Map<id, id>();
        Map<string, id> lsNameMap = new Map<String, id>();
        List<ContentVersion> files = new List<ContentVersion>();

        List<Delivery_Note__c> dnList = (List<Delivery_Note__c>)scope;
        for(Delivery_Note__c dn : dnList) {
            lsNameMap.put(dn.old_LS_Name__c, dn.id);
        }
        List<Lieferschein__c> lsList = [SELECT id, name FROM Lieferschein__c WHERE name IN : lsNameMap.keySet()];
        for(Lieferschein__c ls : lsList) { 
            lsDnMap.put(ls.id, lsNameMap.get(ls.name));
        }
        list<attachment> atList = [SELECT id, name, parentId, body 
                            FROM attachment 
                            WHERE parentId IN : lsDnMap.keySet() 
                            AND description != 'convertet']; 
        for(attachment at : atList) {
            ContentVersion file = new ContentVersion();
            file.VersionData = at.Body;
            file.Title = at.Name;
            file.PathOnClient = at.Name + '.pdf';
            file.FirstPublishLocationId = lsDnMap.get(at.ParentId);
            file.ContentLocation = 'S';
            at.description = 'convertet';
            files.add(file);
            system.debug('#### dn:' + file.FirstPublishLocationId);
        }
        if (files != null && files.size() > 0) {
            try {
                insert files;
                update atList;
                totalAttachments += files.size();
            } catch (Exception e) {
                System.debug('Fehler beim Inserieren der Files');
            }
        }	        

    }

    public void finish(Database.BatchableContext bc){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setSaveAsActivity(false);
        mail.setSubject(string.valueOf(totalAttachments) +' Attachments wurden übernommen');
        mail.setPlainTextBody(string.valueOf(totalAttachments) + ' Attachments wurden übernommen.');
        mail.setHtmlBody(string.valueOf(totalAttachments) + ' Attachments wurden übernommen.');
        String email = 'kontakt@klosesrockepartner.de';
        String[] toAddress = new String[] {email};
        mail.setToAddresses(toAddress);
       
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );
        } catch (Exception e) {
        	System.debug('Datenübernahme Error: ' + e.getMessage());
        }       
    }
}