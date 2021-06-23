/**
 * @CloudMonsters
 * Last Changed 18.05.2021
 * Flow Controller
 *@description :class used by visual flows
 **/
public class FlowController{
    
    /**************** map contact***************************/
    public Map<Id, Contact> contactsMap{
        get{
            if (contactsMap == null){
                System.debug('I have just changed this line to check it ');
             Set<Id> contactIds = new Set<Id>();
                if (UpdatedFollowUpTasks != null){
                    for (Follow_up_Task__c task : UpdatedFollowUpTasks){
                    contactIds.add(task.Contact__c);
                    }
                }
                
              contactsMap = new Map<Id, Contact>([SELECT Id,Status_PG54__c,Status_PG51__c , LastName, Name, Salutation, Salutation_Text_Curabox__c, WorkAroundTemplatesAccountNumber__c, Email
                                                    FROM Contact
                                                    WHERE Email != null AND Id =:contactIds ]);
            }
            return contactsMap;
        }
        set;
    }

    /*Input */
    @AuraEnabled
    public Id contactId;

    /*Output */
    /*Get Contact Record by Id*/
    @AuraEnabled
    public Contact Contact{
        get{
            return contactsMap.get(contactId);
        }
        set;
    }

    /**************** get successfully updated  FollowUpTasks ***************************/
    /*Input */
    @AuraEnabled
    public List<Follow_up_Task__c> followUpTasksToUpdate;
    /*Output */
    @AuraEnabled
    public List<Follow_up_Task__c> UpdatedFollowUpTasks{
        get{
            Set<Id> updatedFollowUpTasksIds = new Set<Id>();
            if (followUpTasksToUpdate != null){
                //get successfully updated records
                Database.saveResult[] srList = Database.update(followUpTasksToUpdate, false);
                for (Database.SaveResult sr : srList){
                    if (sr.isSuccess()){
                        updatedFollowUpTasksIds.add(sr.getId());
                    }
                }
            }
            return [SELECT Id, Contact__c, Subject__c,Status__c
                    FROM Follow_up_Task__c
                    where Id in :updatedFollowUpTasksIds];
        }

        set;
    }
}