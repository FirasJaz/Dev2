//****************************************************************************************************************************
// Erstellt 11.06.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Test for addressHelper
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
@isTest
public class addressHelper_test {
    @testSetup static void dataForTest() {
        create_test_product.createProducts();
    }

    static testMethod void addressTest() {
        create_test_product.createTestContacts(5);
        test.startTest(); 
        
        List<contact_address__c> adList = [SELECT id, name FROM contact_address__c];
        //System.assertEquals(adList.size() , 6);
        List<contact> ctList = [SELECT id, lastname, firstname, MailingStreet, Betreuer__c FROM contact];
        ctList[0].MailingStreet = 'contactstreet';
        update ctList;
        id testContactId = ctList[0].id;
        contact_address__c test1 = [SELECT id, name, Street__c FROM contact_address__c WHERE contact__c = :testContactId];
        System.assertEquals(test1.Street__c , 'contactstreet');
        contact_address__c newCA = new contact_address__c(Contact__c=testContactId, Street__c = 'teststreet', Type_of_Address__c='family member', Standard_shipping_address__c=true);
        insert newCA;

        // check update second 'customer address'
        newCA.Type_of_Address__c='customer address';
        try {
            update newCA;
        }
        catch(System.Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('contact has already the "customer address". Please select other address type.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }

        // check delete standard address
        try {
            delete newCA;
        }
        catch(System.Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Default delivery address can not be deleted.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }

        contact_address__c newCA2 = new contact_address__c(Contact__c=testContactId, Street__c = 'teststreet 22', Type_of_Address__c='customer address', Standard_shipping_address__c=true);
        try {
            insert newCA2;
        }
        catch(System.Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('contact has already the "customer address". Please select other address type.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        // check with betreuer



        test.stopTest();
    }

    static testMethod void addressBetreuerTest() {
        test.startTest();
        create_test_product.createFamilyFromBetreuer();
        test.stopTest(); 
         // es soll 3 Adressen sein - 1 für Betreuer und 2 für contact
        List<contact_address__c> adList = [SELECT id, name FROM contact_address__c WHERE Type_of_Address__c='family member'];
        // Betreuer 1 address
        System.assertEquals(1 , adList.size());
        adList = [SELECT id, name FROM contact_address__c WHERE Type_of_Address__c='customer address'];
        // Betreuer 2 addresses
        System.assertEquals(2 , adList.size());
    }

    @isTest
    static void checkStandardShippingAddress_NoStandardShipping_PreventUpdate()  {
        //SETUP
        create_test_product.createTestContacts(5);
        List<contact> ctList = [SELECT id, lastname, firstname, MailingStreet, Betreuer__c FROM contact];
        id testContactId = ctList[0].id;
        contact_address__c ca = [SELECT id, name, Street__c FROM contact_address__c WHERE contact__c = :testContactId];
        // ACTION
        ca.Standard_shipping_address__c=false ;

        try{
            update ca ;
        }
        catch(Exception e){
            // VERIFY
        System.AssertEquals(e.getMessage().contains(System.Label.CONTACT_ADDRESS_ERR_ONLY_ONE_STANDARD_SHIPPING), true);
                
        }
    
    
    }
    
}