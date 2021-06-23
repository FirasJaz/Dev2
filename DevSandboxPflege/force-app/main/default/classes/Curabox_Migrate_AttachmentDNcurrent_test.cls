/****************************************************************************************************************************
// Created 15.08.2019 von  AM
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
// Test class for Curabox_Migrate_AttachmentDNcurrent
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public with sharing class Curabox_Migrate_AttachmentDNcurrent_test {

    @testSetup 
    static void setup() {
        // create Test data
        List<Contact> conList = new List<Contact>();
        List<Kunde__c> kundeList = new List<Kunde__c>();
        List<Lieferschein__c> lsList = new List<Lieferschein__c>();
        List<Delivery_Note__c> dnList = new List<Delivery_Note__c>();
        List<Attachment> attList = new List<Attachment>();
        for (Integer i = 0; i < 10; i++){
            Kunde__c  kunde = new Kunde__c(Name__c = 'Alex '+i, Produktgruppe__c ='PG54');
            kundeList.add(kunde);
        }
        insert kundeList;
        if (kundeList != null && kundeList.size() > 0) {
            for (Kunde__c client : kundeList) {
                Contact contact = new Contact(LastName =client.Name__c, Kunde_Id__c = client.Id);
                conList.add(contact);
            }
            insert conList;

        }

        for (Integer i = 0; i < 10; i++){
            Lieferschein__c  ls = new Lieferschein__c(Kunde__c = kundeList[i].id);
            lsList.add(ls);
        }
        insert lsList;
        List<Lieferschein__c> newList = [SELECT id, Name FROM Lieferschein__c];        
        for (Lieferschein__c ls : newList) {
            system.debug('####' + ls.name);
            Delivery_Note__c dn = new Delivery_Note__c(Contact__c = conList[0].id, old_LS_Name__c=ls.name);
            dnList.add(dn);
            Attachment attachment = new Attachment();
            attachment.Body = Blob.valueOf('Test String');
            attachment.Name = String.valueOf('test.pdf');
            attachment.Description = 'Hello';
            attachment.ParentId = ls.Id;
            attList.add(attachment);
        }
        insert attList;
        insert dnList;
    }

    static testmethod void test() {   
        Test.startTest();
        Curabox_Migrate_AttachmentDNcurrent uca = new Curabox_Migrate_AttachmentDNcurrent();
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();

        // after the testing stops, assert records were updated properly
        System.assertEquals([select count() FROM contentDocument], [select count() FROM attachment]);
    }    


}