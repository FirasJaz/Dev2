@isTest
public class Delivery_Line_Test {
    
    @isTest static void createDeliveryLines(){
    	// create products test data
        create_test_product.createProducts();
        // create contact
		create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders
        create_test_product.createOrders();
        Order__c order = [SELECT Id, Name, Liefertag__c FROM Order__c WHERE Contact__c =: contactId LIMIT 1];
        List<Order_Line__c> orderLineList = [SELECT Id, Name, Product__c, Gen_Menge_Stk_Mon__c FROM Order_Line__c WHERE Order__c =: order.Id];
        List<Delivery_Line__c> dList = Delivery_Line.createDeliveryLines(order, orderLineList, contactId, 'Bedarf');
        insert dList;
        String orderId = order.Id;
        List<Delivery_Line__c> lineList = Delivery_Line.getDeliveryLines(orderId, 'Bedarf');
        //Tests
        System.assertNotEquals(0, dList.size());
        System.assertNotEquals(0, lineList.size());
    }

}