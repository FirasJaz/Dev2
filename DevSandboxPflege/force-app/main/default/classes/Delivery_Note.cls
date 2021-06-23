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
//
//****************************************************************************************************************************
//
// Description:       
//	
//
//****************************************************************************************************************************
// Changes: 
// 02.06.2019 AM replace Anschrift__c with contact_address__c
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Delivery_Note {
    
    /**
    *  create delivery note and lines if the Insurance is cooperativ or when the request is approved.
    */
    public static void createDeliveryByAntrag(String contactId, String paragraph, Order__c order, List<Order_Line__c> orderLineList){
        insertDelivery(contactId, paragraph, 'Bedarf', order, orderLineList);
    }

    /**
    *  insert delivery note and lines in the database 
    */
    public static void insertDelivery(String contactId, String paragraph, String status, Order__c order, List<Order_Line__c> orderLineList){
        List<Delivery_Line__c> DlineList = Delivery_Line.createDeliveryLines(order, orderLineList, contactId, status);
        try {
            insert DlineList;
        } catch (Exception e) {
            System.debug('Beim Einlegen der Lieferpositionen ist folgende Fehler aufgetreten: '+e);
        }
    }

    public static id getAddressbyContact(String contactId) {
        try{ 
            contact_address__c address = [SELECT id FROM contact_address__c WHERE Contact__c =: contactId 
                                            AND Standard_shipping_address__c = true
                                            LIMIT 1]; 
            return address.id;                                
        }      
        catch(Exception e){
            System.debug(e);
            return null;
        }
    }
}