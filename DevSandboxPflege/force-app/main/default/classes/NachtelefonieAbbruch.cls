/****************************************************************************************************************************
// Erstellt 15.10.2016 von MZ
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
// Nachtelefonie__c.id
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//    notice that public string values are used in trigger "sendEmailOnAbbruchgerundEdit" and "AbbruchOnAbbruchgerundEdit"
//****************************************************************************************************************************
// Änderungen:
//  17.11.2016    AM    #134428327
//  19.12.2016    MZ    #135762243    nur die Abbruchgründe des jeweiligen Recordtypes dargestellt werden.
//  09.01.2017    MZ    #134960689
//  23.01.2017    MZ    Do not send email for the status "Auslandsanfrage" or "Job Anfrage" because of the trigger sendEmailOnAbbruchgerundEdit
//  12.06.2017    MZ    hide the ctegory line from visualforce page for selfmailer
//  14.06.2017    MZ    add 'Abbruchgruende' for 'Notrufsysteme'
//  24.06.2017    MZ    add 'Abbruchgruende' for 'Widerspruch'
//  26.07.2017    BT    add 'Abbruchgruende' for 'Pflegeimmobilien'
//  18.08.2017    MZ    notification to TeamLead is disabled for limited time
//  23.08.2017    MZ    new canceling reason added for TL
//  25.10.2017    MZ    case 00001312 - plain text body of email changed to match html body.
//  16.11.2017    MZ    #152709934 specific template for PI added
//  22.05.2017    MZ    #157306557 new canceling reasons
//  24.07.2018    MZ    00001549 kat 2 removed for Badumbau
//  26.07.2018    MZ    badumbau email template added.
//  27.09.2018    MZ    #159987135 Badumbau - NT Abbruch logic
//  19.11.2020    DZ    New: "Aufschub wegen Corona"
//  27.04.2021    DZ    New "Reine Preisanfrage" for Recordtype Treppenlift
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public class NachtelefonieAbbruch{

    private static String selectOne = 'Please select one of the options!';
    private static String ownerError = 'Zur Weiterverarbeitung musst du Inhaber des Datensatzes sein';
    private static String warningMsg = 'Es wurden weniger als 6 Versuche unternommen den Interessenten zu erreichen, soll die Nachtelefonie wirklich geschlossen bzw. in Kategorie 2 verschoben werden? <span class="btn" onclick="saveNachtelefonie()"> Ja</span> <span class="btn" onclick="uncheckKat2()"> Nein </span>';
    
    private static String abbruchgerundAspNichtErreichbar = 'ASP nicht erreichbar';
    private static String abbruchgerundFehlerhafteKontaktdaten = 'Fehlerhafte Kontaktdaten - Kontakt nicht möglich';
    public  static String abbruchgerundAuslandsanfrage = 'Auslandsanfrage';
    public  static String abbruchgerundJobAnfrage = 'Job Anfrage';
    
    private static string status_kat2 = 'Offen - Kat. 2';
    private static string status_abbruch = 'Abbruch';
    private static string status_selfmailer = 'Selfmailer nachtelefonieren';
    private static string PWE_standard_user = 'PWE Standardbenutzer';
    private static string ZWB_standard_user = 'ZWB Standardbenutzer';

    public static string status_opp_abbruch = 'Abbruch';
    public static string status_opp_kat2 = 'Wiedervorlage Kat. 2';
    
    public static String defaultEmailTemplate = 'Nachtelefonie_cancel_customer';
    public static String auslandAnfrageEmailTemplate = 'Nachtelefonie_cancel_AUSLAND_ANFRAGE';
    public static String jobAnfrageEmailTemplate = 'Nachtelefonie_cancel_JOB_ANFRAGE';
    public static String defaultEmailTemplate_PI = 'Nachtelefonie_cancel_customer_PI';
    public static String defaultEmailTemplate_Badumbau = 'Kunde_mehrfach_nicht_erreicht';
    
    public Boolean isOwner = False;
    public string abbruchGrund{set;get;}
    public Boolean cat2Checkbox{set;get;}  
    public Boolean showCat2Checkbox{set;get;} 
    
    private Id nachtelefonieId;


    public Nachtelefonie__c formObj = new Nachtelefonie__c();

public NachtelefonieAbbruch(){
    nachtelefonieId = ApexPages.currentPage().getParameters().get('id');
    isOwner(nachtelefonieId);
    
    showCat2Checkbox = true;
    
    Nachtelefonie__c[] nList = [ select Id, 
                                Name, 
                                Opportunity__c, 
                                Status__c, 
                                F_lligkeitsdatum__c, 
                                Anzahl_der_Versuche__c, 
                                Abbruchgrund__c, 
                                recordTypeId, 
                                recordType.name, 
                                Opportunity__r.recordType.name,
                                NT_Badumbau_Type__c
                                from Nachtelefonie__c 
                                where Id = :nachtelefonieId limit 1];
    if(nList!= null && nList .size()>0){
        formObj = nList[0];
        if(formObj.Status__c == status_selfmailer){
            showCat2Checkbox = false;
        } 
        if(formObj.recordType.name == 'Badumbau'){
            showCat2Checkbox = false;
        }
    }else{
        System.debug('error in PNachtelefonie !!! ::: no Nachtelefonie found with Id: ' + this.nachtelefonieId );
    }
    
}

public List<SelectOption> getItems() {

    List<SelectOption> options = new List<SelectOption>();
        
    /*Schema.DescribeFieldResult fieldResult = Nachtelefonie__c.Abbruchgrund__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    options.add(new SelectOption('--None--', '--None--'));     
    for(Schema.PicklistEntry f : ple)
    {
       options.add(new SelectOption(f.getValue(), f.getLabel()));
    } */
    if(formObj.recordType.name == 'Treppenlift'){
        options.add(new SelectOption('Nur Beratung - wünscht kein Infomaterial', 'Nur Beratung - wünscht kein Infomaterial'));
        options.add(new SelectOption(abbruchgerundAspNichtErreichbar , abbruchgerundAspNichtErreichbar ));
        options.add(new SelectOption(abbruchgerundFehlerhafteKontaktdaten , abbruchgerundFehlerhafteKontaktdaten ));
        options.add(new SelectOption('Zu teuer / zu geringes Budget - Zuschüsse nicht ausreichend', 'Zu teuer / zu geringes Budget - Zuschüsse nicht ausreichend'));
        options.add(new SelectOption('Möchte direkt Kontakt mit Anbieter - nicht über pflege.de', 'Möchte direkt Kontakt mit Anbieter - nicht über pflege.de'));
        options.add(new SelectOption(abbruchgerundAuslandsanfrage , abbruchgerundAuslandsanfrage ));
        options.add(new SelectOption('ASP hat selber nicht angefragt und wusste von nichts', 'ASP hat selber nicht angefragt und wusste von nichts'));
        options.add(new SelectOption('Vermieter nicht einverstanden', 'Vermieter nicht einverstanden'));
        options.add(new SelectOption('Mehrfamilienhaus mit zu geringer Treppenbreite', 'Mehrfamilienhaus mit zu geringer Treppenbreite'));
        options.add(new SelectOption('PB verstorben', 'PB verstorben'));
        options.add(new SelectOption('Kein Bedarf mehr, Wohnsituation geändert', 'Kein Bedarf mehr, Wohnsituation geändert'));
        options.add(new SelectOption('Kontakt zu spät - ASP hat schon Angebote', 'Kontakt zu spät - ASP hat schon Angebote'));
        options.add(new SelectOption('PB akzeptiert Bedarf nicht', 'PB akzeptiert Bedarf nicht'));
        options.add(new SelectOption('Bedarf erst in mehreren Jahren', 'Bedarf erst in mehreren Jahren'));
        options.add(new SelectOption('Dopplung', 'Dopplung'));
        options.add(new SelectOption('Ausschuss', 'Ausschuss'));
        options.add(new SelectOption('Absage per Mail/Sprachnachricht - Grund nicht ermittelbar', 'Absage per Mail/Sprachnachricht - Grund nicht ermittelbar'));
        options.add(new SelectOption('mit Vor Ort Termin nicht einverstanden', 'mit Vor Ort Termin nicht einverstanden'));
        options.add(new SelectOption('keine Partner', 'keine Partner'));
        options.add(new SelectOption('Kunde wünscht keine telefonische Beratung', 'Kunde wünscht keine telefonische Beratung'));
        options.add(new SelectOption('Aufschub wegen Corona', 'Aufschub wegen Corona'));
        options.add(new SelectOption('Reine Preisanfrage', 'Reine Preisanfrage'));
            
    }
    if(formObj.recordType.name == 'Betreuungsleistungen'){
        options.add(new SelectOption('Nur Beratung - wünscht kein Infomaterial', 'Nur Beratung - wünscht kein Infomaterial'));
        options.add(new SelectOption(abbruchgerundAspNichtErreichbar , abbruchgerundAspNichtErreichbar ));
        options.add(new SelectOption(abbruchgerundFehlerhafteKontaktdaten , abbruchgerundFehlerhafteKontaktdaten ));
        options.add(new SelectOption('Zu teuer / zu geringes Budget - Zuschüsse nicht ausreichend', 'Zu teuer / zu geringes Budget - Zuschüsse nicht ausreichend'));
        options.add(new SelectOption(abbruchgerundAuslandsanfrage , abbruchgerundAuslandsanfrage ));
        options.add(new SelectOption('ASP hat selber nicht angefragt und wusste von nichts', 'ASP hat selber nicht angefragt und wusste von nichts'));
        options.add(new SelectOption('PB verstorben', 'PB verstorben'));
        options.add(new SelectOption('Kontakt zu spät - ASP hat schon Angebote', 'Kontakt zu spät - ASP hat schon Angebote'));
        options.add(new SelectOption('PB akzeptiert Bedarf nicht', 'PB akzeptiert Bedarf nicht'));
        options.add(new SelectOption('Bedarf erst in mehreren Jahren', 'Bedarf erst in mehreren Jahren'));
        options.add(new SelectOption('Dopplung', 'Dopplung'));
        options.add(new SelectOption('Ausschuss', 'Ausschuss'));
        options.add(new SelectOption('Absage per Mail/Sprachnachricht - Grund nicht ermittelbar', 'Absage per Mail/Sprachnachricht - Grund nicht ermittelbar'));
        options.add(new SelectOption('AD oder Intensivpflege gewünscht', 'AD oder Intensivpflege gewünscht'));
        options.add(new SelectOption('Keine Unterbringung möglich', 'Keine Unterbringung möglich'));
        options.add(new SelectOption('Bedarf wird familiär gelöst', 'Bedarf wird familiär gelöst'));
        options.add(new SelectOption('Nicht abgeschickte Anfrage – keine Beratung erwünscht', 'Nicht abgeschickte Anfrage – keine Beratung erwünscht'));
        options.add(new SelectOption('Leistung gewünscht, die nicht angeboten wird', 'Leistung gewünscht, die nicht angeboten wird'));       
        options.add(new SelectOption('Job Anfrage', 'Job Anfrage'));       
        options.add(new SelectOption('keine Partner', 'keine Partner'));
        options.add(new SelectOption('Kunde wünscht keine telefonische Beratung', 'Kunde wünscht keine telefonische Beratung'));
        options.add(new SelectOption('Aufschub wegen Corona', 'Aufschub wegen Corona'));
    
    }
    if(formObj.recordType.name == 'Notrufsysteme'){
        options.add(new SelectOption('Absage per Mail/Sprachnachricht - Grund nicht ermittelbar', 'Absage per Mail/Sprachnachricht - Grund nicht ermittelbar'));
        options.add(new SelectOption('Anbieter wurde schon kontaktiert, da pflege.de zu spät', 'Anbieter wurde schon kontaktiert, da pflege.de zu spät'));
        options.add(new SelectOption('Anbieter wurde vor pflege.de kontaktiert, kein Vergleichsangebot gewünscht', 'Anbieter wurde vor pflege.de kontaktiert, kein Vergleichsangebot gewünscht'));
        options.add(new SelectOption('ASP hat selber nicht angefragt und wusste von nichts', 'ASP hat selber nicht angefragt und wusste von nichts'));
        options.add(new SelectOption(abbruchgerundAspNichtErreichbar , abbruchgerundAspNichtErreichbar ));
        options.add(new SelectOption(abbruchgerundAuslandsanfrage , abbruchgerundAuslandsanfrage ));
        options.add(new SelectOption('Ausschuss', 'Ausschuss'));
        options.add(new SelectOption('Dopplung', 'Dopplung'));
        options.add(new SelectOption(abbruchgerundFehlerhafteKontaktdaten , abbruchgerundFehlerhafteKontaktdaten ));
        options.add(new SelectOption('Gesprächsabbruch', 'Gesprächsabbruch'));
        options.add(new SelectOption('Hat bereits einen HNR - Preisauskunft gewünscht', 'Hat bereits einen HNR - Preisauskunft gewünscht'));
        options.add(new SelectOption('Zu teuer / zu geringes Budget - Zuschüsse nicht ausreichend', 'Zu teuer / zu geringes Budget - Zuschüsse nicht ausreichend'));
        options.add(new SelectOption('Möchte direkt Kontakt mit Anbieter - nicht über pflege.de', 'Möchte direkt Kontakt mit Anbieter - nicht über pflege.de'));
        options.add(new SelectOption('Nicht abgeschickte Anfrage – keine Beratung erwünscht', 'Nicht abgeschickte Anfrage – keine Beratung erwünscht'));
        options.add(new SelectOption('Nur Beratung - wünscht kein Infomaterial', 'Nur Beratung - wünscht kein Infomaterial'));
        options.add(new SelectOption('PB akzeptiert Bedarf nicht', 'PB akzeptiert Bedarf nicht'));
        options.add(new SelectOption('PB verstorben', 'PB verstorben'));
        options.add(new SelectOption('Kontakt zu spät - ASP hat schon Angebote', 'Kontakt zu spät - ASP hat schon Angebote'));
        options.add(new SelectOption('Kein Bedarf mehr, Wohnsituation geändert', 'Kein Bedarf mehr, Wohnsituation geändert'));
        options.add(new SelectOption('PB verstorben', 'PB verstorben'));
        options.add(new SelectOption('keine Partner', 'keine Partner'));
        options.add(new SelectOption('Kunde wünscht keine telefonische Beratung', 'Kunde wünscht keine telefonische Beratung'));
        options.add(new SelectOption('Aufschub wegen Corona', 'Aufschub wegen Corona'));
        }
    if(formObj.recordType.name == 'Widerspruch'){
        options.add(new SelectOption(abbruchgerundAspNichtErreichbar , abbruchgerundAspNichtErreichbar ));
        options.add(new SelectOption(abbruchgerundAuslandsanfrage , abbruchgerundAuslandsanfrage ));
        options.add(new SelectOption(abbruchgerundFehlerhafteKontaktdaten , abbruchgerundFehlerhafteKontaktdaten ));
        options.add(new SelectOption('Ausschuss', 'Ausschuss'));
        options.add(new SelectOption('Dopplung', 'Dopplung'));
        options.add(new SelectOption('Nicht abgeschickte Anfrage – keine Beratung erwünscht', 'Nicht abgeschickte Anfrage – keine Beratung erwünscht'));
        options.add(new SelectOption('Monetarisierung abgelehnt', 'Monetarisierung abgelehnt'));
        options.add(new SelectOption('Kein Potenzial', 'Kein Potenzial'));
        options.add(new SelectOption('Anderweitig Informationen eingeholt', 'Anderweitig Informationen eingeholt'));
        options.add(new SelectOption('Aufschub wegen Corona', 'Aufschub wegen Corona'));
    }
    if(formObj.recordType.name == 'Pflegeimmobilien'){
        options.add(new SelectOption('Betreutes Wohnen als Anlagenmöglichkeit', 'Betreutes Wohnen als Anlagenmöglichkeit'));
        options.add(new SelectOption('Betreutes Wohnen zum Eigennutz', 'Betreutes Wohnen zum Eigennutz'));
        options.add(new SelectOption('Altersgerechtes Wohnen/Eigentumswohnung als Anlagemöglichkeit', 'Altersgerechtes Wohnen/Eigentumswohnung als Anlagemöglichkeit'));
        options.add(new SelectOption('Altersgerechtes Wohnen/Eigentumswohnung zum Eigennutz', 'Altersgerechtes Wohnen/Eigentumswohnung zum Eigennutz'));
        options.add(new SelectOption('Barzahlung: Budget kleiner 100.000 €', 'Barzahlung: Budget kleiner 100.000 €'));
        options.add(new SelectOption('Finanzierung: Budget kleiner 10.000 €', 'Finanzierung: Budget kleiner 10.000 €'));
        options.add(new SelectOption('Zu starke regionale Einschränkung', 'Zu starke regionale Einschränkung'));
        options.add(new SelectOption(abbruchgerundFehlerhafteKontaktdaten, abbruchgerundFehlerhafteKontaktdaten));
        options.add(new SelectOption(abbruchgerundAspNichtErreichbar, abbruchgerundAspNichtErreichbar));
        options.add(new SelectOption('Absage per Mail/Sprachnachricht – Grund nicht ermittelbar', 'Absage per Mail/Sprachnachricht – Grund nicht ermittelbar'));
        options.add(new SelectOption('Nur Beratung erwünscht, keine WL', 'Nur Beratung erwünscht, keine WL'));      
        options.add(new SelectOption('Keine Rückmeldung – Anruf untersagt', 'Keine Rückmeldung – Anruf untersagt'));
        options.add(new SelectOption('Dopplung', 'Dopplung'));
        options.add(new SelectOption('Kein Bedarf mehr', 'Kein Bedarf mehr'));
        options.add(new SelectOption('keine Partner', 'keine Partner'));
        options.add(new SelectOption('Kunde wünscht keine telefonische Beratung', 'Kunde wünscht keine telefonische Beratung'));
        options.add(new SelectOption('Aufschub wegen Corona', 'Aufschub wegen Corona'));
    }   
    if(formObj.recordType.name == 'Badumbau'){
        options.add(new SelectOption(abbruchgerundAspNichtErreichbar, abbruchgerundAspNichtErreichbar));
        options.add(new SelectOption(abbruchgerundFehlerhafteKontaktdaten, abbruchgerundFehlerhafteKontaktdaten));
        options.add(new SelectOption('Dopplung', 'Dopplung'));
        options.add(new SelectOption('Kein Bedarf mehr', 'Kein Bedarf mehr'));
        options.add(new SelectOption('Nicht abgeschickte Anfrage – keine Beratung erwünscht', 'Nicht abgeschickte Anfrage – keine Beratung erwünscht'));
        options.add(new SelectOption('Aufschub wegen Corona', 'Aufschub wegen Corona'));
    }
   
   return options;
}

