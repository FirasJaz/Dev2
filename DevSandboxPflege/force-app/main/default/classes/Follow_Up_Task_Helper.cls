/****************************************************************************************************************************
// Created 02.06.2019 von  AD
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
//
//****************************************************************************************************************************
//
// Description:       
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Follow_Up_Task_Helper {
   
    public static Follow_up_Task__c createNewFollowUpTask(String contactId, String subject, String action, Date dueDate, String status){
        Follow_up_Task__c task = new Follow_up_Task__c();
        task.Status__c = status;
        task.Action__c = action;
        task.Contact__c = contactId;
        task.Opportunity__c = Curabox_Helper.getOpportunityStage(contactId).Id;
        task.Subject__c = subject;
        //task.Description__c = description;
        task.Due_Date__c = Datetime.newInstance(dueDate.year(), dueDate.month(), dueDate.day(), 12, 00, 00);

        return task;
    }

    public static void insertFollowUpTask(Id contactId, String subject, String description, Date dueDate, String status){
        Follow_up_Task__c task = createNewFollowUpTask(contactId, subject, description, dueDate, status);
        try {
            insert task;
        } catch (Exception e) {
            System.debug('Fehler beim Anlegen des Follow-up Tasks');
        }
    }

    public static void updateFollowUpTask(String contactId, String action, String status){
        Follow_up_Task__c task = getFollowUpTask(contactId, action);
        task.Status__c = status;
        try {
           update task;
        } catch (Exception e) {
            System.debug('Fehler beim Update des Follow-Up Tasks!');
        }
    }

    public static Follow_up_Task__c getFollowUpTask(String contactId, String action){
        Follow_up_Task__c task = new Follow_up_Task__c();
        try {
            task = [SELECT Id FROM Follow_up_Task__c WHERE Contact__c =: contactId AND Action__c =: action AND (Status__c = 'Offen' OR Status__c = 'In Bearbeitung') ORDER BY createdDate Desc LIMIT 1];
        } catch (Exception e) {
            System.debug('Kein Follow-Up Task gefunden!');
        }
        return task;
    }

    public static Date getDueDate(Decimal setting){
        Date today = System.today();
        Date dueDate = today.addDays(Integer.valueOf(setting));
        return dueDate;
    }


}