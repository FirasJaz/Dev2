/****************************************************************************************************************************
// Created 04.06.2018 von  MZ
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
// 	opportunity Id
//
//****************************************************************************************************************************
//
// Description:       
//	to create a new Bad-umbau task
//
//****************************************************************************************************************************
// test class: TaskNewBadumbau_test
//****************************************************************************************************************************
// Changes: 
// 27.06.2018     MZ     Assigned-To added as a field. default value is IT-Support 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class TaskNewBadumbau {
    public static String TaskCreatedSuccessfully = 'Aufgabe wird erfolgreich erstellt!';
    public String opportunityId {get; set;}
    Public Task formTask {get; set;}
    
    Public String taskSubject {get; set;}
    
    public TaskNewBadumbau(ApexPages.StandardController controller) {
        opportunityId = ((Opportunity)controller.getRecord()).id;
        initializeTask();
    }
    
    private void initializeTask(){
        taskSubject = '';
        formTask = new Task();
        formTask.Priority = 'Normal';
        formTask.Status = 'Open';
        formTask.WhatId = opportunityId;
        formTask.ActivityDate = Date.today().addDays(1);
        
        List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
        if(user_list != null && user_list.size()>0){
            formTask.ownerID = user_list[0].id;
        }
        
        List<RecordType> rtList = [select id, name, SObjectType from RecordType where SObjectType = 'Task' and developerName = 'Badumbau' limit 1];
    	if(rtList != null && rtList.size()>0){
        	formTask.recordTypeId = rtList[0].Id;
    	}
    }
     
    public void saveTask(){
        try{
            if(formTask != null){
                formTask.Subject = taskSubject;
                if(String.isEmpty(taskSubject)){
                    formTask.Subject = formTask.Task_Phase__c + ' - ';
                    if(!String.isEmpty(formTask.Task_SubPhase__c)){
                        formTask.Subject = formTask.Subject + formTask.Task_SubPhase__c;
                    }
                }
                insert formTask;
            }
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, TaskCreatedSuccessfully ));
            initializeTask();
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));
        }
    }
    
    public void phaseChanged(){
        taskSubject = '';
        if(formTask.Task_Phase__c != null){
            taskSubject += formTask.Task_Phase__c;
        }
    }
    
    public void subPhaseChanged(){
        taskSubject = '';
        if(formTask.Task_Phase__c != null){
            taskSubject += formTask.Task_Phase__c;
            if(formTask.Task_SubPhase__c != null){
                taskSubject += ' - ' + formTask.Task_SubPhase__c;
            }
        }
        
    }
    
    
    
}