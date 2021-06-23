/********************************************************************************************************************************************
//  Erstellt 20.12.2016 von MZ
//                      Klose und Srocke Gesellschaft für kreative KonfliktlÃ¶sungen mbH
//                      Mindelweg 11
//                      22393 Hamburg 
//                      Tel.:  04064917161
//                      Fax.: 04064917162
//                      Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter: opportunityId
//
//********************************************************************************************************************************************
//
//  Beschreibung: 
//      to separate the functionalities which are specific for "Betreuungsleistungen" recordType in PLZ_Tool  
//      send email on page load if opportunity.Pflegedienst is True
//
//********************************************************************************************************************************************
//  Änderungen:
//    13.02.2017    MZ    get email reciever address and cc from custom setting "Status Emails erhalten"."Email an PWE TEAM (BEL)"
//    05.07.2017    MZ    nullPointerException in sending email when ContactPerson is null is resolved
//********************************************************************************************************************************************
*/

public class PLZTool_Betreuungsleistungen{

    private static String retPage_BelPflegedienst = '/apex/PLZTool_BelPflegedienstPage';
    private static String retPage_lead = '/apex/Notification_Leads_anzeigen';
    
    private Opportunity opp;
    private Contact contactPerson;
    private Contact insuredPerson;
    
    private static String emailTemplateName = 'PlzToolAgents_PWE_Mail';
    
    private String tblEnd = plzEmailTagsGenerator.tblEnd ;
    private String tdEnd = plzEmailTagsGenerator.tdEnd ;
    private String tr = plzEmailTagsGenerator.tr ;
    private String trEnd = plzEmailTagsGenerator.trEnd ;
        
    private String tblCustomer = plzEmailTagsGenerator.tblCustomer ;
    private String tdCustomerTitle = plzEmailTagsGenerator.tdCustomerTitle ;
    private String tdCustomerValue = plzEmailTagsGenerator.tdCustomerValue ;

    private String tblOpp = plzEmailTagsGenerator.tblOpp ;
    private String tdOppTitle = plzEmailTagsGenerator.tdOppTitle ;
    private String tdOppValue = plzEmailTagsGenerator.tdOppValue ;
    
    public PLZTool_Betreuungsleistungen() {
         Id oppId = ApexPages.currentPage().getParameters().get('id');
         setOpportunity (oppId); 
    }
    
    public PLZTool_Betreuungsleistungen(Id oppId) {
        setOpportunity (oppId); 
    }
    
    private void setOpportunity (Id opportunityId){
        List<Opportunity> oppList = [select Id,
                                        Name, 
                                        StageName,
                                        Pflegedienst__c,
                                        X24h_Betreuung__c,
                                        Stundenweise_Betreuung__c, 
                                        Hauswirtschaftsleistungen__c,
                                        Bezugspunkt_der_PLZ_Suche__c,
                                        Alternative_Postleitzahl__c,
                                        Description 
                                        from Opportunity 
                                        where Id = :opportunityId limit 1];
        if(oppList != null && oppList.size()>0){
            opp = oppList [0];
        }
    }
    
    public PageReference mainAction(){
        if(opp .Pflegedienst__c == false &&
           opp .X24h_Betreuung__c == false &&
           opp .Stundenweise_Betreuung__c == false &&
           opp .Hauswirtschaftsleistungen__c == false
        ){
            return null;
        }
        Boolean emailSent = False;
        if(opp .Pflegedienst__c == True){
            if(setPerson()){
                sendEmailOnPageLoad();
                emailSent = True;
            }else{
                System.debug('the opportunity has no contact role !');
                throw new applicationException('Hat die Opportunity keine Kontaktrolle! Email hat nicht gesendet.');
            }
        }
        if(opp .X24h_Betreuung__c == true ||
           opp .Stundenweise_Betreuung__c == true ||
           opp .Hauswirtschaftsleistungen__c == true)
        {
            return null;
        }
        if(emailSent){
            updateOpportunity();
        }
        PageReference returnPage = new PageReference( retPage_BelPflegedienst + '?id=' + opp.Id );
        returnPage.setRedirect(true);
        return returnPage;
        
    }
    
    public Boolean setPerson(){
        List<OpportunityContactRole> contactRoles = [select ContactId, Role, IsPrimary  from OpportunityContactRole where OpportunityId = :opp.Id and IsDeleted = false];
        if(contactRoles != null && contactRoles.size()>0){
            for( OpportunityContactRole cr : contactRoles  ){
                String contactQuery = 'select Id, salutation, Name, Phone, MobilePhone, Email, mailingStreet, MailingCity, MailingPostalCode, Pflegegrad__c, Pflegestufe__c, Birthdate from Contact where Id = \''+cr.ContactId+'\' limit 1';
                List<Contact> contactList =  Database.query(contactQuery);
                if(contactList != null && contactList.size() > 0){
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
                }
            }
            return True;
        }
        return False;
    }
    
