//****************************************************************************************************************************
    // Erstellt 02.06.2019 von AM
    //                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
    //                         Nordkanalstr. 58
    //                         20097 Hamburg 
    //                         Tel.:  04023882986
    //                         Fax.: 04023882989
    //                         Email: kontakt@klosesrockepartner.de
    //
    //****************************************************************************************************************************
    //
    // Parameter: 
    // xxxx
    //
    //****************************************************************************************************************************
    //
    // Beschreibung:
    //                      
    // Sorgt für das Anlegen der Anschriften (contact_address)
    //
    //
    //****************************************************************************************************************************
    //Änderungen:
    //
    //****************************************************************************************************************************
    trigger contact_addressTrigger on contact_address__c (before insert, after insert, before update, after update, before delete) {
        set<id> parentIdSet = new set<id>();
        if(trigger.isInsert) {
            if(trigger.isBefore) {
                // da prüfen wir ob eine 'customer address' bereits existiert
                // "Es kann nur einen geben"
                addressHelper.checkBeforeinsertNewAddress(trigger.new);
            }
            if(trigger.isAfter) {
                // hier ist nur Standard_shipping_address__c relevant
                addressHelper.insertNewAddress(Trigger.new);   
            }   
        }
        if(trigger.isUpdate) {
            if(trigger.isBefore) {
                // da prüfen wir ob eine 'customer address' bereits existiert
                addressHelper.checkBeforeUpdateAddress(trigger.new, trigger.oldMap);
                addressHelper.checkStandardShippingAddress(trigger.newMap,trigger.oldMap);
            }  
            if(trigger.isAfter) {
                // da prüfen wir ob eine 'customer address' bereits existiert
                addressHelper.checkStandard(trigger.new, trigger.oldMap);
            }        
        }
        if(trigger.isDelete) {
            // Default delivery address can not be deleted
            addressHelper.checkBeforeDeleteAddress(trigger.old);
        }
    }