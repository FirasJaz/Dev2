public with sharing class Notifications_Mails_anzeigen {

    public String message { get; set; }

    public String TS { get; set; }

    public String message_layout { get; set; }
    public integer counter=0;  //keeps track of the offset
    public integer list_size=100; //sets the page size or number of rows
    public integer total_size; //used to show user the total size of the list   
    public Integer noOfRecords{get; set;}
    public Integer size{get;set;}
    
    

 
    
    public List<task> tslist {
        set;
        get {
        return (List<task>)[SELECT id, subject, CC__c, Reason_of_email__c, status, whoID, Who.Name, ActivityDate, Email__c, priority
                                        FROM task
                                        WHERE (status = 'Ungelesen' OR status ='Wird bearbeitet') and (recordtype.name = 'Email') and (priority = 'Normal')
                                        ORDER BY createddate DESC
                                        LIMIT 1000] ;
        }
    }
    
    public List<task> tslist3 {
        set;
        get {
        return (List<task>)[SELECT id, subject, CC__c, Reason_of_email__c, status, whoID, Who.Name, ActivityDate, Email__c, priority
                                        FROM task
                                        WHERE status = 'Ungelesen' and recordtype.name = 'Email' and priority = 'High'
                                        ORDER BY createddate DESC
                                        LIMIT 1000] ;
        }
    }

    public List<task> tslist2 {
        set;
        get {
        return (List<task>)[SELECT id, subject, CC__c, status, whoID, Who.Name, ActivityDate, Email__c
                                        FROM task
                                        WHERE status = 'Gelesen' and recordtype.name = 'Email'
                                        ORDER BY createddate DESC
                                        LIMIT 1000] ;
        }
    }


}