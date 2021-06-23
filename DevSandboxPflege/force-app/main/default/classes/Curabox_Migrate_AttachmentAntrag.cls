/****************************************************************************************************************************
// Created 29.08.2019 von  AM
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
// convert attachment 'Antrag_PG' to files
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class Curabox_Migrate_AttachmentAntrag implements Database.Batchable<sObject>, Database.Stateful{
    public static list<string> errorList = new list<string>();
    public integer total = 0;

    public Curabox_Migrate_AttachmentAntrag() {}

    public Database.querylocator start(Database.BatchableContext BC) {
        string query = 'select id, name, parentid, body from attachment where parentid in (select kunde__c from kundenstatus__c where status__c in (\'Kandidat\', \'Interessent\') and Produktgruppe__c in (\'PG51\', \'PG54\' ) ) AND ((name LIKE \'Antr%\') OR (name LIKE \'CB_%\') OR (name LIKE \'Seit%\')) AND description != \'convertet\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        map<id, id> kundeContactMap = new map<id, id>();
        set<id> contSet = new set<id>();
        set<id> kdSet = new set<id>();
        List<ContentVersion> files = new List<ContentVersion>();
        
        List<attachment> atList = (List<attachment>)scope;
        // alle kunden 
        for(attachment at : atList) {
            kdSet.add(at.parentid);
        }

        // alle contacts
        List<contact> ctList = [SELECT id, kunde_id__c FROM contact WHERE kunde_id__c IN: kdSet];
        for(contact c : ctlist) {
            kundeContactMap.put(id.valueOf(c.kunde_id__c), c.id);
        }        

        // attachments
        // list<attachment> atList = [SELECT id, name, parentId, createddate, body 
        //                             FROM attachment 
        //                             WHERE parentId IN : kundeContactMap.keySet() 
        //                             AND ((name LIKE 'Antr%') OR (name LIKE 'CB_%') OR (name LIKE 'Seit%'))  
        //                             AND description != 'convertet'
        //                             ];        

        // los
        for(attachment at : atList) {
            ContentVersion file = new ContentVersion();
            file.VersionData = at.Body;
            file.Title = at.Name;
            file.PathOnClient = at.Name + '.pdf';
            file.FirstPublishLocationId = kundeContactMap.get(at.ParentId);

            
            file.ContentLocation = 'S';
            if(file.FirstPublishLocationId != null){
                system.debug('#### contact:' + file.FirstPublishLocationId);
                files.add(file);
                at.description = 'convertet';
            }
        }
        if (files != null && files.size() > 0) {
            try {
                insert files;
                update atList;
                total += files.size();
            } catch (Exception e) {
                System.debug('Fehler beim Inserieren der Files');
            }
        }           
    }

    public void finish(Database.BatchableContext bc){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setSaveAsActivity(false);
        mail.setSubject(string.valueOf(total) +' Attachments wurden übernommen');
        mail.setPlainTextBody(string.valueOf(total) + ' Attachments wurden übernommen.');
        mail.setHtmlBody(string.valueOf(total) + ' Attachments wurden übernommen.');
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