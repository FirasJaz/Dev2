/****************************************************************************************************************************
// Created 07.08.2019 von  AD
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
// Test class for Curabox_Migrate_Delivery_Note
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
private class Curabox_Migrate_Delivery_Test {

    @testSetup 
    static void setup() {
        // create Test data
        List<Contact> conList = new List<Contact>();
        List<Kunde__c> kundeList = new List<Kunde__c>();
        List<Lieferschein__c> lscheine = new List<Lieferschein__c>();
        List<Lieferscheinposition__c> positions = new List<Lieferscheinposition__c>();
        for (Integer i = 0; i < 10; i++){
            Kunde__c  kunde = new Kunde__c(Name__c = 'Alex '+i, Produktgruppe__c ='PG54');
            kundeList.add(kunde);
        }
        insert kundeList;
        if (kundeList != null && kundeList.size() > 0) {
            for (Kunde__c client : kundeList) {
                Contact contact = new Contact(LastName ='Alex', Kunde_Id__c = client.Id);
                conList.add(contact);
                Lieferschein__c schein = new Lieferschein__c();
                schein.Kunde__c = client.Id;
                lscheine.add(schein);
            }
            insert conList;
            insert lscheine;
            for (Lieferschein__c ls : lscheine) {
                Lieferscheinposition__c pos = new Lieferscheinposition__c(Kunde__c = ls.Kunde__c, Lieferschein__c = ls.Id);
                positions.add(pos);
            }
            insert positions;
        }
    }

    static testmethod void test() {        
        Test.startTest();
        Curabox_Migrate_Delivery_Note uca = new Curabox_Migrate_Delivery_Note();
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();
        // after the testing stops, assert records were updated properly
        //System.assertEquals(10, [select count() FROM Delivery_Note__c]);
    }

    
}