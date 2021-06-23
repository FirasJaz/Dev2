/****************************************************************************************************************************
// Created  05.03.2018 von MZ
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
// HTTP request JSON
//
//****************************************************************************************************************************
//
// Description:
//    #155031314
//        WDS Leads conversion to contact and opportunity                      
//
//****************************************************************************************************************************
// Changes:
// 23.10.2018   MZ  #161257706 wizard version added
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@RestResource(urlMapping='/Pflegeschulungen/*')
// dev:     https://dev-pflegede.cs84.force.com/services/apexrest/Pflegeschulungen
// fs:     https://fs-pflegede.cs84.force.com/services/apexrest/Pflegeschulungen

global class ksgPflegeschulungenController {
    
    @HttpPost 
    global static string createNewLead( String created_at,
                                        String Order_ID,
                                        String wizard_name,
                                        String referrer,
                                        String GCLID,
                                        String UserID,                             
                                        contact_wds contact_wds,
                                        String Partner_ID,
                                        String wizard_version) {
        boolean doppelt_OrderId = false;
        string ret = 'OK';                                  
        id rtid = null;       
        id ownid = UserInfo.getUserId();  
        try {      
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name = 'Pflegeschulungen' limit 1];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        else {
            return 'Error: RecordType Pflegeschulungen not found for sObjectType lead'; 
        }
        list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
        if((usList != null) && (usList.size() > 0)) {
            ownid = usList[0].id;
        }       
        
        lead l = new lead(Company='Pflegeschulungen', Status='Open');
        l.RecordTypeId = rtid;  
        l.OwnerID = ownid;
        l.OM_created_at__c = created_at;
        l.OM_Tracking_Order_ID__c = Order_ID;
        l.OM_Wizard_Version__c = wizard_version;
        l.OM_Referrer__c = referrer;
        l.GCLID__c = GCLID;    
        l.OM_UserId__c = UserID;
        l.OM_Partner_ID__c = Partner_ID;
        l.TL_Treppenliftart__c = 'Pflegeschulungen';
        
        if(contact_wds != null) {
            try { 
                l.Email = contact_wds.contact_mail_from;
                l.Firstname = contact_wds.contact_first_name;
                l.Lastname = contact_wds.contact_last_name;
                l.Phone = contact_wds.contact_phone_number;
                l.Salutation = contact_wds.contact_salutation;
            }
            catch (System.Exception e) {
                ret = 'Error: ' + e.getMessage();
            }
        }       
        
        // check dulicate of Tracking Order Id
        List<lead> toUpdateLeads = new List<lead>();
        List<Contact> toUpdateContacts = new List<Contact>();
        List<Kunde__c> toUpdateKunde = new List<Kunde__c>();
        list<lead> doppList_OrderId = [SELECT id, isConverted FROM lead WHERE OM_Tracking_Order_ID__c = :l.OM_Tracking_Order_ID__c];
        if((doppList_OrderId != null) && (doppList_OrderId.size() > 0) ){
            doppelt_OrderId = true;
            if(!String.isEmpty(UserID)){
                for(Lead dl : doppList_OrderId){
                    if(!dl.isConverted){
                        dl.OM_UserID__c = UserID;
                        toUpdateLeads.add(dl);
                    }
                }
            }
        }
        
        // Ursprungsanfrage2
        List<Campaign> cmplist = [select id, name from Campaign where name =: wizard_name LIMIT 1];        
        if(cmplist != null && cmplist.size() != 0) {
            l.OM_Wizzard_Name2__c = cmplist[0].Id;      
        }
        else return 'Error: Campaign ' + wizard_name + ' not found.';  
       
        if(! doppelt_OrderId) {
            // create lead
            try {
                insert l;
                ret = Lead_to_Opportunity_Pflegeschulungen.convertLeadToOpportunity(l);
            }
            catch (Exception e) {
                ret = 'Error: ' + e.getMessage(); 
                system.debug('#########################error ' + e);
            }
        }
        
        
        // #145581229 set userID
        if(!String.isEmpty(UserID)){
            Set<Id> contactIds = new Set<Id>();
            Set<Id> kundeIds = new Set<Id>();
            String keyword = '%'+ Order_ID + '%';
            List<OpportunityContactRole> opcr_list = [select ContactId, opportunity.OM_Tracking_Order_ID__c from OpportunityContactRole where opportunity.OM_Tracking_Order_ID__c like: keyword ];
            for(OpportunityContactRole r : opcr_list){
                contactIds.add(r.ContactId);
            }
            toUpdateContacts = [select Id, OM_USERID__c, Passender_CB_Kunde__c from Contact where id in :contactIds];
            for(Contact c : toUpdateContacts){
                c.OM_UserId__c = UserID;
                if(!String.isEmpty(c.Passender_CB_Kunde__c)){
                    kundeIds.add(c.Passender_CB_Kunde__c);
                }
            }
            toUpdateKunde = [select id, OM_USERID__c from Kunde__c where id in :kundeIds ];
            for(Kunde__c k : toUpdateKunde){
                k.OM_UserId__c = UserID;
            }
        }
        
        try{
            update toUpdateLeads;
            update toUpdateContacts;
            update toUpdateKunde;
        }
        catch (System.Exception e) {
            system.debug('#########################error ' + e);
            ret = 'Error: update failed: ' + e.getMessage();
        }
        return ret;
        }
        catch (Exception e) {
            return 'Error: ksgPflegeschulungenController' + e.getMessage(); 
        }
    }

    global class contact_wds {
        global String contact_mail_from {get;set;} 
        global String contact_first_name {get;set;} 
        global String contact_last_name {get;set;} 
        global String contact_phone_number {get;set;} 
        global String contact_salutation {get;set;}
    }   

}