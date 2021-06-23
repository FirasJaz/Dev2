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
// While inserting delivery notes, address informations from contact address records are saved in delivery notes 
// 
//
//****************************************************************************************************************************
// Changes:
//     30.10.2019    BT    While saving address informations postal code field from contact address is ignored                          
//****************************************************************************************************************************
trigger before_insert_delivery_note on Delivery_Note__c (before insert) {
    Map<Delivery_note__c, Id> dnToContactMap = new Map<Delivery_note__c, Id>();
    Map<Id, Contact_address__c> addressMap = new Map<Id, Contact_address__c>();
    Id tempContactId;
    Contact_address__c tempAddress;
    
    for(Delivery_note__c dn: Trigger.New) {
       if(dn.Contact__c != null) {
           dnToContactMap.put(dn, dn.Contact__c);
       }
    }
    
    for(Contact_address__c ca: [select Street__c, House_number__c, City__c, Postal_code__c, Contact__c 
                                                    from Contact_address__c
                                                    where Standard_shipping_address__c = true
                                                    and Contact__c in :dnToContactMap.values()]) {                                                    
        addressMap.put(ca.Contact__c, ca);
    }
    
    for(Delivery_note__c dn: dnToContactMap.keySet()) {
        tempContactId = dnToContactMap.get(dn);
        tempAddress = addressMap.get(tempContactId);
        
        if(tempAddress != null) {
            dn.Street__c = tempAddress.Street__c;                        
            dn.PostalCode__c = tempAddress.Postal_code__c;
            dn.City__c = tempAddress.City__c;
        }
    }    
}