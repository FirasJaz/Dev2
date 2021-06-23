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
// convert attachment 'Genehmigung_PG' to files
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class Curabox_Migrate_AttachmentGenehmigung implements Database.Batchable<sObject>, Database.Stateful{
    
    public integer totalGenehmigung = 0;
    // public Curabox_Migrate_AttachmentGenehmigung() {}

    public Database.querylocator start(Database.BatchableContext BC) {
        string query = 'SELECT id, kunde_id__c FROM contact WHERE kunde_id__c != null';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        map<id, id> kundeContactMap = new map<id, id>();
        map<id, id> gen51Map = new Map<id, id>();
        map<id, id> gen54Map = new Map<id, id>();
        map<id, id> contactGen51Map = new Map<id, id>();
        map<id, id> contactGen54Map = new Map<id, id>();
        List<ContentVersion> files = new List<ContentVersion>();
        set<id> contSet = new set<id>();

        List<contact> ctList = (List<contact>)scope;

        for(contact c : ctlist) {
            kundeContactMap.put(id.valueOf(c.kunde_id__c), c.id);
            contSet.add(c.id);
        }

        List<Curabox_Genehmigung__c> newgnList = [SELECT id, Nach_Paragraph__c, Contact__c 
                                                    FROM Curabox_Genehmigung__c
                                                    WHERE Contact__c IN :contSet
                                                    AND Status__c IN ('Bewilligung', 'Teilbewilligung') 
                                                    AND ((genehmigt_bis__c >= TODAY) OR (unbefristet_genehmigt__c = true))];
        for(Curabox_Genehmigung__c gn : newgnList) {
            if(gn.Nach_Paragraph__c == '51') {
                if(!contactGen51Map.containsKey(gn.Contact__c)) {
                    contactGen51Map.put(gn.Contact__c, gn.id); 
                }
            }
            if(gn.Nach_Paragraph__c == '54') {
                if(!contactGen54Map.containsKey(gn.Contact__c)) {
                    contactGen54Map.put(gn.Contact__c, gn.id); 
                }
            }
        }                       



        List<Genehmigung__c> oldgnList = [SELECT id, Kunde__c, Nach_Paragraph__c, createddate 
                                            FROM Genehmigung__c 
                                            WHERE Status__c IN ('Bewilligung', 'Teilbewilligung') 
                                            AND ((genehmigt_bis__c >= TODAY) OR (unbefristet_genehmigt__c = true))
                                            AND Kunde__c IN : kundeContactMap.keySet()
                                            ORDER BY Kunde__c, Nach_Paragraph__c, createddate DESC];
        for(Genehmigung__c gn : oldgnList) {
            if(gn.Nach_Paragraph__c == '51') {
                if(!gen51Map.containsKey(gn.Kunde__c)) {
                    gen51Map.put(gn.Kunde__c, contactGen51Map.get(kundeContactMap.get(gn.Kunde__c))); 
                }
            }
            if(gn.Nach_Paragraph__c == '54') {
                if(!gen54Map.containsKey(gn.Kunde__c)) {
                    gen54Map.put(gn.Kunde__c, contactGen54Map.get(kundeContactMap.get(gn.Kunde__c))); 
                }
            }
        }
        // gen5XMap key=kundeId, value=newGenId

        set<string> toConvertSet = new Set<string>();
        list<attachment> toConvertList = new list<attachment>();
        list<attachment> gnList = [SELECT id, name, parentId, createddate, body 
                                    FROM attachment 
                                    WHERE parentId IN : kundeContactMap.keySet() 
                                    AND name = 'Genehmigung_PG54.pdf' and lastmodifieddate = yesterday
                                    AND description = null
                                    ORDER BY ParentId, name, createddate DESC]; 
        for(attachment at : gnList) {
            string key;
            if(at.name.containsIgnoreCase('PG54')) {
                key = string.valueOf(at.ParentId) + 'PG54';
            }
            else if(at.name.containsIgnoreCase('PG51')) {
                key = string.valueOf(at.ParentId) + 'PG51';
            }
            if(!toConvertSet.contains(key)) {
                toConvertSet.add(key);
                toConvertList.add(at);
            }
        }

        if(!toConvertList.isEmpty()) {
            for(attachment at : toConvertList) {
                // system.debug('###' + at.parentid + ' ' + at.name + ' ' + at.createddate);
                
                ContentVersion file = new ContentVersion();
                file.VersionData = at.Body;
                file.Title = at.Name;
                file.PathOnClient = at.Name + '.pdf';
                if(at.name.containsIgnoreCase('54')) {
                    file.FirstPublishLocationId = gen54Map.get(at.ParentId);
                }
                else {
                    file.FirstPublishLocationId = gen51Map.get(at.ParentId);
                }
                
                file.ContentLocation = 'S';
                if(file.FirstPublishLocationId != null){
                    system.debug('#### cb_Genehmigung:' + file.FirstPublishLocationId);
                    files.add(file);
                    at.description = 'convertet';
                }
            }
            if (files != null && files.size() > 0) {
                try {
                    insert files;
                    update gnList;
                    totalGenehmigung += files.size();
                } catch (Exception e) {
                    System.debug('Fehler beim Inserieren der Files');
                }
            }   
        }
    }

    public void finish(Database.BatchableContext bc){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setSaveAsActivity(false);
        mail.setSubject(string.valueOf(totalGenehmigung) +' Attachments wurden übernommen');
        mail.setPlainTextBody(string.valueOf(totalGenehmigung) + ' Attachments wurden übernommen.');
        mail.setHtmlBody(string.valueOf(totalGenehmigung) + ' Attachments wurden übernommen.');
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