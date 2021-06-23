/********************************************************************************************************************************************
// Created 21.05.2019 by BT
//                      Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                      Nordkanalstraße 58
//                      20097  Hamburg 
//                      Tel.:  0423882986
//                      Fax.:  0423882986
//                      Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Description:    
//                      This class represents a controller for the notification bar. 
//                      It checks if there are new or pending approvals and follow-up tasks. 
//
//********************************************************************************************************************************************
// Changes:
//  28.05.2019  BT      New approval KV statuses: 'pending', 'error', 'closed'
//  09.07.2019  BT      Translated approval KV statuses
//  15.08.2019  BT      Sorting follow-up tasks by subject, new approval status 'message received'
//  14.01.2020  BT		- 00002353 New approval status: 'Ablehnung' 
//  					- 00002353 New query condition 'Antrag_beantwortet_am__c = null' when KV status is 'closed' and status is 'Ablehnung'
//  27.01.2020  BT		- 00002353 search for kv status "send"	
//  04.02.2020  BT		- 00002391 count() query limit of 50.000 records				
//********************************************************************************************************************************************
*/
public with sharing class NotificationController {
    public integer totalNumberOfItems {get;set;}
    public integer totalNumberOfAntragsversandApproval;
    public integer totalNumberOfAblehnungApproval;
    public integer totalNumberOfOpenFu;
    public integer totalNumberOfPendingFu;
    public Map<string, Map<string, integer>> approvals {get; set;}
    public Map<string, string> translatedKvStatuses {get; set;}
    public Map<string, integer> dueOpenFollowUpTasks {get; set;}
    public Map<string, integer> undueOpenFollowUpTasks {get; set;}
    public Map<string, integer> duePendingFollowUpTasks {get; set;}
    public Map<string, integer> unduePendingFollowUpTasks {get; set;} 
    public List<string> followUpTaskSubjectValues {get; set;}
    
    // constructor
    public NotificationController() {
        checkItems();
    }

    // check all approvals and follow-ups with specifics statuses
    public PageReference checkItems() {
        // init variables
        init();

        // check approvals with status 'Antragsversand' and KV status 'send'
        checkAntragsVersandApprovals('send');

        // check approvals with status 'Antragsversand' and KV status 'pending'
        checkAntragsVersandApprovals('pending');

        // check approvals with status 'Antragsversand' and KV status 'error'
        checkAntragsVersandApprovals('error');

        // check approvals with status 'Antragsversand' and KV status 'closed'
        checkAntragsVersandApprovals('closed');

        // check approvals with status 'Antragsversand' and KV status 'message received'
        checkAntragsVersandApprovals('message received');
        
		// check approvals with status 'Ablehnung' and KV status 'send'
        checkAblehnungApprovals('send');

        // check approvals with status 'Ablehnung' and KV status 'pending'
        checkAblehnungApprovals('pending');

        // check approvals with status 'Ablehnung' and KV status 'error'
        checkAblehnungApprovals('error');

        // check approvals with status 'Ablehnung' and KV status 'closed'
        checkAblehnungApprovals('closed');

        // check approvals with status 'Ablehnung' and KV status 'message received'
        checkAblehnungApprovals('message received');        
    
        for(String followUpTaskSubject: followUpTaskSubjectValues) {
            // check due follow-ups with status 'Open' and a specific subject
            checkOpenFollowUps(true, followUpTaskSubject);

            // check undue follow-ups with status 'Open' and a specific subject
            checkOpenFollowUps(false, followUpTaskSubject);

            // check due follow-ups with status 'In Bearbeitung' and a specific subject
            checkPendingFollowUps(true, followUpTaskSubject);

            // check undue follow-ups with status 'In Bearbeitung' and a specific subject
            checkPendingFollowUps(false, followUpTaskSubject);
        }        

        return null;
    }

    // init all variables
    private void init(){
        totalNumberOfItems = 0;
        totalNumberOfAntragsversandApproval = 0;
        totalNumberOfAblehnungApproval = 0;
        totalNumberOfOpenFu = 0;
        totalNumberOfPendingFu = 0;
        approvals = new Map<string, Map<string, integer>>();
        approvals.put('Antragsversand', new Map<string, integer>());    
        approvals.put('Ablehnung', new Map<string, integer>());
        translatedKvStatuses = new Map<string, string>();
        translatedKvStatuses.put('closed', 'Abgeschlossen');
        translatedKvStatuses.put('error', 'Fehler');
        translatedKvStatuses.put('pending', 'Anstehend');
        translatedKvStatuses.put('send', 'Noch nicht gesendet');
        translatedKvStatuses.put('message received', 'Nachricht angekommen');       
        followUpTaskSubjectValues = getFollowUpTaskSubjectValues();
        dueOpenFollowUpTasks = new Map<string, integer>();
        undueOpenFollowUpTasks = new Map<string, integer>();
        duePendingFollowUpTasks = new Map<string, integer>();
        unduePendingFollowUpTasks = new Map<string, integer>();
    }

    // check all approvals with status 'Antragsversand' and specific KV status
    private void checkAntragsVersandApprovals(String kvStatus) {
        integer numberOfAntragsversandApproval = getNumberOfAntragsversandApproval(kvStatus);
        approvals.get('Antragsversand').put(kvStatus, numberOfAntragsVersandApproval);
        totalNumberOfItems += numberOfAntragsversandApproval;
        totalNumberOfAntragsversandApproval += numberOfAntragsversandApproval;
    }
    
	// check all approvals with status 'Ablehnung' and specific KV status
    private void checkAblehnungApprovals(String kvStatus) {
        integer numberOfAblehnungApproval = getNumberOfAblehnungApproval(kvStatus);
        approvals.get('Ablehnung').put(kvStatus, numberOfAblehnungApproval);
        totalNumberOfItems += numberOfAblehnungApproval;
        totalNumberOfAblehnungApproval += numberOfAblehnungApproval;
    }    

    // check all (un)due follow-ups with status 'Offen' and a specific subject
    private void checkOpenFollowUps(boolean isDue, string subject){
        integer numberOfOpenFu = getNumberOfOpenFu(isDue, subject);
        if(isDue) {
            dueOpenFollowUpTasks.put(subject, numberOfOpenFu);
        }
        else {
            undueOpenFollowUpTasks.put(subject, numberOfOpenFu);
        }
        totalNumberOfItems += numberOfOpenFu;
        totalNumberOfOpenFu += numberOfOpenFu;
    }

    // check all (un)due follow-ups with status 'In Bearbeitung' and a specific subject
    private void checkPendingFollowUps(boolean isDue, string subject){
        integer numberOfPendingFu = getNumberOfPendingFu(isDue, subject);
        if(isDue) {
            duePendingFollowUpTasks.put(subject, numberOfPendingFu);
        }
        else {
            unduePendingFollowUpTasks.put(subject, numberOfPendingFu);
        }
        totalNumberOfItems += numberOfPendingFu;
        totalNumberOfPendingFu += numberOfPendingFu;
    }

    // get the total number of approvals with status 'Antragsvesand'
    private integer getNumberOfAntragsversandApproval(String kvStatus){
        return [select count() from Curabox_Genehmigung__c 
                where status__c = 'Antragsversand' and KV_status__c =: kvStatus and currentEditor__c = null
                limit 50000];
    }
    
 	// get the total number of approvals with status 'Ablehnung'
    private integer getNumberOfAblehnungApproval(String kvStatus){
        if(kvStatus != 'closed') {
            return [select count() from Curabox_Genehmigung__c 
                    where status__c = 'Ablehnung' and KV_status__c =: kvStatus and currentEditor__c = null
                    limit 50000];
        }
        else {
            return [select count() from Curabox_Genehmigung__c where status__c = 'Ablehnung' 
                    and KV_status__c =: kvStatus 
                    and currentEditor__c = null
                    and Antrag_beantwortet_am__c = null
                    limit 50000];
        }
    }    

    // get the total number of (un)due follow-ups with status 'Offen' and a specific subject
    private integer getNumberOfOpenFu(boolean isDue, string subject) {
        if(isDue) {
            return [select count() from Follow_up_Task__c where status__c = 'Offen' 
                    and subject__c = :subject
                    and Due_Date__c < :System.now() 
                    and currentEditor__c = null
                    limit 50000];
        }
        else {
            return [select count() from Follow_up_Task__c where status__c = 'Offen' 
                    and subject__c = :subject
                    and Due_Date__c >= :System.now() 
                    and currentEditor__c = null
                    limit 50000];
        }        
    }

    // get the total number of (un)due follow-ups with status 'In Bearbeitung' and a specific subject
    private integer getNumberOfPendingFu(boolean isDue, string subject) {
        if(isDue){
            return [select count() from Follow_up_Task__c where status__c = 'In Bearbeitung' 
                    and subject__c = :subject
                    and Due_Date__c < :System.now() 
                    and currentEditor__c = null
                    limit 50000];
        }
        else {
            return [select count() from Follow_up_Task__c where status__c = 'In Bearbeitung' 
                    and subject__c =: subject
                    and Due_Date__c >= :System.now() 
                    and currentEditor__c = null
                    limit 50000];
        }    
    }

    // get all possible values for follow-up task subject
    public List<String> getFollowUpTaskSubjectValues(){
        List<String> taskSubjects = new List<String>();

        try {
            for(Task__c task: [select Subject__c, Visible_in_notification_center__c
                               from Task__c
                               where Visible_in_notification_center__c = true]) {
                taskSubjects.add(task.Subject__c);
            }
        }
        catch(System.Exception e) {
            Schema.DescribeFieldResult fieldResult = Follow_up_Task__c.Subject__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                taskSubjects.add(pickListVal.getLabel());
            }  
        }
   
		return taskSubjects;
    }
}