public void checkAnzahlDerVersuche(){
    if( !isOwner(nachtelefonieId) ){
        return ;
    }
    if((abbruchGrund == null || abbruchGrund == '--None--') && ! cat2Checkbox){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, selectOne ));
        return ;
    } 
    if((formObj.Anzahl_der_Versuche__c < 6) && (abbruchgrund == abbruchgerundAspNichtErreichbar)){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, warningMsg));
        return ;
    }else{
        Speichern();
    }
}

public void sendEmailToCustomer(){
    Id recipientId;
    List<OpportunityContactRole> role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId = :formObj.Opportunity__c and ( Role = 'ASP' or Role = 'PB = ASP')];
    if(role_list != null && role_list.size()>0){
        recipientId = role_list[0].ContactId;
    }
    List<Contact> c_list = [select id, salutation, name, phone, LastName from contact where Id = :recipientId limit 1 ];
    Contact recipient;
    if( c_list!= null && c_list.size()>0 ){
        recipient = c_list[0];
    }
    String templateName  = defaultEmailTemplate ;
    if(formObj.Opportunity__r.recordType.name == PLZTool_Basis.rtPflegeimmobilien){
        templateName = defaultEmailTemplate_PI;
    }
    if(formObj.Opportunity__r.recordType.name == PLZTool_Basis.rtBadumbau){
        templateName = defaultEmailTemplate_Badumbau;
    }
    
    if(abbruchGrund  == abbruchgerundAuslandsanfrage){
        templateName = auslandAnfrageEmailTemplate;
    }
    if(abbruchGrund  == abbruchgerundJobAnfrage){
        templateName = jobAnfrageEmailTemplate ;
    }
    List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = :templateName  limit 1];
    EmailTemplate et = new EmailTEmplate();
    if(etList != null && etList.size() > 0){
        et = etList[0];
    }else{
        System.debug('error in sendEmailToCustomer:: Mansi:::: template not found');
        throw new applicationException ('Email template not found! Please check the availability of the email template where DeveloperName = ' + templateName  );
    }
    if(! et.isActive){
        System.debug('error in sendEmailToCustomer:: Mansi:::: template is not active');
        throw new applicationException ('Required email template is not active! Please check the availability of the email template where DeveloperName = ' + templateName  );
    }
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                      
    String htmlValue = EmailTemplateHelper.setRecipientFields(et.HtmlValue, recipient.salutation, recipient.LastName, recipient.phone );
    htmlValue = EmailTemplateHelper.setRegion(htmlValue, formObj.Opportunity__c);
    htmlValue = EmailTemplateHelper.setUserfields(htmlValue, UserInfo.getUserId());
         
    String plainTextValue = EmailTemplateHelper.setRecipientFields(et.body, recipient.salutation, recipient.LastName, recipient.phone );
    plainTextValue = EmailTemplateHelper.setRegion(plainTextValue, formObj.Opportunity__c).replaceAll('<br/>', '');
    plainTextValue = EmailTemplateHelper.setUserfields(plainTextValue, UserInfo.getUserId());
    
    mail.setHtmlBody(htmlValue);
    mail.setPlainTextBody(plainTextValue);
    mail.setSubject(et.Subject);
    mail.setTargetObjectId(recipient.id); 
    
    if(formObj.Opportunity__r.recordType.name == PLZTool_Basis.rtBadumbau){
        mail.setHtmlBody(EmailMessageTagGenerator_Badumbau.resolveMergeFields(formObj.Opportunity__c, htmlValue, UserInfo.getUserId()));
        mail.setPlainTextBody(EmailMessageTagGenerator_Badumbau.resolveMergeFields(formObj.Opportunity__c, plainTextValue, UserInfo.getUserId()));
        mail.setSubject(EmailMessageTagGenerator_Badumbau.resolveMergeFields(formObj.Opportunity__c, et.Subject, UserInfo.getUserId()));
        mail.setWhatId(formObj.Opportunity__c);
        List<OrgWideEmailAddress> orgWideAddresses = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Badumbau'];
        if(orgWideAddresses != null && orgWideAddresses.size()>0){
            mail.setOrgWideEmailAddressId(orgWideAddresses[0].Id);
            mail.setReplyTo(orgWideAddresses[0].Address);
        }
    }
    
    Messaging.SendEmailResult[] sendMailRes = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});  
    if(! sendMailRes[0].success){
        throw new applicationException('Error : could not send email! ' + sendMailRes[0]);
    }      
}

