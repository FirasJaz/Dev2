// Created Mai 2016        by MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04023882986
//                         Fax.:  04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// xxxx
//
//****************************************************************************************************************************
//
// Description:
//                      
// creates a new Nachtelefonie
//
//
//****************************************************************************************************************************
//Changes:
//
// 19.12.2016     MZ     set the Nachtelefonie recordType based on opportunity recordType
// 27.02.2017     MZ     set Nachtelefonie.Produkt with opportunity.Produkt value
// 16.11.2017     MZ     #152709934 specific template for PI added
// 16.01.2018     MZ     #154212180
// 24.07.2018	  MZ	 changed for Badumabu. field Nt_Badumbau_type__c added and status of opportunity won't change anymore.
// 26.07.2018	  MZ	 badumbau email template added.
//****************************************************************************************************************************

global with sharing class Nachtelefonie_einrichten {

    public static String Preferred_timeframe_Vormittags ='Vormittags 08:00 – 12:00';
    public static String Preferred_timeframe_Mittags ='Mittags 12:00 – 15:00';
    public static String Preferred_timeframe_Nachmittags ='Nachmittags 15:00 – 18:00';
    
    private static String NT_CUSTOMER = 'Nachtelefonie_customer';
    private static String NT_CUSTOMER_PI = 'Nachtelefonie_customer_PI';
    private static String NT_CUSTOMER_Badumbau = 'Kunde_erstmalig_nicht_erreicht';
    
    private static String BadumbauOppKontaktanbahnungsphase = 'Kontaktanbahnungsphase';
    private static String BadumbauOppErstberatungsphase = 'Erstberatungsphase';
    private static String BadumbauOppAngebotsphase = 'Angebotsphase';
    
    private static String ownerError = 'Zur Weiterverarbeitung musst du Inhaber des Datensatzes sein';
    private static String BadumabuOppStageError = 'Bitte „NT individuell einrichten“ verwenden';
    
    private Opportunity opp;
    private User us;
    Nachtelefonie__c n = new Nachtelefonie__c();
    
    global Nachtelefonie_einrichten(ApexPages.StandardController stdController) {
        this.opp= (Opportunity )stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference einrichten() {
        String oppId = ApexPages.currentPage().getParameters().get('id');
        
        if( isOwner(oppId ) ){
        
        
        List<Opportunity> opp_list = [select id, name, AccountId, recordTypeId, recordType.name, Produkt_Kategorie__c, Preferred_timeframe__c, stageName from Opportunity where id = :oppId limit 1];
        if(opp_list!= null && opp_list.size()>0){
            opp = opp_list[0];
            n.Name='NT - '+ opp.Name;
            n.Opportunity__c = opp.Id;
            n.Produkt_Kategorie__c = opp.Produkt_Kategorie__c;
            n.Familie__c = opp.AccountId;
            n.Preferred_timeframe__c = opp.Preferred_timeframe__c;
            
            List<RecordType> rtList =[select id, name,sobjecttype from recordType where name = :opp.recordType.name and sobjecttype  = 'Nachtelefonie__c' limit 1];
            if(rtList != null && rtList.size()>0){
                n.RecordTypeId = rtList[0].Id;
            }
        }
        
        List<OpportunityContactRole> role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId = :oppId and ( Role = 'PB' or Role = 'PB = ASP')];
        if(role_list != null && role_list.size()>0){
            n.Pflegebed_rftiger__c = role_list[0].ContactId;
        }

        role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId = :oppId and ( Role = 'ASP' or Role = 'PB = ASP')];
        if(role_list != null && role_list.size()>0){
            n.Ansprechpartner__c = role_list[0].ContactId;
        }
                
        List<user> user_list = [select id, name from User where name = 'IT Support' limit 1];
        if(user_list!= null && user_list.size()>0){
            n.OwnerID = user_list[0].id;
            opp.ownerID = user_list[0].id;
        }
        
        NachtelefonieZeitpunkt2 nz = new NachtelefonieZeitpunkt2();
        n.F_lligkeitsdatum__c = nz.getNextPreferredTimeframe(opp.Preferred_timeframe__c);
        
        if(opp.recordType.name != PLZTool_Basis.rtBadumbau){
            opp.StageName = 'Wiedervorlage';
        }else{
            n.Status__c = 'Offen';
            if(!setBadumbauNTType()){
                return null;
            }
        }
        
        insert n;
        update opp;
        
            if(sendEmailToCustomer()){
                // go back to the original page
                PageReference nextpage = new PageReference('/' + oppId );
                nextPage.setRedirect(true);
                return nextpage; 
            }
        }
        return null; 
  }
    
  // NT - Art is a field of NT. the value should be set based on opportunity status
  private Boolean setBadumbauNTType(){
      if(opp.stageName == BadumbauOppKontaktanbahnungsphase){
          n.NT_Badumbau_Type__c = 'Kontaktanbahnung';
      }else if(opp.stageName == BadumbauOppErstberatungsphase){
          n.NT_Badumbau_Type__c = 'Erstberatung';
      }else if(opp.StageName == BadumbauOppAngebotsphase){
          n.NT_Badumbau_Type__c = 'Angebot';
      }else{
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, BadumabuOppStageError ));
          return false;
      }
      return true;
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
    
 public Boolean sendEmailToCustomer(){
    String templateName = NT_CUSTOMER;
    
    if(opp.recordType.name == PLZTool_Basis.rtPflegeimmobilien){
        templateName = NT_CUSTOMER_PI;
    }
    if(opp.RecordType.name == PLZTool_Basis.rtBadumbau){
        templateName = NT_CUSTOMER_Badumbau;
	}
    
    String htmlValue;
    List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = :templateName  limit 1];
    EmailTemplate et = new EmailTEmplate();
  
    if(etList != null && etList.size() > 0){
        et = etList[0];
    }else{
        System.debug('error in sendEmailToCustomer:: Mansi:::: template not found');
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Email-Vorlage wurde nicht gefunden! Prüfen Sie bitte, ob die Email-Vorlage ' + templateName + ' zur Verwendung verfügbar ist.' ));
        return false;
    }
    if(! et.isActive){
        System.debug('error in sendEmailToCustomer:: Mansi:::: template is not active');
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Erforderliche Email-Vorlage ist nicht aktiv! Prüfen Sie bitte, ob die Email-Vorlage ' + templateName + ' zur Verwendung verfügbar ist.' ));
        return false;
    }
    
    Contact c = getContact();
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
    htmlValue = EmailTemplateHelper.setTipp(et.HtmlValue, opp.Id); 
    htmlValue = EmailTemplateHelper.setRecipientFields(htmlValue, c.salutation, c.lastname, c.phone);
    htmlValue = EmailTemplateHelper.setRegion(htmlValue, opp.Id );
    htmlValue = EmailTemplateHelper.setUserfields(htmlValue, UserInfo.getUserId());
    
    String plainTextValue = EmailTemplateHelper.setTipp(et.body, opp.Id).replaceAll('<br/>', ''); 
    plainTextValue = EmailTemplateHelper.setRecipientFields(plainTextValue, c.salutation, c.lastname, c.phone);
    plainTextValue = EmailTemplateHelper.setRegion(plainTextValue, opp.Id ).replaceAll('<br/>', ''); 
    plainTextValue = EmailTemplateHelper.setUserfields(plainTextValue, UserInfo.getUserId());
    
    
    mail.setHtmlBody(htmlValue);
    mail.setPlainTextBody(plainTextValue);
    mail.setSubject(et.Subject);
     
    if(opp.RecordType.name == PLZTool_Basis.rtBadumbau){
        mail.setHtmlBody(EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, htmlValue, UserInfo.getUserId()));
        mail.setPlainTextBody(EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, plainTextValue, UserInfo.getUserId()));
        mail.setSubject(EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, et.Subject, UserInfo.getUserId()));
        mail.setWhatId(opp.Id);
        List<OrgWideEmailAddress> orgWideAddresses = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Badumbau'];
        if(orgWideAddresses != null && orgWideAddresses.size()>0){
        	mail.setOrgWideEmailAddressId(orgWideAddresses[0].Id);
        	mail.setReplyTo(orgWideAddresses[0].Address);
        }
	}
     
    if(c == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Die Opportunity hat keinen ASP Kontakt.'));
            return false;
    }
    else if(c.Email == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Mail konnte nicht zugestellt werden. Der Kontakt hat keine E-Mail-Adresse.'));
            return false;        
    }
    
    mail.setTargetObjectId(c.id);
    
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    return true;
}

private Contact getContact(){
    List<OpportunityContactRole> contactRoles = [select ContactId, Role, IsPrimary  from OpportunityContactRole where OpportunityId = :opp.Id and IsDeleted = false and ( Role = :PLZTool_Basis.contactRoleContact or Role = :PLZTool_Basis.contactRoleSame )];
    if(contactRoles != null && contactRoles.size()>0){
        for( OpportunityContactRole cr : contactRoles  ){
            String contactQuery = 'select Id, Name,lastname, Salutation, Phone, Email, mailingStreet, MailingCity, MailingPostalCode from Contact where Id = \''+cr.ContactId+'\' limit 1';
                                   
            List<Contact> contactList =  Database.query(contactQuery);
             
            
            return contactList[0];
        }
    }else{
        System.debug('error in setIntendedContacts:::: Mansi::: Keine Kontaktrolle gefunden!!!');
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Für die Opportunity wurde keine Kontaktrolle gefunden! '));
    }
    return null;
}
           
}