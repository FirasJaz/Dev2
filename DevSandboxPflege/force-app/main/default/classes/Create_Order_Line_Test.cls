@isTest
private class Create_Order_Line_Test {

    @isTest static void getOrderLinesIds(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders and opportunities
        create_test_product.createOrders();
        Order__c order = [SELECT Id, Name FROM Order__c WHERE Contact__c =: contactId];
        String orderId = order.Id;
        // Test
        List<Id> orderLines = Create_Order_Line.getOrderLinesIds(orderId);
        System.assertNotEquals(0, orderLines.size());
    }
    
}