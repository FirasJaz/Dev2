@RestResource(urlMapping='/Multicontroller/*')
// dev :    http://dev2-pflegede.cs129.force.com/services/apexrest/Multicontroller/*

global class MultiController {
 
    
    @HttpPost 
    global static string createNewLead( String created_at,
                                        String Order_ID,
                                        String referrer,
                                        String Partner_ID,
                                        string GCLID,
                                        string UserID,
                                        String wizard_version,
                                       	String wizard_name,
                                        String Topics_multilead,
                                       	String contact_first_name,
                                       	String contact_last_name,
                                       	String contact_phone_number,
                                       	String salutation
                                          ) 
    {
        boolean doppelt = false;
        string ret = 'OK';                                  
        id rtid = null;       
        id ownid = UserInfo.getUserId();        
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name = 'Multilead'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        
        list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
        if((usList != null) && (usList.size() > 0)) {
            ownid = usList[0].id;
        }       
        
        lead l = new lead(Company='Multilead', Status='Open');
        l.OM_Wizard_Version__c = wizard_version;
        l.Topics_multilead__c = Topics_multilead;                                    
        l.RecordTypeId = rtid;  
        l.OwnerID = ownid;
        l.OM_created_at__c = created_at;
        l.OM_Tracking_Order_ID__c = Order_ID;        
        l.GCLID__c = GCLID;
        l.OM_UserId__c = UserID;    
        l.OM_Referrer__c = referrer;
        l.OM_Partner_ID__c = Partner_ID;
        l.Firstname = contact_first_name;
        l.Lastname = contact_last_name;
		l.Phone = contact_phone_number;
        l.Salutation = salutation;



        
        // check dulicate
        // #145581229 set userID
        list<lead> doppList = [SELECT id, OM_UserID__c, isConverted FROM lead WHERE OM_Tracking_Order_ID__c = :l.OM_Tracking_Order_ID__c];
        List<lead> toUpdateLeads = new List<lead>();
        List<Contact> toUpdateContacts = new List<Contact>();
        List<Kunde__c> toUpdateKunde = new List<Kunde__c>();
        if((doppList != null) && (doppList.size() > 0) ){
            doppelt = true;
            if(!String.isEmpty(UserID)){
                for(Lead dl : doppList){
                    if(!dl.isConverted){
                        dl.OM_UserID__c = UserID;
                        toUpdateLeads.add(dl);
                    }
                }
            }
        }
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
        
        
        
        // Ursprungsanfrage2
        List<Campaign> cmplist = [select id, name from Campaign where name =: wizard_name LIMIT 1];        
        if(cmplist != null && cmplist.size() != 0) l.OM_Wizzard_Name2__c = cmplist[0].Id;       
        if(!doppelt) {
            try {
                insert l;
            }
            catch (System.Exception e) {
                system.debug('#########################error ' + e);
            }
        }
        try{
            update toUpdateLeads;
            update toUpdateContacts;
            update toUpdateKunde;
        }
        catch (System.Exception e) {
            system.debug('#########################error ' + e);
        }
        
        return ret;
    }

}