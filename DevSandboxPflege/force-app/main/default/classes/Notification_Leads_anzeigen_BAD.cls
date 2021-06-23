/********************************************************************************************************************************************
//  Created 03.04.2018 by MZ
//  Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//  Nordkanalstraße 58
//  20097 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
// Parameter: Opportunity
//
//********************************************************************************************************************************************
//
// Description:    
//    page to show the list of open Badumbau leads
//
//********************************************************************************************************************************************
// Changes:
//********************************************************************************************************************************************
*/
public with sharing class Notification_Leads_anzeigen_BAD {

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
        return (List<Lead>)[SELECT id, Name, COMPANY, Phone, EMAIL, OM_created_at__c, TL_Treppenliftart__c, Preferred_timeframe__c
                                        FROM Lead
                                        WHERE (status = 'Open' and recordtype.name = 'Badumbau' and owner.name = 'IT Support')
                                        ORDER BY OM_created_at__c ASC] ;
        }
    }

}