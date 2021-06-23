//****************************************************************************************************************************
// Created   12.05.2020    by DZ
//                         
//
//****************************************************************************************************************************
//
// Description:
//                      
// Creating a multilead form an opportunity
//
//
//****************************************************************************************************************************
//Changes:
//

//****************************************************************************************************************************
public class OpportunityToMultiLead{

    private static String ownerError = 'Zur Weiterverarbeitung musst du Inhaber des Datensatzes sein';
    private static String rtCurabox = 'Curabox';
    private static String rtTreppenlift = 'Treppenlift';
    private static String rtBetreuungsleistungen = 'Betreuungsleistungen';
    private static String rtNotrufSystem = 'Notrufsysteme';
    private static String rtWiderspruch = 'Widerspruch';
    private static String rtPflegeimmobilien = 'Pflegeimmobilien';
    private static String rtBadumbau = 'Badumbau';
    private static String rtPflegeschulungen = 'Pflegeschulungen';
    
    public Boolean leadUebernehmen {get; set;}


    public Lead formObj = new Lead();
    public Id opportunityId;
    
    public String selectedRt = '';

    public Boolean isOwner;
    public string message_display {get; set;}
    public string message {get; set;}
        
    public OpportunityToMultiLead(){
        opportunityId = ApexPages.currentPage().getParameters().get('id');
        message_display = 'none';
    }
    

    
    public List<SelectOption> getRtItems() {
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption(rtCurabox , rtCurabox ));
        options.add(new SelectOption(rtTreppenlift , rtTreppenlift ));
        options.add(new SelectOption(rtBetreuungsleistungen , rtBetreuungsleistungen ));
        options.add(new SelectOption(rtNotrufSystem, rtNotrufSystem));
        options.add(new SelectOption(rtWiderspruch, rtWiderspruch));
        options.add(new SelectOption(rtPflegeimmobilien, rtPflegeimmobilien));
        options.add(new SelectOption(rtBadumbau, rtBadumbau));
        options.add(new SelectOption(rtPflegeschulungen, rtPflegeschulungen));
        
