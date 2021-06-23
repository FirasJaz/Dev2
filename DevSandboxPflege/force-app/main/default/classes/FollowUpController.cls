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
//                      This class represents a controller for the visualforce page FollowUpView
//                      It lists all Follow-up tasks, which are in a specific status.
//********************************************************************************************************************************************
// Changes:
//      18.07.2019  BT  pagination and column sort
//      15.08.2019  BT  follow-up task subject as new search criterion
//                      00002324 - the list of follow-up tasks is from now refreshed after current editor of a follow-up task is set.
//      04.02.2020  BT  00002391 - query limit of 10.000 records
//                               - page message when limit has been reached
//      05.10.2020  DZ   Added new column "Last_modified__c"
//********************************************************************************************************************************************
*/
public with sharing class FollowUpController {
    public string status {get; set;}
    public string isDue {get; set;}
    public boolean isDueBool {get; set;}
    public boolean all {get; set;}
    public string subject {get; set;}    
    public ApexPages.StandardSetController con {get; set;}
    private string sortDirection = 'ASC';
    private string sortExp = 'name';
    public string pageMessage{get;set;}

    public FollowUpController() {
        status = apexpages.currentpage().getparameters().get('status');
        isDue = apexpages.currentPage().getParameters().get('isDue');
        subject = apexpages.currentPage().getParameters().get('subject');
        
        try {
            isDueBool = Boolean.valueOf(isDue);
        }
        catch(System.exception e) {}

        if(status == 'null') all = true;
    }

    public Pagereference queryFollowUpTasks() {  
        // String formatedDt = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String formatedDt = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'GMT');
        system.debug('############alex6000 ' + formatedDt);
        string sortFullExp = sortExpression + ' ' + sortDirection + ' nulls last';
        string query;

        if(isDue == 'true') {
            query = 'select id, status__c, Name, Contact__r.Pflegedienst__r.Name, Due_Date__c, Subject__c, Contact__r.Name, Last_Modified__c';
            query += ' from Follow_up_Task__c';
            query += ' where status__c =: status';
            query += ' and subject__c =: subject';
            query += ' and Due_Date__c <' + formatedDt;
            query += ' and currentEditor__c = null';
            query += ' order by ' + sortFullExp;
        }
        else if(isDue == 'false') {
            query = 'select id, status__c, Name, Contact__r.Pflegedienst__r.Name, Due_Date__c, Subject__c, Contact__r.Name, Last_Modified__c';
            query += ' from Follow_up_Task__c';
            query += ' where status__c =: status';
            query += ' and subject__c =: subject';
            query += ' and Due_Date__c >=' + formatedDt;
            query += ' and currentEditor__c = null';
            query += ' order by ' + sortFullExp;
        }
        else if(isDue == 'null' && status != 'null'){
            query = 'select id, status__c, Name, Contact__r.Pflegedienst__r.Name, Due_Date__c, Subject__c, Contact__r.Name, Last_Modified__c';
            query += ' from Follow_up_Task__c';
            query += ' where status__c =: status';
            query += ' and subject__c =: subject';
            query += ' and currentEditor__c = null';
            query += ' order by ' + sortFullExp;
        } 
        else if(isDue == 'null' && status == 'null') {
            query = 'select id, status__c, Name, Contact__r.Pflegedienst__r.Name, Due_Date__c, Subject__c, Contact__r.Name, Last_Modified__c';
            query += ' from Follow_up_Task__c';
            query += ' where subject__c =: subject';
            query += ' and status__c in (\'Offen\', \'In Bearbeitung\')';
            query += ' and currentEditor__c = null';
            query += ' order by ' + sortFullExp;
        }
        query += ' limit 10000';

        con = new ApexPages.StandardSetController(Database.getQueryLocator(query));        
        con.setPageSize(20);
        if(con.getResultSize() == 10000) {
            pageMessage = '10.000 Datensätze werden angezeigt aber es könnte noch mehr geben';
        }
        else{
            pageMessage = null;
        }
        return null;
    }

    public List<Follow_up_Task__c> followUpTasks {
        get {
            if(con != null) {
                return (List<Follow_up_Task__c>) con.getRecords();
            }
            else {
                return null;
            }
        }
    }

    public void setFollowUpCurrentEditor() {
        String followUpId = apexpages.currentpage().getparameters().get('followUpId');        
        Follow_up_Task__c followUp = [select currentEditor__c, status__c from Follow_up_Task__c where id =: followUpId];
        followUp.currentEditor__c = UserInfo.getUserId();
        if(followUp.status__c == 'Offen') {
            followUp.status__c = 'In Bearbeitung';
        }
        update followUp;
        
        // refresh list of follow-up tasks
        queryFollowUpTasks();
    }

   public Boolean hasNext {
        get 
        {
            return con.getHasNext();
        }
        set;
    }

    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }     
        set;   
    }

    public integer pageNumber {
        get {
            return con.getPageNumber();            
        }
        set;
    }

    public void previous() {
        con.previous();
    }

    public void next() {
        con.next();
    }

    public string sortExpression {
        get{
            return sortExp;
        }
        set {
            if(value == sortExp) {
                sortDirection = (sortDirection == 'ASC') ? 'DESC' : 'ASC';
            }
            else {
                sortDirection = 'ASC';
                sortExp = value;
            }
        }
    }

    public string getSortDirection () {
        if(sortExpression == null || sortExpression == '') {
            return 'ASC';
        }
        else {
            return sortDirection;
        }
    }

    public void setSortDirection (string value) {
        sortDirection = value;
    }
}