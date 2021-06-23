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
public with sharing class Curabox_Migrate_AttachmentAntrag_test {
    @testSetup 
    static void setup() {
        // create Test data
        List<Contact> conList = new List<Contact>();
        List<Kunde__c> kundeList = new List<Kunde__c>();
        List<Attachment> attList = new List<Attachment>();
        for (Integer i = 0; i < 10; i++) {
            Kunde__c  kunde = new Kunde__c(Name__c = 'Alex '+i, Produktgruppe__c ='PG54');
            kundeList.add(kunde);
        }
        insert kundeList;
        if (kundeList != null && kundeList.size() > 0) {
            for (Kunde__c client : kundeList) {
                Contact contact = new Contact(LastName =client.Name__c, Kunde_Id__c = client.Id);
                conList.add(contact);
                Attachment attachment = new Attachment();
                attachment.Body = Blob.valueOf('Test String');
                attachment.Name = String.valueOf('Antrag.pdf');
                attachment.Description = 'Hello';
                attachment.ParentId = client.Id;
                attList.add(attachment);            
            }
            insert conList;
            insert attList;
            List<contact_status__c> csList = new List<contact_status__c>();
            for(contact c : conList) {
                contact_status__c cs = new contact_status__c(Contact__c = c.id, Status__c='Kandidat');
                csList.add(cs); 
            }
            insert csList;
        }
    }

    static testmethod void test() {   
        Test.startTest();
        Curabox_Migrate_AttachmentAntrag uca = new Curabox_Migrate_AttachmentAntrag();
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();

        // after the testing stops, assert records were updated properly
        System.assertEquals([select count() FROM contentDocument], [select count() FROM attachment]);
    }    
}