/**
 * Trigger on the object Contact_Status__c 
 */
trigger ContactStatusTrigger on Contact_Status__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert){
      
        }

        if (Trigger.isUpdate){
            ContactStatusTriggerHandler.handleBeforeUpdate(Trigger.oldMap,Trigger.newMap);
        }
    }
    if (Trigger.isAfter) {

        if (Trigger.isInsert) {

        }
        if(Trigger.isUpdate){
       
        }
    }


}