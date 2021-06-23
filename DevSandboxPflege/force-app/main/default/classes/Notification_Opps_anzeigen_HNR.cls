public with sharing class Notification_Opps_anzeigen_HNR {

    public String message { get; set; }

    //public String Opp { get; set; }

    public String message_layout { get; set; }
    public integer counter=0;  //keeps track of the offset
    public integer list_size=100; //sets the page size or number of rows
    public integer total_size; //used to show user the total size of the list   
    public Integer noOfRecords{get; set;}
    public Integer size{get;set;}
    
 
    
    public List<Opportunity> Opplist {
        set;
        get {
        return (List< Opportunity>)[SELECT Id, Name,recordtype.name, Produkt_Kategorie__c, createdDate, lastModifiedDate 
                                        FROM opportunity 
                                        WHERE (owner.name = 'IT Support' and recordtype.name =  'Notrufsysteme' and stageName= 'Offen' and Prio__c = true)
                                        ORDER BY createdDate ASC] ;
        }
    }

}