        return options;
    }
    

    public void  setSelectedRt(String val){
        selectedRt = val;
    } 
    
    public String getSelectedRt(){
        return selectedRt ;
    }
    
    
    public PageReference Speichern(){
        if ( ! isOwner(opportunityId) ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ownerError ));
            return null;
        }
        try{
            // prepare the lead
            List<recordType> rtList = [select Id, name from RecordType where name = :selectedRt and SObjectType = 'Lead' ];
            if(rtList == null || rtList.size() == 0 ){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'selected record_type not found ! '));
                return null;
            }            
            formObj.RecordTypeId = rtList[0].Id;
            
            Contact c;
            Contact r;
            if( selectedRt == rtTreppenlift || selectedRt == rtBetreuungsleistungen || selectedRt == rtNotrufSystem || selectedRt == rtWiderspruch || selectedRt == rtPflegeimmobilien || selectedRt == rtBadumbau || selectedRt == rtPflegeschulungen){
                c = getASPContact();
            }else if( selectedRt == rtCurabox ){
                c = getPBContact();
                r = getRelativeContact();
                if(c == null){
                    c = getASPContact();
                }
            }
            if(c == null){
                return null;
            }
            formObj.Salutation = c.Salutation;
            formObj.FirstName = c.FirstName;
            formObj.LastName = c.LastName;
            formObj.Street = c.mailingStreet;
            formObj.PostalCode = c.MailingPostalCode;
            formObj.City = c.MailingCity;
            formObj.Country = c.MailingCountry;
            formObj.Phone = c.Phone;
            formObj.MobilePhone = c.MobilePhone;
            formObj.Email = c.Email;
            
            if(r != null){
                formObj.Angehoeriger_Anrede__c = r.Salutation;
                formObj.Angehoeriger_Vorname__c = r.FirstName;
                formObj.Angehoeriger_Nachname__c = r.LastName;
                formObj.Angehoeriger_Strasse__c = r.mailingStreet;
                formObj.Angehoeriger_PLZ__c = r.MailingPostalCode;
                formObj.Angehoeriger_Ort__c = r.MailingCity;
                formObj.Angehoeriger_Telefon__c = r.Phone;
                formObj.Angehoeriger_Email__c = r.Email;
            }
            
            formObj.Company = selectedRt;
            
            List<Campaign> cmpList = [select id, name from Campaign where name ='Multilead' limit 1];
            if (cmpList != null && cmpList.size()>0) {
                formObj.OM_Wizzard_Name2__c = cmpList[0].Id; 
            } 
            List<Opportunity> oppList = [select id, Alternative_Postleitzahl__c, OM_Tracking_Order_ID__c from Opportunity where id = :OpportunityId limit 1];
            if (oppList != null && oppList.size()>0) {
                Opportunity opp = oppList[0];
                formObj.TL_Postleitzahl_f_r_Suche__c = opp.Alternative_Postleitzahl__c;
                formObj.Vorherige_Anfrage__c = opp.Id;
                formObj.OM_Tracking_Order_ID__c = opp.OM_Tracking_Order_ID__c;
            }
            
            formObj.Mitarbeiter__c = userInfo.getName();
            
            List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
            if(user_list != null && user_list.size()>0){
                formObj.ownerID = user_list[0].id;
            }
            
            if(leadUebernehmen) formObj.ownerID = UserInfo.getUserId();
        
            insert formObj;
            
            return zuLead(formObj.Id);
                     
        }catch(Exception e){
            System.debug('mansi:: error in speichern::'+ e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage() ));       
        }
        return null;
    }
  
    private Contact getPBContact(){
        List<OpportunityContactRole> contactRoles = [select ContactId, Role, IsPrimary  from OpportunityContactRole where OpportunityId = :opportunityId and IsDeleted = false and ( Role = :PLZTool_Basis.contactRoleInsured or Role = :PLZTool_Basis.contactRoleSame )];
        if(contactRoles != null && contactRoles.size()>0){
            for( OpportunityContactRole cr : contactRoles ){
                List<Contact> contactList = [select 
                                             Id,
                                             Name,
                                             firstName,
                                             lastname, 
                                             Salutation, 
                                             Phone,
                                             MobilePhone,
                                             Email, 
                                             mailingStreet, 
                                             MailingCity, 
                                             MailingPostalCode,
                                             MailingCountry
                                             from Contact 
                                             where Id = :cr.ContactId limit 1];
                return contactList[0];
            }
        }else{
            System.debug('error in setIntendedContacts:::: Mansi::: no PB Contact role found !!!');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No PB Contact is defined for the opportunity! '));
        }
        return null;
    }
  
    private Contact getASPContact(){
        List<OpportunityContactRole> contactRoles = [select ContactId, Role, IsPrimary  from OpportunityContactRole where OpportunityId = :opportunityId and IsDeleted = false and ( Role = :PLZTool_Basis.contactRoleContact or Role = :PLZTool_Basis.contactRoleSame )];
        if(contactRoles != null && contactRoles.size()>0){
            for( OpportunityContactRole cr : contactRoles  ){
                List<Contact> contactList = [select 
                                             Id,
                                             Name,
                                             firstName,
                                             lastname, 
                                             Salutation, 
                                             Phone,
                                             MobilePhone,
                                             Email, 
                                             mailingStreet, 
                                             MailingCity, 
                                             MailingPostalCode,
                                             MailingCountry
                                             from Contact 
                                             where Id = :cr.ContactId limit 1];
                
                return contactList[0];
            }
        }else{
            System.debug('error in setIntendedContacts:::: Mansi::: no ASP Contact role found !!!');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No ASP Contact is defined for the opportunity! '));
        }
        return null;
    }
    
    private Contact getRelativeContact(){
        List<OpportunityContactRole> contactRoles = [select ContactId, Role, IsPrimary  from OpportunityContactRole where OpportunityId = :opportunityId and IsDeleted = false and Role = :PLZTool_Basis.contactRoleContact ];
        if(contactRoles != null && contactRoles.size()>0){
            for( OpportunityContactRole cr : contactRoles  ){
                List<Contact> contactList = [select 
                                             Id,
                                             Name,
                                             firstName,
                                             lastname, 
                                             Salutation, 
                                             Phone,
                                             MobilePhone,
                                             Email, 
                                             mailingStreet, 
                                             MailingCity, 
                                             MailingPostalCode,
                                             MailingCountry
                                             from Contact 
                                             where Id = :cr.ContactId limit 1];
                
                return contactList[0];
            }
        }else{
            System.debug('error in setIntendedContacts:::: Mansi::: no ASP Contact role found !!!');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No ASP Contact is defined for the opportunity! '));
        }
        return null;
    }
    
    public class applicationException extends Exception{}
    
    public PageReference zuOpportunity(){
        PageReference PageRef = new PageReference('/' + opportunityId);
        PageRef.setRedirect(true);
        
        return PageRef;
    }
    
    public PageReference zuLead(Id leadId){
        PageReference PageRef = new PageReference('/' + leadId);
        PageRef.setRedirect(true);
        
        return PageRef;
    }
    
    public boolean isOwner(Id opportunityId ){
        Opportunity opp = new Opportunity();
        List<opportunity> oppList =  [select Id, Owner.Id from opportunity where id = :opportunityId limit 1];
        if(oppList != null && oppList.size()>0){
            opp = oppList[0];
            if(opp.Owner.Id != UserInfo.getUserId()){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ownerError ));
                return False;
            }
        }
        return True;
    } 
    
     
}