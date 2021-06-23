@isTest
public with sharing class curabox_tool_orders_test {

    @testSetup 
    static void setup() {
        // create Test data
         create_test_product.createProducts();
         create_test_product.createTestContacts();
         create_test_product.createGenehmigung();
         create_test_product.createOrders();
        List<Delivery_Line__c> dlList = new List<Delivery_Line__c>();
        List<Order_Line__c> oliList = [SELECT id, Product__c, Gen_Menge_Stk_Mon__c, Order__r.Contact__c
                                        FROM Order_Line__c
                                        LIMIT 100];

        system.debug('##### oliList=' + oliList.size());
        for(Order_Line__c ol : oliList) {
            Delivery_Line__c dl = new Delivery_Line__c(Quantity__c=10, Contact__c=ol.Order__r.Contact__c);
            dl.Product__c = ol.Product__c;
            dl.Delivery_date__c = date.today();
            dl.Delivery_status__c = 'Bedarf';
            dlList.add(dl);
        }

        Database.SaveResult[] srList = Database.insert(dlList, false);              
    }

    static testmethod void test() {  
        Test.startTest();
        curabox_tool_orders uca = new curabox_tool_orders();
        Id batchId = Database.executeBatch(uca, 500);
        Test.stopTest();
    }    


}