    public void sendEmailOnPageLoad(){
        List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = :emailTemplateName limit 1];
        
        EmailTemplate et = new EmailTEmplate();
        if(etList != null && etList.size() > 0){
            et = etList[0];
            
        }else{
            System.debug('error in sendEmailOnPageLoad :: Mansi:::: template not found :: '+ emailTemplateName );
            throw new applicationException('Email hat nicht gesendet! Email template not found! Please check the availability of the email template where DeveloperName = ' + emailTemplateName);
            return;
        }
        if(!et.isActive){
            System.debug('error in sendEmailOnPageLoad:: Mansi:::: template is not active');
            throw new applicationException ('Email hat nicht gesendet! Required email template is not active! Please check the availability of the email template where DeveloperName = ' + emailTemplateName);
            return;
        }
        
        String htmlValue =  et.HtmlValue;
        
        String customerTag = '<br/> Ansprechpartner(in) <br/>';
        if(contactPerson != null){
            customerTag  += generateCustomerTag(PLZTool_Basis.contactRoleContact, contactPerson);
        }
        
        if(insuredPerson != null && (contactPerson == null || insuredPerson.Id != contactPerson.Id) ){
            customerTag += '<br/> Pflegebedürftigen(r) <br/>';
            customerTag += generateCustomerTag(PLZTool_Basis.contactRoleInsured, insuredPerson);
        }
        htmlValue = htmlValue.replace('<table id="tblCustomer"/>', customerTag );
        
        htmlValue = htmlValue.replace('<table id="tblOpportunity"/>', generateOpportunityTag());
        
        htmlValue = setUserfields(htmlValue);
        
        Status_Emails__c se = Status_Emails__c.getValues('Email an PWE TEAM (BEL)');
        String[] adr = new String[]{};
        String[] cc = new String[]{};
        
