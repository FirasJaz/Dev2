/****************************************************************************************************************************
// Erstellt 14.07.2017 von AM
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
// Beschreibung:
//                      
// controller für Pflegeimmobilien landingpage
// dev : https://dev-pflegede.cs84.force.com/services/apexrest/pflegeimmobilien
//
//****************************************************************************************************************************
// Änderungen
// 23.10.2018   MZ  #161257706 wizard version added
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

@RestResource(urlMapping='/pflegeimmobilien/*')
global class ksgPflegeimmobilienController {
        @HttpPost 
    global static string createNewLead( string created_at,
                                        string Order_ID,
                                        string wizard_name,
                                        string location_direction,
                                        string own_use,
                                        string financing_model,
                                        string referrer,
                                        contact_immo contact_immo,
                                        string Partner_ID,
                                        string GCLID,
                                        string UserID,
                                        string Preferred_timeframe,
                                        String wizard_version) {
        
        boolean doppelt = false;
        id rtid = null;    
        id ownid = UserInfo.getUserId(); 
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name= 'Pflegeimmobilien'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        } 
        else {
            return 'Error! Lead Record type Pflegeimmobilien not found.';
        }

        list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
        if((usList != null) && (usList.size() > 0)) {
            ownid = usList[0].id;
        }       
        
        lead l = new lead(Company='Pflegeimmobilien', Status='Open');   
        l.RecordTypeId = rtid;  
        l.GCLID__c = GCLID;
        l.OM_created_at__c = created_at;        
        l.OM_Partner_ID__c = Partner_ID;
        l.OwnerID = ownid;
        l.OM_Referrer__c = referrer;
        l.OM_Tracking_Order_ID__c = Order_ID;
        l.OM_Wizard_Version__c = wizard_version;
        l.OM_UserId__c = UserID;
        
        l.financing_model__c = financing_model;
        l.own_use__c = own_use;
        l.location_direction__c = location_direction;
        
        // #154212180
        if(!String.isEmpty(Preferred_timeframe)){
            if(Preferred_timeframe.containsignoreCase('nachmittag') || Preferred_timeframe.containsignoreCase('18')){
                l.Preferred_timeframe__c = Nachtelefonie_einrichten.Preferred_timeframe_Nachmittags;
            }
            else if(Preferred_timeframe.containsignoreCase('vormittag') || Preferred_timeframe.containsignoreCase('8')){
                l.Preferred_timeframe__c = Nachtelefonie_einrichten.Preferred_timeframe_Vormittags;
            }
            else{
                l.Preferred_timeframe__c = Nachtelefonie_einrichten.Preferred_timeframe_Mittags;
            }
        }
        
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
        
        List<Campaign> cmplist = [select id, name from Campaign where name =: wizard_name LIMIT 1];        
        if(cmplist != null && cmplist.size() != 0) {
            l.OM_Wizzard_Name2__c = cmplist[0].Id;      
        }
        else {
            return 'Error! Campaign ' + wizard_name + ' not found';
        }
        if(contact_immo != null) {
            try { 
                l.Email = contact_immo.contact_mail_from;
                l.Firstname = contact_immo.contact_first_name;
                l.Lastname = contact_immo.contact_last_name;
                l.Phone = contact_immo.contact_phone_number;
                l.Salutation = contact_immo.contact_salutation;
            }
            catch (System.Exception e) {
                return 'Error! wrong contact info. e=' + e.getMessage();
            }
        }
        else {
            return 'Error! empty contact info';
        }
        
        if(!doppelt) {
            try {
                insert l;
            }
            catch (System.Exception e) {
                system.debug('#########################error ' + e);
                return 'Error: Lead insert error e=' + e.getMessage();
            }
        }
        try{
            update toUpdateLeads;
            update toUpdateContacts;
            update toUpdateKunde;
        }
        catch (System.Exception e) {
            system.debug('#########################error ' + e);
            return 'Error: update error e=' + e.getMessage();
        }
        
        return 'OK';        
    }
    
    global class contact_immo {
        global String contact_mail_from {get;set;} 
        global String contact_first_name {get;set;} 
        global String contact_last_name {get;set;} 
        global String contact_phone_number {get;set;} 
        global String contact_salutation {get;set;} 
    }  
    
}