public void sendNotificationToTeamlead(){
    if( (formObj.Anzahl_der_Versuche__c < 6 && abbruchGrund  == abbruchgerundAspNichtErreichbar )
        || (formObj.Anzahl_der_Versuche__c >= 9 && cat2Checkbox)){
    String templateName = 'Nachtelefonie_Attempt_notification';
    List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = :templateName  limit 1];
    EmailTemplate et = new EmailTEmplate();
    if(etList != null && etList.size() > 0){
        et = etList[0];
    }else{
        System.debug('error in sendNotificationToTeamlead:: Mansi:::: template not found');
        throw new applicationException ('Email template not found! Please check the availability of the email template where DeveloperName = ' + templateName  );
    }
    if(! et.isActive){
        System.debug('error in sendNotificationToTeamlead:: Mansi:::: template is not active');
        throw new applicationException ('Required email template is not active! Please check the availability of the email template where DeveloperName = ' + templateName  );
    }
    String teamLeadId = null;
    String userId = UserInfo.getUserId();
    User[] userList = [select id, verantwortlicher_Teamlead__c, userRoleId, userRole.Name from user where id = :userId limit 1];
    if(userList != null && userList.size() > 0){
        teamLeadId = userList[0]. verantwortlicher_Teamlead__c;
        if(userList[0].userRole.Name == null || (userList[0].userRole.Name != PWE_standard_user && userList[0].userRole.Name != ZWB_standard_user)){
            return;
        }
    }
    if(teamLeadId == null || teamLeadId  == ''){
        System.debug('error in sendNotificationToTeamlead :: No value found for "verantwortlicher Teamlead"');
        throw new applicationException('No value found for "verantwortlicher Teamlead"! ');
    }
    
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    String htmlBody = et.HtmlValue.replace('{!Nachtelefonie__c.Name}', formObj.Name);
    htmlBody = htmlBody.replace('{!Nachtelefonie__c.Anzahl_der_Versuche__c}', String.valueof(formObj.Anzahl_der_Versuche__c));
    htmlBody = htmlBody.replace('{!User.Name}', UserInfo.getName());
    mail.setHtmlBody(htmlBody );
    mail.setPlainTextBody(htmlBody);
    mail.setSubject(et.Subject);
    mail.setSaveAsActivity(false);
    System.debug('here is your team lead id::: mansi::'+ teamLeadId );
    mail.setTargetObjectId(teamLeadId ); 
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }
}

