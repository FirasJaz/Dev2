/**
 * This class contains all functions we can use inside
 * the ContactStatus trigger
 * 
 */
public  class ContactStatusTriggerHandler {


  /**
      * Function, which includes all the code,
      * we execute on the after update event
      *
      * @param oldMap Map with the old values of the event -> Trigger.oldMap context variable
      * @param newMap Map with the new values of the event -> Trigger.newMap context variable
      *
     */
    public static void handleBeforeUpdate(Map<Id, Contact_status__c> oldMap, Map<Id, Contact_status__c> newMap)
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
    private static void preventStatusCancellationToUpdate(Map<Id, Contact_status__c> oldMap, Map<Id, Contact_status__c> newMap){

 
        Set<Id> contactIdPG54Set = new Set<Id>();
        Set<Id> contactIdPG51Set = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        for (Contact_status__c newContactStatus : newMap.values()){
            // get old contact
            Contact_status__c oldContactStatus = oldMap.get(newContactStatus.id);
            if((newContactStatus.Status__c != oldContactStatus.Status__c) && (newContactStatus.Status__c == Constants.CONTACT_KUENDIGUENG_STATUS )){
                if(newContactStatus.Productgroup__c =='PG54')
                contactIdPG54Set.add(newContactStatus.contact__c);
               
                if(newContactStatus.Productgroup__c =='PG51')
                contactIdPG51Set.add(newContactStatus.contact__c);

            }
        }
      

         If(contactIdPG54Set.isEmpty() && contactIdPG51Set.isEmpty() )
         return ;
         


        for(Contact con : [SELECT Id, Status_PG51__c,Status_PG54__c, (SELECT Id,Status__c,Nach_Paragraph__c 
                             FROM Orders__r)  FROM Contact where Id in :contactIdPG54Set OR id in :contactIdPG51Set ]){
                                 
                                          
                for( Order__c order : con.Orders__r){       
                    if((order.Nach_Paragraph__c == '54' && order.Status__c == Constants.ORDER_ACTIVE_STATUS&& contactIdPG54Set.contains(con.id))||
                    (Order.Nach_Paragraph__c == '51' && Order.Status__c == Constants.ORDER_ACTIVE_STATUS && contactIdPG51Set.contains(con.id)))                
                      contactIdSet.add(con.id);
                    
                }
        }

        if(!contactIdSet.isEmpty()){
            for (Contact_status__c cs: newMap.values()){
                if(contactIdSet.contains(cs.contact__c))
                 cs.addError(System.Label.Status_Cancellation_Contact_Error);
            }
        }
                   
    }

    
}