/****************************************************************************************************************************
// Created 23.05.2018 von MZ
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
// #157053974                     
// controller for Post conversion landingpage
// instance number is required regardless of the environment
// lead data would be updated if lead is not converted.
// if lead is already converted,update contact, account, opportunity name and status + a new NT
//
//
//****************************************************************************************************************************
// Changes:
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@RestResource(urlMapping='/ZWBContactUpdate/*')
// dev :    https://dev-pflegede.cs84.force.com/services/apexrest/ZWBContactUpdate/
// FS:      https://fs-pflegede.cs80.force.com/services/apexrest/ZWBContactUpdate/
// Prod:    https://pflegede.EU6.force.com/services/apexrest/ZWBContactUpdate/
// request: { "Order_ID": "69b1c4dc-384a-4c8a-a5cb-099dc70f7c3d",
//  "contact_mail_from": "",
//  "contact_first_name": "firstnamepost", 
//  "contact_last_name": "postlast", 
//  "contact_phone_number": "1111111111", 
//  "contact_salutation": "Frau"
//}


global class ksgZWBContactUpdateController {
    @HttpPost 
    global static string updateContact(String Order_ID,
                                       String contact_mail_from,
                                       String contact_first_name,
                                       String contact_last_name,
                                       String contact_phone_number,
                                       String contact_salutation){
    	string ret = 'OK';
        if(String.isEmpty(Order_ID)){
            ret = 'Error: Order_ID is empty!';
            return ret;
        }
        List<Lead> existingLeads = [select id,
                                    status,
                                    OM_UserID__c,
                                    Firstname,
                                    Lastname,
                                    Phone,
                                    Salutation,
                                    postalcode,
                                    City,
                                    Street,
                                    Phone2__c,
                                    isConverted,
                                    OM_Tracking_Order_ID__c 
                                    from lead
                                    where OM_Tracking_Order_ID__c  = :Order_ID ];
        Lead l;
        if(existingLeads != null && existingLeads.size() > 0){
            l = existingLeads[0];
            if(!l.isConverted){
                // update lead
            	l.Firstname = contact_first_name;
            	l.Lastname = contact_last_name;
            	l.Phone = contact_phone_number;
            	l.Salutation = contact_salutation;
                l.Email = contact_mail_from;
            	try{
                	update l;
            	}catch(Exception e){
                	ret = 'Error: error in updating lead, ' + e.getMessage();
            	}
                return ret;
            }
        }
                                           
        /* the part is removed because of problem of ticket #159167555. should be added later
                                          
        // check for opportunity
        // update contact, account, opportunity and create a NT
                
        // try to find the opportunity based on Order_ID.
        List<Opportunity> oppList = [select id,
                                              Abbruchgrund__c,
                                              Urspr_nglicher_Lead__c,
                                              OM_Tracking_Order_ID__c,
                                              AccountID,
                                              Name,
                                              Produkt_Kategorie__c,
                                              recordType.name
                                              from Opportunity 
                                              where OM_Tracking_Order_ID__c = :Order_ID
                                              Order by createdDate desc
                                              limit 1];
         if((oppList == null || oppList.size()==0) && (l != null && l.Id != null) ){
                    //try to find the opportunity based on converted lead
                    oppList = [select id,
                               Abbruchgrund__c,
                               Urspr_nglicher_Lead__c,
                               OM_Tracking_Order_ID__c,
                               AccountID,
                               Name, 
                               Produkt_Kategorie__c,
                               recordType.name
                               from Opportunity 
                               where Urspr_nglicher_Lead__c = :l.Id
                               Order by createdDate desc
                               limit 1];
         }
                
                if(oppList != null && oppList.size()>0){
                    Opportunity opp = oppList[0];
                    Contact cont;
                    Account acc;
                    Id accountId = opp.AccountId;
                    
                    List<OpportunityContactRole> contactRoles = [select ContactId, 
                                                                 Role, 
                                                                 IsPrimary,
                                                                 Contact.accountId
                                                                 from OpportunityContactRole 
                                                                 where OpportunityId = :opp.Id 
                                                                 and Contact.accountId = :opp.AccountId
                                                                 and IsDeleted = false 
                                                                 //and (Role = :PLZTool_Basis.contactRoleSame or Role = :PLZTool_Basis.contactRoleContact)
                                                                 order by Role desc // first comes PB = ASP, then ASP, then PB
                                                                ];
                    if(contactRoles == null || contactRoles.size()==0){
                        contactRoles = [select ContactId, Role, IsPrimary, Contact.accountId  
                                                                 from OpportunityContactRole 
                                                                 where OpportunityId = :opp.Id 
                                                                 and IsDeleted = false 
                                                                 //and (Role = :PLZTool_Basis.contactRoleSame or Role = :PLZTool_Basis.contactRoleContact)
                                                                 order by Role desc // first comes PB = ASP, then ASP, then PB
                                                                ];
                    }
                    if(contactRoles != null && contactRoles.size()>0){
                        if(contactRoles[0].Contact.accountId != null){
                            accountId = contactRoles[0].Contact.accountId;
                        }
                        List<Contact> contactList = [select id, 
                                                     accountId,
                                                     Salutation,
                                                     firstname,
                                                     lastname,
                                                     Email,
                                                     Phone,
                                                     MailingCity,
                                                     MailingPostalCode,
                                                     MailingStreet,
                                                     OtherPhone
                                                     from Contact
                                                     where Id = :contactRoles[0].ContactId];
                        if(ContactList != null && contactList.size()>0){
                            cont = ContactList[0];
                            cont.Salutation = contact_salutation;
                            cont.firstname = contact_first_name;
                            cont.lastname = contact_last_name;
                            cont.Email = contact_mail_from;
                            cont.Phone = contact_phone_number;
                        }
                        List<Account> accList = [select id,
                                                 Name,
                                                 Familien_Name__c,
                                                 BillingCity
                                                 from Account 
                                                 where Id = :accountId
                                                 limit 1];
                        
                        if(accList != null && accList.size()>0){
                            acc = accList[0];
                            acc.Name = contact_last_name;
                            acc.Familien_Name__c = contact_last_name;
                        }
                        if(cont != null){
                            try{
                                update cont;
                            }catch(Exception e){
                                ret = 'Error: could not update contact; ' + e.getMessage();
                            }
                        }
                        if(acc != null){
                            try{
                                update acc;
                                if(opp != null){
                                    try{
                                        opp.stageName = 'Offen';
                                        opp.Abbruchgrund__c = null;
                                        update opp;
                                    }catch(Exception e){
                                        ret = 'Error: could not update opportunity; ' + e.getMessage();
                                    }
                            	}
                            }catch(Exception e){
                                ret = 'Error: could not update account; ' + e.getMessage();
                            }
                        }
                        try{
                            String oppName = opp.Name;
                            oppList = [select id, Name
                                       from Opportunity 
                                       where Id = :opp.Id];
                            if(oppList != null && oppList.size()>0){
                                oppName = oppList[0].Name;
                            }
                            Nachtelefonie__c n = new Nachtelefonie__c ();
                        	n.Name='NT - '+ oppName;
                        	n.Opportunity__c = opp.Id;
                        	n.Produkt_Kategorie__c = opp.Produkt_Kategorie__c;
                        	n.Familie__c = accountId;
                            n.F_lligkeitsdatum__c = Datetime.now();
                            List<RecordType> rtList =[select id, name, sobjecttype from recordType where name =:opp.recordType.name and sobjecttype  = 'Nachtelefonie__c'];
                            if(rtList != null && rtList.size()>0){
                                n.RecordTypeId = rtList[0].id;
                            }
                            List<OpportunityContactRole> ASPContactRoles = [select ContactId 
                                                                            from OpportunityContactRole
                                                                            where OpportunityId = :opp.Id 
                                                                            and (Role = :PLZTool_Basis.contactRoleSame or Role = :PLZTool_Basis.contactRoleContact) limit 1];
                            List<OpportunityContactRole> PBContactRoles = [select ContactId 
                                                                            from OpportunityContactRole
                                                                            where OpportunityId = :opp.Id 
                                                                            and (Role = :PLZTool_Basis.contactRoleSame or Role = :PLZTool_Basis.contactRoleInsured) limit 1];
                            if(ASPContactRoles != null && ASPContactRoles.size()>0){
                                n.Ansprechpartner__c = ASPContactRoles[0].ContactId;
                            }
                            if(PBContactRoles != null && PBContactRoles.size()>0){
                                n.Pflegebed_rftiger__c = PBContactRoles[0].ContactId;
                            }
                            
                            List<user> user_list = [select id, name from User where name = 'IT Support' limit 1];
                            if(user_list!= null && user_list.size()>0){
                                n.OwnerID = user_list[0].id;
                            }
                            
                            insert n;
                            
                        }catch(Exception e){
                            ret = 'Error: Could not create Nachtelefonie; '+ e.getMessage();
                        }
                        
                    }else{
                    	ret = 'Error: Opportunity has no ASP';
                    }
                }else{
                    ret = 'Error: could not find any Lead / Opportunity with matching OM_Tracking_Order_ID';
                }
                                           
          */
              
              
        return ret;
    }
}