/**
 * This class contains all functions we can use inside
 * the contact trigger
 * 
 */

public  class ContactTriggerHandler {

    /**
    * Function, which includes all the code,
    * we execute on the before insert event
    *
    * @param newContacts List with the new values of the event -> Trigger.new context variable
    *
   */
  public static void handleBeforeInsert(List<Contact> newContacts)
  {
  
  }

  /**
      * Function, which includes all the code,
      * we execute on the after update event
      *
      * @param oldMap Map with the old values of the event -> Trigger.oldMap context variable
      * @param newMap Map with the new values of the event -> Trigger.newMap context variable
      *
     */
    public static void handleAfterUpdate(Map<Id, Contact> oldMap, Map<Id, Contact> newMap)
    {
        preventStatusCancellationToUpdate(oldMap, newMap);
        
    }
  

     /**
     * Prevent the contact status to get updated to 'Cancellation' if there is active orders  
     * some defined fields
     *
     * @param oldMap
     * @param newMap
     */
    private static void preventStatusCancellationToUpdate(Map<Id, Contact> oldMap, Map<Id, Contact> newMap){
   
     Set<Id> contactsToCheck = new Set<Id>();
       for (Contact newContact : newMap.values()){
           // get old contact
           Contact oldContact = oldMap.get(newContact.id);
           if((newContact.Status_PG51__c != oldContact.Status_PG51__c || newContact.Status_PG54__c != oldContact.Status_PG54__c ) && 
             ((newContact.Status_PG51__c == Constants.CONTACT_KUENDIGUENG_STATUS ||newContact.Status_PG54__c == Constants.CONTACT_KUENDIGUENG_STATUS))){
                contactsToCheck.add(newContact.id);
           }
       }
  
       if(!contactsToCheck.isEmpty()){    
        for(Contact con : [SELECT Id, Status_PG51__c,Status_PG54__c, (SELECT Id,Status__c,Nach_Paragraph__c 
                                                  FROM Orders__r)
                             FROM Contact where Id in :contactsToCheck ]){                             
               for( Order__c order : con.Orders__r){
                 if ((order.Nach_Paragraph__c == '54' && order.Status__c== Constants.ORDER_ACTIVE_STATUS &&  con.Status_PG54__c == Constants.CONTACT_KUENDIGUENG_STATUS)||
                  (order.Nach_Paragraph__c == '51' && order.Status__c== Constants.ORDER_ACTIVE_STATUS && con.Status_PG51__c == Constants.CONTACT_KUENDIGUENG_STATUS))
                       
                       Trigger.newMap.get(con.Id).addError(System.Label.Status_Cancellation_Contact_Error);           
                }
        }
       }

    }
    
}