public void kat2Selected(){
    if(cat2Checkbox){
        abbruchGrund = null;
    }
}

public void uncheckKat2(){
    cat2Checkbox = false;
}

public void grundSelected(){
    if(abbruchGrund != null && abbruchGrund != '--None--'){
        cat2Checkbox = false;
    }
}

public PageReference Speichern(){
    if( !isOwner(nachtelefonieId) ){
        return null;
    }
    try{
    // sendNotificationToTeamlead(); the line is disabled for limited time
    
    // AM 17.11.2016
    if((abbruchGrund != null) && 
       (abbruchGrund == abbruchgerundAspNichtErreichbar || 
        abbruchGrund == abbruchgerundFehlerhafteKontaktdaten
      )) {
        sendEmailToCustomer();
    }
    
    if(abbruchGrund != null && abbruchGrund != '--None--'){
        formObj.Abbruchgrund__c = abbruchGrund ;
        formObj.Status__c = status_abbruch;
        updateOpportunityStatus(status_opp_abbruch);
    }else if(cat2Checkbox){    
        abbruchGrund = null; 
        formObj.Abbruchgrund__c = null;  
        formObj.Status__c = status_kat2;
        formObj.F_lligkeitsdatum__c = null;
        updateOpportunityStatus(status_opp_kat2);
    }else{
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, selectOne ));
        return null;
    }  
        update(formObj);
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm , 'The new changes applied successfully' ));
        return zuNachtelefonie();       
    }catch(Exception e){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage() ));
        
    }
    return null;
}

