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
//                      This class represents a controller for the visualforce page ApprovalView
//                      It lists all approvals, which are in a specific status.
//********************************************************************************************************************************************
// Changes:
//          02.07.2019  BT  Query of attribute 'name'
//          18.07.2019  BT  pagination and column sort
//          15.08.2019  BT  translated KV statuses
//          09.12.2019  BT	00002323 - Added fields Antrag_eingegangen_am__c and LastModifiedDate to the query
//          				00002324 - the list of approvals is from now refreshed after current editor of an approval is set.
//          14.01.2020  BT  00002353 - New query condition 'Antrag_beantwortet_am__c = null' when KV status is 'closed' and status is 'Ablehnung'
//          27.01.2020  BT	00002353 - translation for kv status "send"
//     		04.02.2020  BT  00002391 - query limit of 10.000 records
//      					    	 - page message when limit has been reached
//********************************************************************************************************************************************
*/
public with sharing class ApprovalController {
    public string status {get; set;}
    public string kvStatus {get; set;}
    public boolean kvStatusBool {get; set;}
    public Map<string, string> translatedKvStatuses {get; set;}
    public ApexPages.StandardSetController con {get; set;}
    private string sortDirection = 'ASC';
    private string sortExp = 'name';
    public string pageMessage{get;set;}

    public ApprovalController() {
        status = apexpages.currentpage().getparameters().get('status');
        kvStatus = apexpages.currentPage().getparameters().get('kvStatus');    
        if(kvStatus == 'null') {
            kvStatusBool = false;
        }
        else {
            kvStatusBool = true;
        }
        translatedKvStatuses = new Map<string, string>();
        translatedKvStatuses.put('closed', 'Abgeschlossen');
        translatedKvStatuses.put('error', 'Fehler');
        translatedKvStatuses.put('pending', 'Anstehend');
        translatedKvStatuses.put('send', 'Noch nicht gesendet');
        translatedKvStatuses.put('message received', 'Nachricht angekommen');                                           
    }

    public PageReference queryApprovals() {
        string sortFullExp = sortExpression + ' ' + sortDirection + ' nulls last';
        string query;

        if(kvStatus != 'null') {
            query = 'select id, Name, status__c, contact__r.Kranken_Pflegekasse__r.Name, contact__r.Kranken_Pflegekasse__r.KV_per_Fax__c, Genehmigungsnummer__c, genehmigt_ab__c, genehmigt_bis__c,';
            query += ' Nach_Paragraph__c, Contact__r.Name, Antrag_eingegangen_am__c, LastModifiedDate';
            query += ' from Curabox_Genehmigung__c';
            query += ' where status__c =: status';
            query += ' and KV_status__c =: kvStatus';            
        }
        else {
            query = 'select id, Name, status__c, contact__r.Kranken_Pflegekasse__r.Name, contact__r.Kranken_Pflegekasse__r.KV_per_Fax__c, Genehmigungsnummer__c, genehmigt_ab__c, genehmigt_bis__c,';
            query += ' Nach_Paragraph__c, Contact__r.Name, Antrag_eingegangen_am__c, LastModifiedDate';
            query += ' from Curabox_Genehmigung__c';
            query += ' where status__c =: status';                    
        }

        if(kvStatus == 'closed' && status == 'Ablehnung') query += ' and Antrag_beantwortet_am__c = null';
        query += ' and currentEditor__c = null';
        query += ' order by ' + sortFullExp;
        query += ' limit 10000';
        
        con = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        con.setPageSize(20);
        if(con.getResultSize() == 10000){
            pageMessage = '10.000 Datensätze werden angezeigt aber es könnte noch mehr geben';
        }
        else {
            pageMessage = null;
        }
        return null;
    }

    public List<Curabox_Genehmigung__c> approvals {
        get {
            if(con != null) {
                return (List<Curabox_Genehmigung__c>) con.getRecords();
            }
            else {
                return null;
            }
        }
    }

    public void setApprovalCurrentEditor() {
        String approvalId = apexpages.currentpage().getparameters().get('approvalId');        
        Curabox_Genehmigung__c approval = [select currentEditor__c from Curabox_Genehmigung__c where id =: approvalId];
        approval.currentEditor__c = UserInfo.getUserId();
        update approval;
        
        // refresh the list of approvals
        queryApprovals();
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