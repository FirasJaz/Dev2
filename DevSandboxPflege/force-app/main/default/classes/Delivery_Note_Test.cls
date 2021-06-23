@isTest
public class Delivery_Note_Test {

        @isTest static void createDeliveryByAntrag(){
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
        Delivery_Note.createDeliveryByAntrag(contactId, '54', order, orderLineList);
        List<Delivery_Line__c> lineList = [SELECT Id, Name FROM Delivery_Line__c WHERE Delivery_status__c ='Bedarf' AND Contact__c =: contactId];

        Id addressId = Delivery_Note.getAddressbyContact(contactId);
        //Tests
        System.assertNotEquals(0, lineList.size());
        System.assertNotEquals(null, addressId);
    }

}