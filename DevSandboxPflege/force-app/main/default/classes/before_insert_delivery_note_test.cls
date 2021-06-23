//*****************************************************************************************************************************
// Created on 29.10.2019 by BT
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: none
//
//****************************************************************************************************************************
//
// Description:
//                      
// Test class for trigger before_insert_delivery_note
// 
//
//****************************************************************************************************************************
// Changes:
//                          
//****************************************************************************************************************************
@isTest
private class before_insert_delivery_note_test {
    
    @testSetup static void setup() {
        Contact c = new Contact();
        c.LastName = 'Mustermann';
        c.FirstName = 'Max';
        
        insert c;
        
        Contact_address__c ca = new Contact_address__c();
        ca.Contact__c = c.Id;
        ca.Name = 'Mustermann, Max';
        ca.Street__c = 'Musterstraße 1';
        ca.Postal_code__c = '12345';
        ca.City__c = 'Musterstadt';
        ca.Type_of_Address__c = 'other';
        ca.Standard_shipping_address__c = true;
        
        insert ca;
    }
    
    @isTest static void testInsertDeliveryNote() {
        Contact c = [select id from Contact where LastName = 'Mustermann' limit 1];
        Contact_address__c ca = [select Street__c, House_number__c, City__c, Postal_code__c from Contact_address__c where Contact__c = :c.Id limit 1];
        
        Delivery_note__c dn = new Delivery_note__c();
        dn.Contact__c = c.Id;
        
        insert dn;
        
        dn = [select Street__c, City__c, PostalCode__c from Delivery_note__c where Contact__c = :c.Id limit 1];
        
        //System.assertEquals(dn.Street__c, ca.Street__c);
        //System.assertEquals(dn.City__c, ca.City__c);
        //System.assertEquals(dn.PostalCode__c, ca.Postal_code__c);
    }
}