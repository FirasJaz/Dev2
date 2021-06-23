public with sharing class Notification_Leads_anzeigen_Multilead {

    public String message { get; set; }

    public String LD { get; set; }

    public String message_layout { get; set; }
    public integer counter=0;  //keeps track of the offset
    public integer list_size=100; //sets the page size or number of rows
    public integer total_size; //used to show user the total size of the list   
    public Integer noOfRecords{get; set;}
    public Integer size{get;set;}
    
 
    
    public List<Lead> LDlist {
        set;
        get {
        return (List<Lead>)[SELECT id, Name, COMPANY, Phone, EMAIL, OM_created_at__c, topics_multilead__c, Preferred_timeframe__c
                                        FROM Lead
                                        WHERE (status = 'Open' and recordtype.name = 'Multilead' and owner.name = 'IT Support')
                                        ORDER BY OM_created_at__c ASC] ;
        }
    }

}