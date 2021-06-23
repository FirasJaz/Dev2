/****************************************************************************************************************************
//  Erstellt 02.10.2017 von MZ
//  Klose und Srocke Gesellschaft fÃ¼r kreative KonfliktlÃ¶sungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Opportunity.reference_number + contact.Phone_number
//
//****************************************************************************************************************************
//
// Description:
// handleing the functionality when phone number is provided for prospect opportunities.  
//    1. update phone number
//    2. update opportunity status
//
//****************************************************************************************************************************
//Änderungen:
// 11.10.2017 MZ   No longer any NT is needed. 
// 27.10.2017 MZ   update plz/street/city of contact with new data. 
// 02.11.2017 MZ   update needed_in_zip_code/needed_in_city of opportunity with new data.
//****************************************************************************************************************************
*/
global class Prospect_Opportunity{

    global Prospect_Opportunity(){}
    
    public static String updateContactPhone(String referenceNumber, String phone1, String phone2, String postalcode, String city, String street, String needed_in_zip_code, String needed_in_city){
        try{
            Contact con_toUpdate;
            Opportunity opp_toUpdate;
            List<Opportunity> opp_list = [select id,
                                                 OM_Referenznummer__c,
                                                 Name,
                                                 Produkt_Kategorie__c,
                                                 AccountId,
                                                 Alternative_Postleitzahl__c,
                                                 Angefragter_Wohnort__c,
                                                 RecordTypeId,
                                                 RecordType.name
                                                 from opportunity where stageName = 'Prospect Mkt Cloud' and OM_Referenznummer__c = :referenceNumber];
            
            if(opp_list != null && opp_list.size()>0){
                opp_toUpdate = opp_list[0];
                if(!String.isEmpty(phone1) || !String.isEmpty(phone2)){
                    List<Contact> contactList = new List<Contact>();
                    List<OpportunityContactRole> crList = [select id, ContactId, Role from OpportunityContactRole where OpportunityId =: opp_list[0].id ];
                    Map<String,Id> contactIdMap = new Map<String,Id>();
                    if(crList!= null && crList.size()>0){
                        for(OpportunityContactRole cr: crList){
                            contactIdMap.put(cr.Role, cr.ContactId);
                        } 
                        if(contactIdMap.size()>1){
                            contactList = [select Phone, OtherPhone, firstName, LastName, Email, MailingCity, MailingPostalCode, MailingStreet from Contact where Id = :contactIdMap.get('ASP') or Id = :contactIdMap.get('PB = ASP') ];
                        }else{
                            contactList = [select Phone, OtherPhone, firstName, LastName, Email, MailingCity, MailingPostalCode, MailingStreet from Contact where Id in :contactIdMap.values()];
                        }
                        if(contactList!= null && contactList.size()>0){
                            con_toUpdate = contactList[0];
                            if(!String.isEmpty(phone1)){
                                con_toUpdate.Phone = phone1;
                            }
                            if(!String.isEmpty(phone2)){
                                con_toUpdate.OtherPhone = phone2;
                            }
                            if(!String.isEmpty(postalcode)){
                                con_toUpdate.MailingPostalCode = postalcode;
                            }
                            if(!String.isEmpty(city)){
                                con_toUpdate.MailingCity = city;
                            }
                            if(!String.isEmpty(street)){
                                con_toUpdate.MailingStreet = street;
                            }
                            
                            if(!String.isEmpty(needed_in_zip_code)){
                                opp_toUpdate.Alternative_Postleitzahl__c = needed_in_zip_code;
                            }
                            if(!String.isEmpty(needed_in_city)){
                                opp_toUpdate.Angefragter_Wohnort__c = needed_in_city;
                            }
                            opp_toUpdate.Prio__c = true;
                            opp_toUpdate.StageName = 'offen';
                            
                            /*
                            Nachtelefonie__c n = new Nachtelefonie__c ();
                            n.Name='NT - '+ opp_toUpdate.Name;
                            n.Opportunity__c = opp_toUpdate.Id;
                            n.Produkt_Kategorie__c = opp_toUpdate.Produkt_Kategorie__c;
                            n.Familie__c = opp_toUpdate.AccountId;
                            n.F_lligkeitsdatum__c = Datetime.now();
                            
                            List<RecordType> rtList =[select id, name, sobjecttype from recordType where name ='opp_toUpdate.recordType.name' and sobjecttype  = 'Nachtelefonie__c'];
                            if(rtList != null && rtList.size()>0){
                                n.RecordTypeId = rtList[0].id;
                            }
                            n.Pflegebed_rftiger__c = contactIdMap.get('PB');
                            n.Ansprechpartner__c = contactIdMap.get('ASP');
                            
                            List<user> user_list = [select id, name from User where name = 'IT Support' limit 1];
                            if(user_list!= null && user_list.size()>0){
                                n.OwnerID = user_list[0].id;
                            }*/
                            
                            update con_toUpdate;
                            update opp_toUpdate;
                            //insert n;
                        }
                        else{
                            return 'Error: no contact found with the specified Id or Role!';
                        }
                    }
                    else{
                        return 'Error: no contact-role found for the opportunity!';
                    }
                }
                else{
                    return 'Error: phone number has no value!';
                }
            }
            /*else{
                return 'Error: no opportunity found with referencenumber ' + referenceNumber + ' and status prospect!';
            }*/
        }catch(Exception e){
            return 'Error: Prospect_Opportunity ' + e.getMessage();
        }
        return 'OK';
    }
    
}