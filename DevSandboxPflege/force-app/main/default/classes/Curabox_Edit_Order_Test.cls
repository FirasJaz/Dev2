/****************************************************************************************************************************
// Created 19.07.2019 von  AD
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
//****************************************************************************************************************************
//
// Description:       
//  Test Klasse.
//****************************************************************************************************************************
// Changes:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

@isTest
private class Curabox_Edit_Order_Test {
    
    @testSetup static void dataForTest() {
        // custom settings
        Due_Date__c dueDate = new Due_Date__c(Name = 'Auftrag pausiert', Follow_Up_Task_Due_Date__c = 5);
        insert dueDate;
    }

    @isTest static void getOrders(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders
        create_test_product.createOrders();
        // Tests
        List<Order__c> result = Curabox_Edit_Order.getOrders(contactId);
        String curabox = Curabox_Edit_Order.getWunschCB(contactId);
        System.assertNotEquals(0, result.size());
        System.assertNotEquals(null, curabox);
    }

    @isTest static void terminateOrder(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders
        create_test_product.createOrders();
        create_test_product.createDeliverLinesBedarf();
        Order__c order = [SELECT Id, Name, Contact__c FROM Order__c WHERE Contact__c =:contactId LIMIT 1];
        // 
        String str = Curabox_Edit_Order.terminateOrder(order);
        System.assertNotEquals(null, str);
    }

    @isTest static void pausingOrder(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders
        create_test_product.createOrders();
        create_test_product.createDeliverLinesBedarf();
        Order__c order = [SELECT Id, Name, Contact__c FROM Order__c WHERE Contact__c =:contactId LIMIT 1];
        // 
        String str = Curabox_Edit_Order.pausingOrder(order);
        System.assertNotEquals(null, str);
    }

    @isTest static void activateOrder(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders
        create_test_product.createOrders();
        Order__c order = [SELECT Id, Name, Contact__c FROM Order__c WHERE Contact__c =:contactId LIMIT 1];
        // 
        String str = Curabox_Edit_Order.activateOrder(order, System.today());
        Boolean ex = Curabox_Edit_Order.checkMonthCurrentOrder(contactId, System.today(), 'CB1');
        System.assertNotEquals(null, str);
        System.assertEquals(true, ex);
    }
}