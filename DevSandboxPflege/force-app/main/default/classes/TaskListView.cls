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
// 	opportunity Id could be considered as a parameter in future. 
//
//****************************************************************************************************************************
//
// Description:       
//	to view and filter task list for Badumabu team
//
//****************************************************************************************************************************
// test class: TaskListView_test
//****************************************************************************************************************************
// Changes: 
// 09.07.2018	MZ	filter tasks by their record types --> and recordType.name = \'Badumbau\'
// 21.11.2019   AM  dummyTask mit RecordTypeId
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public without sharing class TaskListView {
    
    private static String Badumbau = 'Badumbau';
    
    public string srchOpportunityNumber {get; set;}
    //public string srchSubject {get; set;}
    public string srchPhase {get; set;}
    public string srchSubPhase {get; set;}
    public string srchUser {get; set;}
    
    public String sortDirection{get;set;}
    public String sortExpression{get;set;}
    
    public List<SelectOption> phaseOptionsList {set;}
    public List<SelectOption> subPhaseOptionsList {set;}
    
    public Task dummyTask{get; set;}
    
    public TaskListView(){
    	if(String.isEmpty(sortDirection)) sortDirection = 'ASC';
        if(String.isEmpty(sortExpression)) sortExpression = 'ActivityDate';
        try{
            dummyTask = new Task(RecordTypeId=[SELECT Id FROM RecordType WHERE sObjectType='task' and developername='Badumbau' LIMIT 1].id);
        }
        catch (System.Exception e) {
            dummyTask = new Task();
        }
        
    }
    
    public String sortFullExp {
        get {
            if(sortDirection == null || sortExpression == null) return ' ActivityDate ASC ';
            else return sortExpression  + ' ' + sortDirection;
        }
        set;
    }
    
    public void doSearchTasks() {

        //return null;
    } 
    
    public void taskPhaseChanegd() {
        dummyTask.Task_SubPhase__c = null;
    }
    
    public void SortToggle() {  
        String sortParam = Apexpages.currentPage().getParameters().get('sortToggleParam');
        
        System.debug('#####mansi:::sortToggleParam:::' + sortParam);
        
        if(String.isEmpty(sortParam)){
            sortExpression = 'ActivityDate';
            sortDirection = 'ASC';
        }else{
            if(!String.isEmpty(sortExpression) && sortExpression == sortParam){
                if(sortDirection == 'ASC'){
                    sortDirection = 'DESC';
                }else{
                    sortDirection = 'ASC';
                }
            }else{
                sortExpression = sortParam;
                sortDirection = 'ASC';
            }
        }
    }  
    
    public List<Task> Tasklist {
        set;
        get {
            String opportunityNumberCondition = '', subjectCondition = '', phaseCondition = '', subPhaseCondition = '', dueDateCondition = '', userCondition = '';//, DueDateCondition = '';
            
            if(!String.isEmpty(srchOpportunityNumber)){
                opportunityNumberCondition = ' and what.name like \'%'+ srchOpportunityNumber +'%\' ';
            }
            //if(!String.isEmpty(srchSubject)){
            //    subjectCondition = ' and Subject like \'%'+ srchSubject +'%\' ';
            //}
            if(!String.isEmpty(dummyTask.Task_Phase__c)){
                phaseCondition = ' and Task_Phase__c = \'' + dummyTask.Task_Phase__c +'\' ';
            }
            if(!String.isEmpty(dummyTask.Task_SubPhase__c)){
                subPhaseCondition = ' and Task_SubPhase__c = \'' + dummyTask.Task_SubPhase__c +'\' ';
            }
            if(!String.isEmpty(srchUser)){
                userCondition = ' and Owner.Name like \'%'+ srchUser +'%\' ';
            }
            /*if(!String.isEmpty(srchUser) && srchUser != '--All--'){
                userCondition = ' and Owner.Id = \'' + srchUser +'\' ';
            }*/
            /*if(!String.isEmpty(dummyTask.activityDate) ){
                dueDateCondition = ' and activityDate = :dummyTask.Task_SubPhase__c ';
            }*/
            
            return (list<Task>) Database.query('SELECT id, activityDate, Subject, whoID, whatId, what.type, what.name, Task_Phase__c, Task_SubPhase__c, ownerId, owner.Name FROM Task where isClosed = False and what.type=\'Opportunity\' '+ opportunityNumberCondition + subjectCondition + phaseCondition + subPhaseCondition + userCondition +' and recordType.name = \''+Badumbau+'\' and What.recordType.name = \''+Badumbau+'\' ORDER BY ' + sortFullExp + ' limit 1000 ');

        }
    }

    public List<Task> allTasklist {
        set;
        get {
            return (list<Task>)Database.query('SELECT id, activityDate, Subject, whoID, whatId, what.type, what.name, Task_Phase__c, Task_SubPhase__c, ownerId, owner.Name FROM Task where isClosed = False and what.type=\'Opportunity\' and recordType.name = \''+Badumbau+'\' and What.recordType.name = \''+Badumbau+'\' ORDER BY ' + sortFullExp + ' limit 1000 ');
        }
    }
    
    public List<SelectOption> getUserList(){
        Set<String> optionsSet = new Set<String>();
        List<SelectOption> optionsList = new List<SelectOption>();                
        optionsList.add(new SelectOption('--All--',  Label.All)); 
        if(allTasklist != null && allTasklist.size() > 0) {
            for(Task t : allTasklist){ 
                if(!optionsSet.contains(t.ownerId) && !String.isEmpty(t.owner.Name)) {
                    optionsList.add(new SelectOption(t.ownerId, t.owner.Name));
                }
                optionsSet.add(t.ownerId);
            }       
        }
        optionsList.sort();
        return optionsList;
    }

    public List<SelectOption> getPhaseOptionsList() {     
        Schema.DescribeFieldResult describeResult = case.Status.getDescribe();
        List<Schema.PicklistEntry> entries = describeResult.getPicklistValues();
        Map<String, String> optLabelsMap = new Map<String, String>();

        for (Schema.PicklistEntry pEntry : entries) {
            if (pEntry.isActive()) {
                optLabelsMap.put(pEntry.getValue(), pEntry.getLabel());
            }
        }
        
        Set<String> optionsSet = new Set<String>();
        List<SelectOption> optionsList = new List<SelectOption>();                
        optionsList.add(new SelectOption('--All--',  Label.All));   
        
        if(allTasklist != null && allTasklist.size() > 0) {
            for(Task t : allTasklist){                    
                if(!optionsSet.contains(t.Task_Phase__c) && !String.isEmpty(t.Task_Phase__c)) {
                    try {
                        optionsList.add(new SelectOption(t.Task_Phase__c, optLabelsMap.get(t.Task_Phase__c)));
                    }
                    catch(System.Exception e) {
                        optionsList.add(new SelectOption(t.Task_Phase__c, t.Task_Phase__c));
                    }
                }
                optionsSet.add(t.Task_Phase__c);
            }       
        }
        
        //optionsList.sort();
                               
        return optionsList;       
    }    

    public List<SelectOption> getSubPhaseOptionsList() {     
        Schema.DescribeFieldResult describeResult = case.Status.getDescribe();
        List<Schema.PicklistEntry> entries = describeResult.getPicklistValues();
        Map<String, String> optLabelsMap = new Map<String, String>();

        for (Schema.PicklistEntry pEntry : entries) {
            if (pEntry.isActive()) {
                optLabelsMap.put(pEntry.getValue(), pEntry.getLabel());
            }
        }
        
        Set<String> optionsSet = new Set<String>();
        List<SelectOption> optionsList = new List<SelectOption>();                
        optionsList.add(new SelectOption('--All--',  Label.All));   
        
        if(allTasklist != null && allTasklist.size() > 0) {
            for(Task t : allTasklist){                    
                if(!optionsSet.contains(t.Task_SubPhase__c) && !String.isEmpty(t.Task_SubPhase__c)) {
                    try {
                        optionsList.add(new SelectOption(t.Task_SubPhase__c, optLabelsMap.get(t.Task_SubPhase__c)));
                    }
                    catch(System.Exception e) {
                        optionsList.add(new SelectOption(t.Task_SubPhase__c, t.Task_SubPhase__c));
                    }
                }
                optionsSet.add(t.Task_SubPhase__c);
            }       
        }
        
        //optionsList.sort();
                               
        return optionsList;       
    }   
}