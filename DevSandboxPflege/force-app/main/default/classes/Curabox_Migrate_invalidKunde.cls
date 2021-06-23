public with sharing class Curabox_Migrate_invalidKunde implements Database.Batchable<sObject>, Database.Stateful{
    public static list<string> errorList = new list<string>();
    public integer total = 0;    

    public Database.querylocator start(Database.BatchableContext BC) {
        string query = 'select id, parentId from attachment where parentId IN (SELECT id FROM Kunde__c) AND description != \'convertet\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        map<id, id> kundeContactMap = new map<id, id>();
        List<ContentVersion> files = new List<ContentVersion>();
        set<id> kdSet = new set<id>();
        set<id> atSet = new set<id>();
        integer count = 0;
        
        List<attachment> atiList = (List<attachment>)scope;
        // alle kunden 
        for(attachment at : atiList) {
            kdSet.add(at.parentid);
            atSet.add(at.id);
        }

        // alle contacts
        List<contact> ctList = [SELECT id, kunde_id__c FROM contact WHERE kunde_id__c IN: kdSet];
        for(contact c : ctlist) {
            kundeContactMap.put(id.valueOf(c.kunde_id__c), c.id);
        }   

        // attachments
        list<attachment> atList = [SELECT id, name, parentId, body, description 
                                        FROM attachment 
                                        WHERE Id IN : atSet
                                        AND description != 'convertet'
                                        LIMIT 1000];  
        // los
        for(attachment at : atList) {
            ContentVersion file = new ContentVersion();
            file.VersionData = at.Body;
            file.Title = at.Name;
            file.PathOnClient = at.Name;
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


        // system.debug('###### count=' + count);
        // Database.SaveResult[] srList = Database.update(caList, false); 

    }

    public void finish(Database.BatchableContext bc){      
        string test = 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
        test += 'aa';
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