/****************************************************************************************************************************
// Created 26.04.2019 von  AD
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
//  Contact Id
//  Order_Line__c
//  Delivery_Note__c
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

/**
*  Initialize a new delivery line and return this
*/
public with sharing class Delivery_Line {

    public static Delivery_Line__c newDeliveryLine(Order__c order, Order_Line__c orderLine, String contactId, String status){
        Integer numberOfDays = Date.daysInMonth(order.Liefertag__c.year(), order.Liefertag__c.month());
        Delivery_Line__c line = new Delivery_Line__c();
        line.Contact__c = contactId;
        line.Delivery_status__c = status;
        line.Order_line__c = orderLine.Id;
        line.Product__c = orderLine.Product__c;
        line.Quantity__c = orderLine.Gen_Menge_Stk_Mon__c;
        line.Delivery_date__c = order.Liefertag__c;
        line.VZ_von__c = Date.newInstance(order.Liefertag__c.year(), order.Liefertag__c.month(), 1);
        line.VZ_bis__c = Date.newInstance(order.Liefertag__c.year(), order.Liefertag__c.month(), numberOfDays);
        return line;
    }
    
    /**
    *  create all delivery lines for a contact
    *  return the list of created delivery lines
    */
    public static List<Delivery_Line__c> createDeliveryLines(Order__c order, List<Order_Line__c> orderLineList, String contactId, String status) {
        List<Delivery_Line__c> deliveryLineList = new List<Delivery_Line__c>();
        for (Order_Line__c orderLine : orderLineList) {
            deliveryLineList.add(newDeliveryLine(order, orderLine, contactId, status));
        }
        return deliveryLineList;
    }

    // get all delivery lines 
    public static List<Delivery_Line__c> getDeliveryLines(String orderId, String status){
        List<Delivery_Line__c> deliveryLines = new List<Delivery_Line__c>();
        List<Id> orderLines = Create_Order_Line.getOrderLinesIds(orderId);
        try {
            deliveryLines = [Select Id, Name from Delivery_Line__c where Delivery_status__c =: status and Order_line__c IN : orderLines];
        } catch (Exception e) {
            System.debug(e);
        }
        return deliveryLines;
    }

}