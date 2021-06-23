/**
 * Trigger on the standard object Contact 
 */
trigger ContactTrigger on Contact (before insert, after insert, before update, after update, before delete, after delete, after undelete) { 

    if (Trigger.isBefore) {
        if (Trigger.isInsert){
      
        }

        if (Trigger.isUpdate){
        
        }
    }
    if (Trigger.isAfter) {

        if (Trigger.isInsert) {

        }
        if(Trigger.isUpdate){
           //ContactTriggerHandler.handleAfterUpdate(Trigger.oldMap,Trigger.newMap);
        }
    }


}