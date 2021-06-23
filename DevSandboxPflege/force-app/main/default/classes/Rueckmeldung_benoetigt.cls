//****************************************************************************************************************************
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
//****************************************************************************************************************************
// test class: Rueckmeldung_benoetigt_test
//****************************************************************************************************************************
//Changes:
//
// 19.12.2016     MZ     set the Nachtelefonie recordType based on opportunity recordType
// 16.11.2017     MZ     #152709934 specific template for PI added
//****************************************************************************************************************************


global with sharing class Rueckmeldung_benoetigt {

    private static String defaultTemplate = 'rueckmeldungTemplate';
    private static String rueckmeldungTemplatePI = 'rueckmeldungTemplate_PI';

    private static String ownerError = 'Zur Weiterverarbeitung musst du Inhaber des Datensatzes sein';
    private static String noCauseSelectedError = 'Bitte wähle einen Grund aus!';
    public Opportunity opp{get;set;}
    public String selectedCause{get;set;}
    private User us;
    
    
    public List<SelectOption> getPickListValuesIntoList(){
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = opportunity.Rueckmeldunggrund__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add(new SelectOption('', '--None--'));
        for( Schema.PicklistEntry pickListVal : ple){
            options.add(new SelectOption(pickListVal.value, pickListVal.label));
        }     
        return options;
    }
    
    global Rueckmeldung_benoetigt(ApexPages.StandardController stdController) {
        this.opp= (Opportunity )stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference start_rueckmeldung() {
        if(String.isEmpty(selectedCause)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noCauseSelectedError ));
            return null;
        }
        String oppId = ApexPages.currentPage().getParameters().get('id');
        if( isOwner(oppId ) ){
        
        Nachtelefonie__c n = new Nachtelefonie__c();
        
        List<Opportunity> opp_list = [select id, name, AccountId, recordTypeId, recordType.name, StageName from Opportunity where id = :oppId limit 1];
        if(opp_list!= null && opp_list.size()>0){
            opp = opp_list[0];
            
            if(opp.stageName == NachtelefonieAbbruch.status_opp_abbruch){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Opportunity-stage ist Abbruch!'));
                return null;
            }
            
            n.Name='NT - '+ opp.Name;
            n.Opportunity__c = opp.Id;
            n.Familie__c = opp.AccountId;
            
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
        
        n.status__c = 'Rückmeldung benötigt'; 
        n.F_lligkeitsdatum__c = Datetime.now().addDays(7);
        n.Rueckmeldunggrund__c = selectedCause;
        
        opp.Rueckmeldunggrund__c = selectedCause;
        opp.StageName = 'Warten auf Rückmeldung Kunden';
        
        try{
            insert n;
            update opp;
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
            return null;
        }
        
        
        List<Contact> c_list = [select id, salutation, name, lastname, phone, Email from contact where Id = :n.Ansprechpartner__c limit 1 ];
        Contact recipient;
        if( c_list!= null && c_list.size()>0 ){
            recipient = c_list[0];
        }
        if(recipient == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Die Opportunity hat keinen ASP Kontakt.'));
            return null;
        }else if(recipient.Email == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Mail konnte nicht zugestellt werden. Der Kontakt hat keine E-Mail-Adresse.'));
            return null;       
        }
        
        // Send Email to ASP       
        String templateName = defaultTemplate;
        if(opp.recordType.name == PLZTool_Basis.rtPflegeimmobilien){
            templateName = rueckmeldungTemplatePI;
        }
        
        EmailTemplate et = new EmailTemplate();
        String htmlValue;
        String plainTextValue;
        
        List<EmailTemplate> et_list = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body from EmailTemplate where DeveloperName = :templateName limit 1 ];
        if(et_list != null && et_list.size()>0){
            et = et_list[0];
        }
               
        if(!et.isActive){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Erforderliche Email-Vorlage ist nicht aktiv!'));
            return null;
        }else{
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            htmlValue = EmailTemplateHelper.setTipp(et.HtmlValue, opp.Id); 
            htmlValue = EmailTemplateHelper.setRecipientFields(htmlValue, recipient.salutation, recipient.Lastname, recipient.phone );
            htmlValue = EmailTemplateHelper.setRegion(htmlValue, opp.Id);
            htmlValue = EmailTemplateHelper.setUserfields(htmlValue, UserInfo.getUserId());
            
            plainTextValue = EmailTemplateHelper.setTipp(et.body, opp.Id).replaceAll('<br/>', ''); 
            plainTextValue = EmailTemplateHelper.setRecipientFields(plainTextValue, recipient.salutation, recipient.Lastname, recipient.phone );
            plainTextValue = EmailTemplateHelper.setRegion(plainTextValue, opp.Id).replaceAll('<br/>', ''); 
            plainTextValue = EmailTemplateHelper.setUserfields(plainTextValue, UserInfo.getUserId());
            
            mail.setHtmlBody(htmlValue);
            mail.setPlainTextBody(plainTextValue);
            mail.setSubject(et.Subject);
            mail.setTargetObjectId(recipient.id); 
            Messaging.SendEmailResult[] sendMailRes = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});  
            if(! sendMailRes[0].success){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Error : could not send email! ' + sendMailRes[0]));
                return null;
            }          
        }
        
        // go back to the original page
        PageReference nextpage = new PageReference('/' + oppId );
        nextPage.setRedirect(true);
        return nextpage;  
        }
        return null;
  }

    public boolean isOwner(Id opportunityId ){
        List<opportunity> oppList =  [select Id, Owner.Id, RecordType.Name from opportunity where id = :opportunityId limit 1];
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