public void updateOpportunityStatus(String status){
    List<Opportunity> oppList = [select id, 
                                 StageName, 
                                 Abbruchgrund__c, 
                                 first_consulting_status__c, 
                                 Angebot_Status_extern__c 
                                 from opportunity 
                                 where id = :formObj.Opportunity__c];
    Opportunity opp;
    if(oppList != null && oppList .size() > 0){
        opp = oppList [0];
    }else{
        System.debug('error in updateOpportunitystatus:: Mansi:::: opportunity not found');
        throw new applicationException ('Opportunity not found!');
    }
    
    // #159987135 for Badumabu no cancelation reason should be saved. different opportunity fields should set based on NT_Badumbau_Type__c 
    if(formObj.recordType.name == 'Badumbau'){
        if(formObj.NT_Badumbau_Type__c == 'Kontaktanbahnung'){
            opp.StageName = status_opp_abbruch;
        }else if(formObj.NT_Badumbau_Type__c == 'Erstberatung'){
            opp.first_consulting_status__c = status_opp_abbruch;
        }else if(formObj.NT_Badumbau_Type__c == 'Angebot'){
            opp.Angebot_Status_extern__c = status_opp_abbruch;
        }
    }else{
        opp.stageName = status;
        opp.Abbruchgrund__c = abbruchGrund;
    }
    
    opp.ownerId = UserInfo.getUserId();
    
    update opp;
}

public PageReference zuNachtelefonie(){
           PageReference PageRef = new PageReference('/' + formObj.Id);
           PageRef.setRedirect(true);
                      
           return PageRef;
    }
    
public boolean isOwner(Id nachtelefonieId){
        Nachtelefonie__c nc = new Nachtelefonie__c();
        List<Nachtelefonie__c> ncList =  [select Id, Owner.Id from Nachtelefonie__c where id = :nachtelefonieId limit 1];
        if(ncList != null && ncList.size()>0){
            nc = ncList [0];
            if(nc.Owner.Id != UserInfo.getUserId()){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ownerError ));
                return False;
            }
        }
        return True;
    }

public class applicationException extends Exception{}



}