//****************************************************************************************************************************
//     Erstellt 19.06.2017 von MZ
//     Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//     Nordkanalstrasse 58
//     20097 Hamburg 
//     Tel.:  04064917161
//     Fax.:  04064917162
//     Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung: send Email to partners. the class is used in NotificationEmailToPartner, ErinnerungsmailAnPartner. 
//
//
//****************************************************************************************************************************
// Änderungen:
//    16.11.2017    MZ    #152709934 specific template for PI added
//****************************************************************************************************************************/

global with sharing class EmailToPartner {

    private Partner_Ticket__c pt;
    private Id partnerTicketId;
    private PLZTool_PartnerProduct p;
    
    private Boolean notificationEmail = false;
    private Boolean reminderEmail = false;
    
    protected User currentUser;
    protected contact primaryContact;
    protected Contact insuredPerson;
    protected Contact contactPerson;

    global EmailToPartner(Id ticketId, Boolean notificatinFlag, Boolean reminderFlag){
        if(ticketId != null){
            partnerTicketId = ticketId;
        }
        notificationEmail = notificatinFlag;
        reminderEmail = reminderFlag;
        setCurrentUser();
    }
    
    public void sendEmail(){
        try{
            prepareData();
            sendEmailToPartner();
        }
        catch(Exception e){
            throw e;
        }
    }
 
    private void sendEmailToPartner() {   
        String templateName = PLZTool_Basis.partnerTemplateName_single;
        
        // Pflegeimmobilien
        if(pt.Opportunity__r.recordType.Name == PLZTool_Basis.rtPflegeimmobilien){
            templateName = PLZTool_Basis.partnerTemplate_PI;
        }
        
        EmailTemplate et = new EmailTemplate();
        List<EmailTemplate> etList = new List<EmailTemplate>();  
        
        etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = : templateName limit 1];
        
        if(etList != null && etList.size() > 0){
            et = etList[0];
        } else {
            System.debug('error in sendEmailToPartner:: Mansi:::: template not found');
            throw new ApplicationException('Email template not found! Please check the availability of the email template where DeveloperName = ' + PLZTool_Basis.partnerTemplateName_single);
        }
        if(!et.isActive){
            System.debug('error in sendEmailToPartner:: Mansi:::: template is not active');
            throw new ApplicationException('Required email template is not active! Please check the availability of the email template where DeveloperName = ' + PLZTool_Basis.partnerTemplateName_single);
        }
        
        String subject = et.Subject;
        String htmlValue = et.HtmlValue;
        
        if(reminderEmail){
            subject = 'fehlende Rückmeldung – ID: <PT:Partner_Ticket_name>';
            htmlValue = htmlValue .replace('<header_text>', 'fehlende Rückmeldung – ID: <PT:Partner_Ticket_name>');
        }else{
            htmlValue = htmlValue .replace('<header_text>', 'Vermittlung von Interessenten');
        }
        
        
        //set product type and opportunityId
        subject = subject.replace('<OPP:Opportunity_Nummer__c>', pt.Opportunity__c);
        subject = subject.replace('<PT:Partner_Ticket_name>', pt.Name );
        
        // Notrufsysteme
        if(pt.Opportunity__r.recordType.Name == PLZTool_Basis.rtHausnotruf){
            if(p.pp.PLZ_Tool_Liste__c == PLZTool_Hausnotruf.direktVertriebKey ){
                subject = subject.replace('<title_text>', 'Direktversand '+ p.pp.produktgruppe__c);
            }
            if(p.pp.PLZ_Tool_Liste__c == PLZTool_Hausnotruf.exklusivKey ){
                subject = subject.replace('<title_text>', 'erfolgreich durchgestellt');
            }
        }
        
        // Widerspruch
        if(pt.Opportunity__r.recordType.Name == PLZTool_Basis.rtwiderspruch){
            subject = subject.replace('<title_text>', 'Anfrage zum ');
            subject = subject.replace('<OPP:Product>', 'Widerspruch gegen einen negativen Pflegebescheid');
            htmlValue = htmlValue .replace('<Comment:main>', 'zum Thema Widerspruch gegen einen negativen Pflegebescheid. <Comment:extra>');
        }
        
        subject = subject.replace('<title_text>', 'Anfrage für die Produktgruppe');
        subject = subject.replace('<OPP:Product>', pt.Opportunity__r.recordType.Name);
        
        htmlValue = htmlValue .replace('<OPP:Product>', pt.Opportunity__r.recordType.Name);
        htmlValue = htmlValue .replace('<Comment:main>', 'für die Produktgruppe "<OPP:Product>". <Comment:extra>');
        htmlValue = htmlValue .replace('<PT:Partner_Ticket_name>', pt.Name );
        
        System.debug('mansi::ticket_email_address__c:'+ p.pp.partner__r.ticket_email_address__c);
        System.debug('mansi::ticket_cc_email_address__c:'+ p.pp.partner__r.ticket_cc_email_address__c);
        System.debug('mansi::ticket_bcc_email_address__c:'+ p.pp.partner__r.ticket_bcc_email_address__c);
            
        // the standard template is not needed for structuredEmail
        if(p.pp.Strukturierte_Partner_Email__c != null){
            System.debug('sending notifications/reminders is not enabled for structured emails');
        }
        else{
                plzPartnerEmailBodyGenerator bodyGenerator = new plzPartnerEmailBodyGenerator(pt.Opportunity__r.recordType.Name);
                bodyGenerator.notificationEmail = notificationEmail;
                bodyGenerator.setPlzToolListe(p.pp.PLZ_Tool_Liste__c);
                String htmlValuePerPartner = bodyGenerator.prepareEmailbody(pt.Opportunity__c, htmlValue, contactPerson, insuredPerson, p.pp.Individuelle_Partner_Email__c);
                
                htmlValuePerPartner = setUserfields(htmlValuePerPartner );
                htmlValuePerPartner = htmlValuePerPartner.replace('<p id="partnerTicket"/>', partnerTicketId );
                htmlValuePerPartner = htmlValuePerPartner.replace('<p id="comment"/>', getFormattedString(p.comment));
                futureSendEmailToPartners(htmlValuePerPartner, 
                                          et.body, 
                                          subject, 
                                          pt.Opportunity__c, 
                                          et.Id, 
                                          p.pp.partner__r.ticket_email_address__c,
                                          p.pp.partner__r.ticket_cc_email_address__c,
                                          p.pp.partner__r.ticket_bcc_email_address__c);
                
        }
        
    }
    
    public void prepareData(){
        List<Partner_Ticket__c> ptList = [select Id,
                                            Name,
                                            Partner_Produkt__c, 
                                            Opportunity__c, 
                                            Opportunity__r.recordType.Name,
                                            Opportunity__r.Anmerkungen_f_r_den_Partner__c 
                                          from Partner_Ticket__c 
                                          where Id =: partnerTicketId
                                          limit 1];
        
        if( ptList != null && ptList.size()>0){
            pt = ptList[0];
        }
        else{
            throw new ApplicationException('No Partner Ticket found with Id = ' + partnerTicketId);
        }
        try{
            setIntendedContacts();
        }catch(Exception e){
            throw e;
        }
        
        List<Partner_Produkte__c> ppList = [select Id, 
                                                Kontingent_offen_Produkt__c, 
                                                Partner__r.Kontingent_offen_Partner__c, 
                                                Partner__c, 
                                                Partner__r.Name, Produktgruppe__c, 
                                                partner__r.BillingStreet, 
                                                partner__r.BillingCity, 
                                                partner__r.BillingPostalCode, 
                                                partner__r.Phone, 
                                                partner__r.Website, 
                                                partner__r.Logo_Url__c, Anmerkung__c, 
                                                Medizinische_Pflege__c, 
                                                Leichte_Pflege__c, 
                                                Betreuung__c, 
                                                Hauswirtschaft__c, 
                                                Vermittlungsmodell__c,
                                                Priorit_t__c, Kosten__c, 
                                                Mindestdauer_des_Einsatzes__c, 
                                                Herkunftsland_der_Betreuer__c, 
                                                partner__r.ticket_email_address__c, 
                                                partner__r.ticket_cc_email_address__c, 
                                                partner__r.ticket_bcc_email_address__c,
                                                Individuelle_Partner_Email__c, 
                                                Strukturierte_Partner_Email__c, 
                                                Kostenstelle__c, 
                                                Belastbarkeit__c,
                                                PLZ_Tool_Liste__c
                                             from Partner_Produkte__c 
                                             where Id = :pt.Partner_Produkt__c
                                             limit 1];
                                             
        if(ppList == null || ppList.size()==0){
            throw new ApplicationException('Not product found with Id = ' + pt.Partner_Produkt__c);
        }
        
        p = new PLZTool_PartnerProduct(ppList[0], false);
        p.setPrice();
        p.comment = pt.Opportunity__r.Anmerkungen_f_r_den_Partner__c;
        
    }


    @future(callout=true)
    private static void futureSendEmailToPartners(String htmlValuePerPartner, 
                                                 String plainTextBody, 
                                                 String subject, 
                                                 id WhatId, 
                                                 id TemplateId, 
                                                 String emailAddrresses,
                                                 String ccEmailAddrresses,
                                                 String bccEmailAddrresses)
    {   
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(htmlValuePerPartner);
        mail.setPlainTextBody(plainTextBody);
        mail.setSubject(subject);
        mail.setWhatId(WhatId);
        mail.setToAddresses(emailAddrresses.split(','));
        if(!String.isBlank(ccEmailAddrresses)){
            mail.setCcAddresses (ccEmailAddrresses.split(','));
        }
        if(!String.isBlank(bccEmailAddrresses)){
            mail.setBccAddresses (bccEmailAddrresses.split(','));
        }
        mail.setTemplateId(TemplateId);     
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );    
    }
    
    private void setIntendedContacts(){
        List<OpportunityContactRole> contactRoles = [select ContactId, 
                                                         Role, 
                                                         IsPrimary  
                                                     from OpportunityContactRole     
                                                     where OpportunityId = :pt.Opportunity__c and IsDeleted = false];
        boolean EmailBounced = false;
        string BouncedReason = null;
        if(contactRoles != null && contactRoles.size()>0){
            for( OpportunityContactRole cr : contactRoles  ){
                String contactQuery = 'select Id, salutation,firstName, lastname, Name, Phone, Email, mailingStreet, MailingCity, MailingPostalCode, EmailBouncedDate, EmailBouncedReason from Contact where Id = \''+cr.ContactId+'\' limit 1';
                List<Contact> contactList =  Database.query(contactQuery);
                if(contactList != null && contactList.size() > 0){
                    if(cr.IsPrimary){
                        primaryContact = contactList[0];
                    }
                    if(cr.Role == PLZTool_Basis.contactRoleInsured){
                        insuredPerson = contactList[0];                    
                    }               
                    if(cr.Role == PLZTool_Basis.contactRoleContact){
                        contactPerson = contactList[0];
                    } 
                    if(cr.Role == PLZTool_Basis.contactRoleSame){
                        insuredPerson = contactList[0];
                        contactPerson = contactList[0];
                    }
                    if(contactList[0].EmailBouncedDate != null) {
                        EmailBounced = true;
                        BouncedReason = contactList[0].EmailBouncedReason;
                    }
                } 
            }
            if(insuredPerson == null) {
                 insuredPerson = contactPerson;
            }
            if(primaryContact == null){
                throw new ApplicationException(PLZTool_Basis.noPrimaryContact);
            }
            // AM 2016.09.05
            if(EmailBounced) {
                if(BouncedReason != null ) {
                    throw new ApplicationException('Dieser Ansprechpartner hat eine fehlerhafte Email-Adresse. ' + BouncedReason + ' <span class="btn" onclick="GoBackToContact()"> Ok </span>');
                }
                else {
                    throw new ApplicationException(PLZTool_Basis.emailNotValid);
                    //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, PLZTool_Basis.emailNotValid));
                }
            }
            
        }else{
            throw new ApplicationException('No contact role is defined for the opportunity! ');
        }
    }
    
    public String getFormattedString(String s){
        // replaces < and > with ( and ) because of security issues (e.g. injection)
        if(s !=null && s != ''){
            return '<br/>Kommentar:<br>' + s.replaceAll('<','(').replaceAll('>',')').replaceAll('\n','<br/>')+ '<br/>';
        }else{
            return ' ';
        }
    }

    public void setCurrentUser(){
        List<User> uList = [select Id, Name, Title, phone, email from User where Id = :UserInfo.getUserId() limit 1];
        if(uList != null && uList .size()>0){
            currentUser = uList [0];
        }   
    }
        
    public String setUserfields(String str){
        if(currentUser  != null){
            if(UserInfo.getName()!= null) { str = str.replace('{!User.Name}', UserInfo.getName() ); }else{str = str.replace('{!User.Name}', ' ');}
            if(currentUser.Title!= null) { str = str.replace('{!User.Title}', currentUser.Title );}else{str = str.replace('{!User.Title}', ' ' );}
            if(currentUser.phone!= null) { str = str.replace('{!User.Phone}', currentUser.phone );}else{str = str.replace('{!User.Phone}', ' ');}
            if(UserInfo.getUserEmail()!= null) { str = str.replace('{!User.Email}', UserInfo.getUserEmail() );}else{str = str.replace('{!User.Email}', ' ' );}
        }
        return str;
    }
    
    public class applicationException extends Exception{}
}