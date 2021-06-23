/****************************************************************************************************************************
// Created 13.05.2019 von  AD
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
//
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Curabox_Edit_Order {
    
    @AuraEnabled
    public static List<Order__c> getOrders(String contactId){
        List<Order__c> orderList = new List<Order__c>();
        try {
            orderList = [select Id, Name, Status__c, Nach_Paragraph__c, Liefertag__c, Delivery_frequency__c, Description__c, Pausieren__c, Contact__c, Genehmigt_von__c, 
                        Genehmigt_bis__c, Unbefristet_genehmigt__c, pausingDisabled__c, terminateDisabled__c from Order__c where Contact__c =:contactId order by CreatedDate Desc];
        } catch (Exception e) {
            System.debug(e);
        }
        return orderList;
    }

    @AuraEnabled
    public static String getWunschCB(String contactId){
        return Product_List.getWunschCurabox(contactId);
    }

    // update order status and delete all delivery lines with status 'bedarf'
    @AuraEnabled
    public static string terminateOrder(Order__c order){
        String returnString = '';
        if (order.Id != null && !String.isEmpty(order.Id)) {
            setOrderStatus(order.Id, 'beendet');
            returnString = deleteBedarf(order.Id);
        }
        return returnString;
    }

    // pausing the order
    @AuraEnabled
    public static string pausingOrder(Order__c order){
        String returnString = '';
        Date today = System.today();
        Integer intervall = Integer.valueOf(Due_Date__c.getValues('Auftrag pausiert').Follow_Up_Task_Due_Date__c);
        Date dueDate = today.addMonths(intervall);
        if (order.Id != null && !String.isEmpty(order.Id)) {
            setOrderStatus(order.Id, 'pausiert');
            setButtonLabel(order.Id, 'Aktivieren');
            returnString = deleteBedarf(order.Id);
            Follow_Up_Task_Helper.insertFollowUpTask(order.Contact__c, 'Lieferung angehalten', 'Auftrag pausieren', dueDate, 'Offen');
        }
        return returnString;
    }

    // activate the order: create new Delivery lines with status 'Bedarf'
    @AuraEnabled
    public static string activateOrder(Order__c order, Date datum){
        String returnString = '';
        if (order.Id != null && !String.isEmpty(order.Id)) {
            setOrderStatus(order.Id, 'aktiv');
            setButtonLabel(order.Id, 'Pausieren');
            insertBedarf( updateOrderDate(order.Id, datum));
            returnString = 'OK';
        }
        return returnString;
    }

    // update order, wird momentan nicht benutzt.
    /*
    @AuraEnabled
    public static string updateOrderSave(List<Order__c> order){
        String returnString = '';
        if (order != null && order.size() > 0) {
           try {
               update order;
           } catch (Exception e) {
               returnString = null;
               System.debug(e);
           }
        }
        return returnString;
    }*/

    // insert new delivery lines
    public static void insertBedarf(Order__c order){
        List<Order_Line__c>  orderList = getOrderLines(order.Id);
        List<Delivery_Line__c> dLines = new List<Delivery_Line__c>();
        if (orderList.size() > 0) {
            for (Order_Line__c line : orderList) {
                dLines.add(Delivery_Line.newDeliveryLine(order, line, order.Contact__c, 'Bedarf'));
            }
        }
        try {
            insert dLines;
        } catch (Exception e) {
            System.debug('Fehler beim Anlegen der Bedarfe bei der Wiederaktivierung' + order);
        }
    }

    // delete delivery lines mit status 'Bedarf'
    public static String deleteBedarf(String orderId){
        String returnString = '';
        List<Delivery_Line__c> dList = Delivery_Line.getDeliveryLines(orderId, 'Bedarf');
        try {
            delete dList;
        } catch (Exception e) {
            returnString = null;
           System.debug(e); 
        }
        return returnString;
    }

    // update order status
    public static void setOrderStatus(String orderId, String status){
        Order__c order = Curabox_Helper.getOrderById(orderId);
        order.Status__c = status;
        try {
            update order;
        } catch (Exception e) {
            System.debug(e);
        }
    }

    // update order date
    public static Order__c updateOrderDate(String orderId, Date datum){
        Order__c order = Curabox_Helper.getOrderById(orderId);
        order.Liefertag__c = datum;
        try {
            update order;
        } catch (Exception e) {
            System.debug(e);
        }
        return order;
    }

    // update button label
    public static void setButtonLabel(String orderId, String status){
        Order__c order = Curabox_Helper.getOrderById(orderId);
        order.Pausieren__c = status;
        try {
            update order;
        } catch (Exception e) {
            System.debug(e);
        }
    }

    // get all order lines that contains a order.
    @AuraEnabled
    public static List<Order_Line__c> getOrderLines(String orderId){
        List<Order_Line__c> lineList = new List<Order_Line__c>();
        try {
            lineList = [Select Id, Name, Product__c, Product__r.Name, Product__r.Price__c, Gen_Menge_Stk_Mon__c, Price__c, Lieferstatus__c from Order_Line__c where Order__c =:orderId];
        } catch (Exception e) {
            System.debug(e);
        }
        return lineList;
    }

    @AuraEnabled
    public static Boolean checkMonthCurrentOrder(String contactId, Date lieferdatum, String curabox){
        return Create_Order.checkMonthCurrentOrder(contactId, lieferdatum, curabox);
    }


}