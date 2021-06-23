/****************************************************************************************************************************
//  Created     05.03.2018 von MZ
//  Klose und Srocke Gesellschaft fÃ¼r kreative KonfliktlÃ¶sungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Lead 
//
//****************************************************************************************************************************
//
// Description:
//     Converting Pflegeschulungen-lead to opportunity.         
//
//****************************************************************************************************************************
// Changes:
// 23.10.2018   MZ  #161257706 wizard version added
//****************************************************************************************************************************
*/
global class Lead_to_Opportunity_Pflegeschulungen{
    private static String rt_Familienangehoerige = 'Familienangehörige';
    private static String rt_Standard = 'Standard';
    private static String rt_Familien = 'Pflege.de - Familien';


    global Lead_to_Opportunity_Pflegeschulungen(){
    }
    
    public static String convertLeadToOpportunity(Lead l){
        try{
            Id userId;
            list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
            if((usList != null) && (usList.size() > 0)) {
                userId = usList[0].id;
            }
            
            Contact con = getContact(l);
            Account acc;
            List<Opportunity> oppList;
            if(con.accountId == null){
                acc = getAccount(l);
                oppList = getOpportunity(l.Id, acc.Id);
            }else{
                oppList = getOpportunity(l.Id, con.accountId);
            }
            
            if(con.accountId == null){
                if(acc != null){
                    if(acc.Id == null){
                        if(userId != null) acc.OwnerId = userId;
                        insert acc;
                    }else{
                        update acc;
                    }
                    con.accountId = acc.Id;
                }
            }
            
            con.OM_UserID__c = l.OM_UserID__c;
            if(con.Id == null){
                if(userId != null) con.OwnerId = userId;
                con.Marketing_Cloud_ID__c = l.Id;
                insert con;
            }else{
                if(String.isEmpty(con.Email)){
                    con.Email = l.Email;
                }
                update con;
            }
            
            Opportunity opp;
            List<Opportunity> oppList_toUpdate = new List<Opportunity>();
            for(Opportunity o: oppList){
                if(o.Id == null){
                    opp = o;
                }else{
                    oppList_toUpdate.add(o);
                }
            }
            if(oppList_toUpdate != null && !oppList_toUpdate.isEmpty()){
                update oppList_toUpdate;
                
                //l.status = 'Ausschuss';
                l.Lead_Status_Bemerkung__c = 'Dopplung';
                update l;
                
            }
            if(opp != null){
                opp.AccountId = con.accountId;                
                
                if(userId != null) opp.OwnerId = userId;
                
                insert opp;
                
                OpportunityContactRole ocr = new OpportunityContactRole( ContactId = con.Id,
                                                                         OpportunityId = opp.Id,
                                                                         IsPrimary = true,
                                                                          Role = 'ASP');
                if(l.Person_des_Bedarfs__c != null && l.Person_des_Bedarfs__c == 'Für mich'){
                    ocr.Role = 'PB = ASP';
                }
                insert ocr;
                
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(l.id);
                lc.setDoNotCreateOpportunity(true);
                lc.setAccountId(con.accountId);
                lc.setContactId(con.Id);
                System.debug('mansi:::con.accountId:::'+ con.accountId);
                System.debug('mansi:::con.Id:::'+ con.Id);

                if(oppList_toUpdate != null && !oppList_toUpdate.isEmpty()){
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Ausschuss' LIMIT 1];
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                }else{
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Qualified' LIMIT 1];
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                }

                Database.LeadConvertResult lcr = Database.convertLead(lc);
                
            }
            
        }
        catch (Exception e){
            return 'Error: ksgPflegeschulungenController' + e.getMessage();
        }
        
        return 'OK';
    }
    
    private static Contact getContact(Lead l){
        Contact c;
        map<String, Id> rtMap = new map<String, Id>();
        list<RecordType> rtList = [SELECT Id, Name, sObjectType FROM RecordType WHERE Name IN ( :rt_Familienangehoerige, :rt_Standard) and sObjectType = 'Contact'];     
        for(RecordType rt : rtList){
            rtMap.put(rt.Name, rt.Id);
        }
        if(!rtList.isEmpty()){
            List<Contact> contactList = [select id, 
                                                Name, 
                                                firstname, 
                                                lastname, 
                                                Email, 
                                                Phone, 
                                                RecordTypeId, 
                                                MobilePhone, 
                                                CreatedById, 
                                                AccountId, 
                                                Art_des_Kontakts__c,
                                                Familien_Zugeh_rigkeit__c, 
                                                von__c, 
                                                MailingStreet, 
                                                MailingCity, 
                                                MailingPostalCode
                                       from  Contact 
                                       where (Email = null or Email =: l.Email) and   
                                             firstname != null and
                                             firstname =: l.firstname and
                                             lastname != null and
                                             lastname =: l.lastname and   
                                             RecordTypeId in :rtMap.values()];
            if(contactList!= null){
                Integer listSize = contactList.size();
                if(listSize == 0){
                    c = null;
                }else if(listSize == 1){
                    c = contactList[0];
                }else{ // more than one contact is found
                    Integer i = 0;
                    while (i < contactList.size()){
                      if(contactList.size()>1 && contactList[i].AccountId == null){
                          contactList.remove(i);
                      }else{
                          i++;
                      }
                    }
                    i = 0;
                    while (i < contactList.size()){
                      if(contactList.size()>1 && contactList[i].RecordTypeId != rtMap.get(rt_Familienangehoerige)){
                          contactList.remove(i);
                      }else{
                          i++;
                      }
                    }
                    c = contactList[0];
                }
            }
        
            if(c == null){
                c = new Contact(Salutation = l.Salutation,
                                firstname = l.firstname,
                                lastname = l.lastname,
                                Email = l.Email,
                                MailingCity = l.City,
                                MailingPostalCode = l.PostalCode,
                                MailingStreet = l.Street,
                                RecordTypeId = rtMap.get(rt_Familienangehoerige));
                if(l.pflegegrad__c != null) c.Pflegegrad__c = l.pflegegrad__c; 
                if(l.Pflegestufe__c != null) c.Pflegestufe__c = l.Pflegestufe__c;   
            }else{
                c.RecordTypeId = rtMap.get(rt_Familienangehoerige);
                if(String.isEmpty(c.Email)) c.Email = l.Email;
                if(String.isEmpty(c.MailingStreet) && !String.isEmpty(l.Street)) c.Email = l.Street;
                if(String.isEmpty(c.MailingCity) && !String.isEmpty(l.City)) c.MailingCity = l.City;
                if(String.isEmpty(c.MailingPostalCode) && !String.isEmpty(l.postalcode)) c.MailingPostalCode = l.Email;
                if(c.Pflegegrad__c == null && l.pflegegrad__c != null) c.Pflegegrad__c = l.pflegegrad__c; 
                if(c.Pflegestufe__c == null && l.Pflegestufe__c != null) c.Pflegestufe__c = l.Pflegestufe__c;
            }
        }
        
        return c;
    }
    
    private static Account getAccount(Lead l){
        Account a;
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE Name =: rt_Familien and sObjectType = 'Account' limit 1];
        list<RecordType> rtListContact = [SELECT Id, Name, sObjectType FROM RecordType WHERE Name =: rt_Familienangehoerige and sObjectType = 'Contact' limit 1];     
        
        if(!rtList.isEmpty()) {
            if(!rtListContact.isEmpty()) {
                List<Contact> contactsWithSameEmail = [select Id, 
                                                             Email, 
                                                             RecordTypeId, 
                                                             AccountId,
                                                             Account.Familien_Name__c,
                                                             Account.BillingCity
                                                       from  Contact
                                                       where Email != null and 
                                                             Email =: l.Email and
                                                             AccountId != null and 
                                                             Account.Familien_Name__c =: l.lastname and
                                                             RecordTypeId =: rtListContact[0].Id and
                                                             Account.RecordTypeId =: rtList[0].Id ];
                if(!contactsWithSameEmail.isEmpty()){
                    if(contactsWithSameEmail.size() > 1){
                        Integer i = 0;
                        while (i < contactsWithSameEmail.size()){
                          if(contactsWithSameEmail.size()>1 && contactsWithSameEmail[i].Account.BillingCity != l.City){
                              contactsWithSameEmail.remove(i);
                          }else{
                              i++;
                          }
                        }
                    }
                    a = [select Id, Name, Familien_Name__c, BillingCity from Account where Id =: contactsWithSameEmail[0].AccountId limit 1];
                }
            }
            if(a == null){
                a = new Account(Name = l.lastname,
                                Familien_Name__c = l.lastname,
                                BillingCity = l.City,
                                RecordTypeId = rtList[0].Id );
            }
        }
        return a;
    }
    
    
    private static List<Opportunity> getOpportunity(Id leadId, Id accountId){
    
        List<Opportunity> oList = new List<Opportunity>();
        
        try{
            Lead l = [select Id,
                        RecordTypeId,
                        OM_Referrer__c,
                        OM_created_at__c,
                        OM_Tracking_Order_ID__c,
                        OM_Wizard_Version__c,
                        OM_Wizzard_Name2__c,
                        createdDate,
                        OM_UserID__c,
                        OM_Partner_ID__c,
                        Marketing_Cloud_ID__c,
                        GCLID__c,
                        OwnerID
                    from Lead where Id =: leadId limit 1];
                    
            list<RecordType> rtList;
            list<RecordType> rtListLead = [SELECT Id, SobjectType, Name FROM RecordType WHERE Id =: l.RecordTypeId];
            if(!rtListLead.isEmpty()){
                rtList = [SELECT Id, SobjectType, Name FROM RecordType WHERE Name =: rtListLead[0].Name and SobjectType = 'Opportunity'];
                if(!rtList.isEmpty()){
                    Opportunity o = new Opportunity(Name = 'tempName', 
                                                    StageName = 'Erfolg', 
                                                    RecordTypeId = rtList[0].Id); 
                                              
                    o.OM_Referrer__c = l.OM_Referrer__c;
                    o.OM_Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c;
                    o.OM_Wizard_Version__c = l.OM_Wizard_Version__c;
                    o.CloseDate = date.today();
                    o.Date_of_Request__c = l.createdDate;
                    o.Automatically_Converted__c = true;
                    o.OM_Partner_ID__c = l.OM_Partner_ID__c;
                    o.GCLID__c = l.GCLID__c;
                                  
                    o.CampaignId = l.OM_Wizzard_Name2__c;
                    o.Urspr_nglicher_Lead__c = l.Id;   
                    
                    if(rtList[0].Name == 'Pflegeimmobilien' || rtList[0].Name == 'Widerspruch' || rtList[0].Name == 'Pflegeschulungen' ){
                        o.Produkt_Kategorie__c = rtList[0].Name;
                        o.RO_Produkt_Kategorie__c = rtList[0].Name;
                    }                  
                    
                    if(accountId != null){
                        o.AccountId = accountId;
                        List<Opportunity> oppList = [select id, 
                                                        AccountId, 
                                                        Name, 
                                                        Produkt_Kategorie__c, 
                                                        RecordTypeId, 
                                                        StageName, 
                                                        OM_Tracking_Order_ID__c,
                                                        OM_Wizard_Version__c,
                                                        OM_Referenznummer__c
                                                     from Opportunity 
                                                     where AccountId =: accountId and 
                                                         RecordTypeId =: rtList[0].Id];
                        if(!oppList.isEmpty()){
                            o.OM_Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c;
                            o.StageName = 'Abbruch';
                            o.Abbruchgrund__c = 'Auschuss';
                        }
                    }
                    oList.add(o);
                }
            }
        }catch(Exception e){
            System.debug(e.getMessage());
            throw new applicationException (e.getMessage());
        }
        return oList;                     
    }
    
    public class applicationException extends Exception{}


}