        if(se != null){
            String toAddress = se.Empf_nger_Email_Adresse__c;
            if(toAddress == null){
                System.debug('error in sendEmailOnPageLoad:: Mansi:::: Empfänger Email Adresse ist null');
                throw new applicationException ('Empfänger Email Adresse is null! Please check the value in Status_Emails_erhalten custom setting');
                return;
            }
            adr.add(toAddress);
            String toCC = se.Empf_nger_Email_Adresse_CC__c;
            if(toCC != null){
                if(toCC.contains(',')){
                    cc = toCC.split(',');
                }
                else if(toCC.contains(';')){
                    cc = toCC.split(';');
                }
                else{
                    cc.add(toCC);
                }
            }
        }
        futureSendEmailToPWE(htmlValue, et.body, et.Subject, opp.Id, adr, cc);
    }
    
    public String generateCustomerTag(String contactRole, Contact prs){        
        String htmlTag = plzEmailTagsGenerator.tblCustomer ;
            
        htmlTag += tr;
        if(prs.salutation != null)
            htmlTag += tdCustomerTitle + 'Anrede' + tdEnd + tdCustomerValue + prs.salutation + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Anrede' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd; 
        
        htmlTag += tr;
        htmlTag += tdCustomerTitle + 'Name' + tdEnd + tdCustomerValue + prs.Name + tdEnd;
        htmlTag += trEnd;
        
        if( contactRole == PLZTool_Basis.contactRoleInsured ){
            htmlTag += tr;
            if(prs.Pflegegrad__c != null)
                htmlTag += tdCustomerTitle + 'Pflegegrad' + tdEnd + tdCustomerValue + prs.Pflegegrad__c + tdEnd;
            else
                htmlTag += tdCustomerTitle + 'Pflegegrad' + tdEnd + tdCustomerValue + '-' + tdEnd;
            htmlTag += trEnd;
            
            htmlTag += tr;
            if(prs.Pflegestufe__c != null)
                htmlTag += tdCustomerTitle + 'Pflegestufe' + tdEnd + tdCustomerValue + prs.Pflegestufe__c + tdEnd;
            else
                htmlTag += tdCustomerTitle + 'Pflegestufe' + tdEnd + tdCustomerValue + '-' + tdEnd;
            htmlTag += trEnd;
            
            htmlTag += tr;
            if(prs.Birthdate!= null)
                htmlTag += tdCustomerTitle + 'Geburtsdatum' + tdEnd + tdCustomerValue + prs.Birthdate+ tdEnd;
            else
                htmlTag += tdCustomerTitle + 'Geburtsdatum' + tdEnd + tdCustomerValue + '-' + tdEnd;
            htmlTag += trEnd;
        }
        
        htmlTag += tr;
        if(prs.mailingStreet != null)
            htmlTag += tdCustomerTitle + 'Strasse' + tdEnd + tdCustomerValue + prs.mailingStreet+ tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Strasse' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;        
        
        htmlTag += tr;
        if(prs.MailingPostalCode != null || prs.MailingCity != null)
            htmlTag += tdCustomerTitle + 'PLZ Ort' + tdEnd + tdCustomerValue + prs.MailingPostalCode + ' ' + prs.MailingCity + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'PLZ Ort' + tdEnd + tdCustomerValue + ' ' + tdEnd;
        htmlTag += trEnd;    

        htmlTag += tr;
        if(prs.Phone != null)
            htmlTag += tdCustomerTitle + 'Telefon' + tdEnd + tdCustomerValue + prs.Phone + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Telefon' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        if( contactRole == PLZTool_Basis.contactRoleContact ){
            htmlTag += tr;
            if(prs.MobilePhone != null)
                htmlTag += tdCustomerTitle + 'Mobiltelefon' + tdEnd + tdCustomerValue + prs.MobilePhone + tdEnd;
            else
                htmlTag += tdCustomerTitle + 'Mobiltelefon' + tdEnd + tdCustomerValue + '-' + tdEnd;
            htmlTag += trEnd;
        }
        
        htmlTag += tr;
        if(prs.Email != null)
            htmlTag += tdCustomerTitle + 'Email' + tdEnd + tdCustomerValue + prs.Email+ tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Email' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;
     
        htmlTag += tblEnd; 
          
        return htmlTag;
    }
    
    public String generateCustomerPlainText(String contactRole, Contact prs){        
        String htmlTag ='';
        String newLine = '\n';
        String tabSpace = '\t';
            
        htmlTag += newLine;
        if(prs.salutation != null)
            htmlTag += 'Anrede' + tabSpace + prs.salutation ;
        else
            htmlTag += 'Anrede' + tdEnd + '-';
        htmlTag += newLine; 
        
        htmlTag += newLine;
        htmlTag += tdCustomerTitle + 'Name' + tdEnd + tdCustomerValue + prs.Name + tdEnd;
        htmlTag += newLine;
        
        if( contactRole == PLZTool_Basis.contactRoleInsured ){
            htmlTag += newLine;
            if(prs.Pflegegrad__c != null)
                htmlTag += tdCustomerTitle + 'Pflegegrad' + tdEnd + tdCustomerValue + prs.Pflegegrad__c + tdEnd;
            else
                htmlTag += tdCustomerTitle + 'Pflegegrad' + tdEnd + tdCustomerValue + '-' + tdEnd;
            htmlTag += newLine;
            
            htmlTag += newLine;
            if(prs.Pflegestufe__c != null)
                htmlTag += tdCustomerTitle + 'Pflegestufe' + tdEnd + tdCustomerValue + prs.Pflegestufe__c + tdEnd;
            else
                htmlTag += tdCustomerTitle + 'Pflegestufe' + tdEnd + tdCustomerValue + '-' + tdEnd;
            htmlTag += newLine;
            
            htmlTag += newLine;
            if(prs.Birthdate!= null)
                htmlTag += tdCustomerTitle + 'Geburtsdatum' + tdEnd + tdCustomerValue + prs.Birthdate+ tdEnd;
            else
                htmlTag += tdCustomerTitle + 'Geburtsdatum' + tdEnd + tdCustomerValue + '-' + tdEnd;
            htmlTag += newLine;
        }
        
        htmlTag += newLine;
        if(prs.mailingStreet != null)
            htmlTag += tdCustomerTitle + 'Strasse' + tdEnd + tdCustomerValue + prs.mailingStreet+ tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Strasse' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += newLine;        
        
        htmlTag += newLine;
        if(prs.MailingPostalCode != null || prs.MailingCity != null)
            htmlTag += tdCustomerTitle + 'PLZ Ort' + tdEnd + tdCustomerValue + prs.MailingPostalCode + ' ' + prs.MailingCity + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'PLZ Ort' + tdEnd + tdCustomerValue + ' ' + tdEnd;
        htmlTag += newLine;    

        htmlTag += newLine;
        if(prs.Phone != null)
            htmlTag += tdCustomerTitle + 'Telefon' + tdEnd + tdCustomerValue + prs.Phone + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Telefon' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += newLine;
        
        if( contactRole == PLZTool_Basis.contactRoleContact ){
            htmlTag += newLine;
            if(prs.MobilePhone != null)
                htmlTag += tdCustomerTitle + 'Mobiltelefon' + tdEnd + tdCustomerValue + prs.MobilePhone + tdEnd;
            else
                htmlTag += tdCustomerTitle + 'Mobiltelefon' + tdEnd + tdCustomerValue + '-' + tdEnd;
            htmlTag += newLine;
        }
        
        htmlTag += newLine;
        if(prs.Email != null)
            htmlTag += 'Email' + tdEnd + tdCustomerValue + prs.Email+ tdEnd;
        else
            htmlTag += 'Email' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += newLine;
     
          
        return htmlTag;
    }

    private String generateOpportunityTag(){
        String htmlTag = tblOpp ;
        htmlTag += tr;
        if(opp.Bezugspunkt_der_PLZ_Suche__c != null)
            htmlTag += tdOppTitle + 'Bezugspunkt der PLZ Suche' + tdEnd + tdOppValue + opp.Bezugspunkt_der_PLZ_Suche__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Bezugspunkt der PLZ Suche' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
    
        htmlTag += tr;
        if(opp.Alternative_Postleitzahl__c != null)
            htmlTag += tdOppTitle + 'Angefragte PLZ' + tdEnd + tdOppValue + opp.Alternative_Postleitzahl__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Angefragte PLZ' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
            
        htmlTag += tr;
        if(opp.Description != null)
            htmlTag += tdOppTitle + 'Besonderheiten' + tdEnd + tdOppValue + opp.Description + tdEnd;
        else
            htmlTag += tdOppTitle + 'Besonderheiten' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        String link = '<a href="http://'+ApexPages.currentPage().getHeaders().get('Host')+ '/' + opp.Id +'">' + opp.Name + '</a>';
        htmlTag += tdOppTitle + 'Ursprung' + tdEnd + tdOppValue + link + tdEnd;
        htmlTag += trEnd;
        
        String Leistungen = '';
        if(opp .X24h_Betreuung__c == true ) {
            Leistungen += '24h Betreuung';
        }
        if(opp .Stundenweise_Betreuung__c == true){
            if( Leistungen != ''){
                Leistungen += ', ';
            }
            Leistungen += 'Stundenweise Betreuung';
        }
        if(opp .Hauswirtschaftsleistungen__c == true){
            if( Leistungen != ''){
                Leistungen += ', ';
            }
            Leistungen += 'Hauswirtschaftsleistungen';
        }
        
        if(Leistungen != ''){
            htmlTag += tr;
            htmlTag += tdOppTitle + 'Zusaetzliche Leistungen' + tdEnd + tdOppValue + Leistungen + tdEnd;
            htmlTag += trEnd;
        }
        
        htmlTag += tblEnd;
        return htmlTag;
    }
    
    @future(callout=true)
    public static void futureSendEmailToPWE(String htmlValue, String plainTextBody, string subject, id WhatId, String[] adr, String[] cc ){   
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(htmlValue);
        mail.setPlainTextBody(plainTextBody);
        mail.setSubject(subject);
        mail.setWhatId(WhatId);
        mail.setToAddresses(adr);
        mail.setCCAddresses(cc);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );    
    }
    
    public String setUserfields(String str){
        User currentUser;
        List<User> uList = [select Id, Name, Title, phone, email from User where Id = :UserInfo.getUserId() limit 1];
        if(uList != null && uList .size()>0){
            currentUser = uList [0];
            if(UserInfo.getName()!= null) { str = str.replace('{!User.Name}', UserInfo.getName() ); }else{str = str.replace('{!User.Name}', ' ');}
            if(currentUser.Title!= null) { str = str.replace('{!User.Title}', currentUser.Title );}else{str = str.replace('{!User.Title}', ' ' );}
            if(currentUser.phone!= null) { str = str.replace('{!User.Phone}', currentUser.phone );}else{str = str.replace('{!User.Phone}', ' ');}
            if(UserInfo.getUserEmail()!= null) { str = str.replace('{!User.Email}', UserInfo.getUserEmail() );}else{str = str.replace('{!User.Email}', ' ' );}
        }   
        return str;
    }
    
    private void updateOpportunity(){
         opp.StageName =  PLZTool_Basis.oppStatusErfolg ;
         update opp;
    }
    
    public class applicationException extends Exception{}
    
    public PageReference toOpportunity(){
        PageReference returnPage = new PageReference('/' + opp.Id );
        returnPage.setRedirect(true);
        return returnPage;
    }
    
    public PageReference toLeads(){
        PageReference returnPage = new PageReference( retPage_lead );
        returnPage.setRedirect(true);
        return returnPage;
    }

}