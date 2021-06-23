/****************************************************************************************************************************
// Erstellt 13.03.2017 von MZ
//      Klose und Srocke Gesellschaft für kreative Konfliktlösungen GmbH
//      Mindelweg 11
//      22393 Hamburg 
//      Tel.:  04064917161
//      Fax.: 04064917162
//      Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:    controller for Selfmailer "HNR", to seprate the selfmailer methods from other hnr methods
//
//****************************************************************************************************************************
// Änderungen:
//    28.05.2017    Pdfs werden per E-Mail-Anhang versendet
//    12.06.2017    Nachtelefonie - Fälligkeitsdatum auf 4 Tage 
//      13.06.2017  Setzen whatId(opp) und TargetObjectId(customer.id) bei der email;
//****************************************************************************************************************************
*/
public class SelfmailerController{
    public static String[] PflegegradValues = new String[]{'1', '2', '3', '4', '5', 'Pflegegrad vorhanden'};
    public static String selfmailer2Fach = 'Selfmailer 2-fach';
    public static String selfmailer3Fach = 'Selfmailer 3-fach';
        
    public Boolean showSelfmailer{get; set;}
    public String layout {get; set;}
    
    public Boolean emptyFormFlag {get; set;}
    public Boolean toCustomer {get; set;}
    public Boolean toAlternative {get; set;}    
    
    public Boolean has2Fach {get; set;}
    public Boolean has3Fach {get; set;}
    public Boolean KlasBasisPaket {get; set;}
    public Boolean KlasServicePaket {get; set;}
    public Boolean ModServicePaket {get; set;}
    public Boolean ModBasisPaket {get; set;}
    public Boolean kombiPaket {get; set;}
    
    public String fach1Label {get; set;}
    public String fach2Label {get; set;}
    public String fach3Label {get; set;}
    public String fach4Label {get; set;}
    
    public Boolean hasPflegegrad {get; set;}
    public Boolean hasZuschuss {get; set;}
    public Boolean sendAntragsformular {get; set;}
    
    public Id partnerProductId {get; set;}
    public Id opportunityId {get; set;}
    public Contact customer {get; set;}
    public String customerEmail {get; set;}
    public Contact alternative {get; set;}   
        
    public String terminPhone {get; set;}
    
    private PLZTool_PartnerProduct product;            

    public SelfmailerController(Id oppId) {
        showSelfmailer = false;
        layout = 'none';
        opportunityId = oppId;
        System.debug('mansi::: in SelfmailerController constructor with parameter');
    }
    
    public SelfmailerController(){
        System.debug('mansi::: in SelfmailerController constructor');
        opportunityId = ApexPages.currentPage().getParameters().get('id');
        System.debug('mansi::: in SelfmailerController constructor opportunityId:::'+ opportunityId);      
    }
       
    public void start(PLZTool_PartnerProduct selectedProduct){
        System.debug('mansi::: startSelfMailer');
        showSelfmailer = true;
        layout = 'initial';
        
        emptyFormFlag = false;
        customerEmail = '';
        toCustomer = false;
        toAlternative = false;
        KlasBasisPaket = false;
        KlasServicePaket = false;
        ModBasisPaket = false;
        ModServicePaket = false;        
        
        customer = new Contact();
        alternative = new Contact();
        setContacts();
        
        setPartnerProduct(selectedProduct);
    }
    
    // check the 'Pflegegrad' value of opportunity and PB and lead. 
    // the contacts should be filled before calling this method
    private void hasPflegegrad(){
        hasPflegegrad = false;
        Opportunity opp;
        List<Opportunity> oppList = [select Id,
                                        Name, 
                                        Pflegegrad_vorhanden__c 
                                        from Opportunity 
                                        where Id = :opportunityId limit 1];
        if(oppList != null && oppList.size()>0){
            opp = oppList [0];
            if(opp.Pflegegrad_vorhanden__c == 'Pflegegrad vorhanden'){
                hasPflegegrad = true;
            }
        }
        if(!hasPflegegrad && alternative != null && alternative.Pflegegrad__c != null){
            for(String val : PflegegradValues){
                if(alternative.Pflegegrad__c == val){
                    hasPflegegrad = true;
                }
            }
        }
    }    
    
    public PageReference abbruch(){
        showSelfmailer = false;
        layout = 'none';
        
        return null;
    }
    
    public PageReference sendEmail(){
        showSelfmailer = false;
        layout = 'none';                
        
        System.debug('mansi:: sendEmail:: customer::'+ customer);
        if(customer != null) {                                           
                Messaging.SingleEmailMessage mail = createMail();
                
                if(mail != null) {
                    mail.setToAddresses(new String[]{customer.Email});   
                    
                    mail.setTargetObjectId(customer.id);
                    mail.setWhatId(opportunityId);
                    
                    if(customerEmail != ''){
                        if(customer.Email != customerEmail) {                  
                             mail.setToAddresses(new String[]{customerEmail});                                                       
                        }
                    }
                    
                    try {
                         Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});        
                    }
                    catch(system.exception e) {
                         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Mail konnte nicht versendet werden! ' + e.getMessage() ));
                         system.debug('######BT2017 : Mail konnte nicht versendet werden !!!');
                    }      
                }               
       }
              
       List<Opportunity> oppList = [select Id,
                                        Name, 
                                        StageName,
                                        recordTypeId, AccountId,
                                        recordType.name,
                                        Produkt_Kategorie__c
                                        from Opportunity 
                                        where Id = :opportunityId limit 1];                                           
       
       //create a new Nachtelefonie
       createNachtelefonie(oppList[0]);
       
       // Opp update
       oppList[0].StageName = 'Selfmailer versendet';                                                         
       
       try {
           update oppList[0];
       }
       catch(system.exception e){
           system.debug('#####BT2017: Opportunity konnte nicht upgedatet werden !');
       }       
       
       updateContacts();
                   
       PageReference returnPage = new PageReference('/' + opportunityId );

       returnPage.setRedirect(true);

       return returnPage;
    }
    
    public Messaging.SingleEmailMessage createMail() {
                if(emptyFormFlag == true) setContacts();                                                                                         
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                String templateName = 'Selfmailer_customer';
                String htmlValue;
                String plainTextValue;
                List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = :templateName  limit 1];
                EmailTemplate et = new EmailTEmplate();
              
                if(etList != null && etList.size() > 0){
                    et = etList[0];
                }else{
                    System.debug('error in sendEmail:: BT:::: template not found');
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Email template not found! Please check the availability of the email template where DeveloperName = ' + templateName  ));
                    return null;
                }
                if(! et.isActive){
                    System.debug('error in sendEmail:: BT:::: template is not active');
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Required email template is not active! Please check the availability of the email template where DeveloperName = ' + templateName  ));
                    return null;
                }                
                
                htmlValue = EmailTemplateHelper.setRecipientFields(et.HtmlValue, customer.salutation, customer.lastname, customer.phone);
                plainTextValue = EmailTemplateHelper.setRecipientFields(et.body, customer.salutation, customer.lastname, customer.phone);
                
                if(htmlValue.contains('Lieber Herr')) {
                    htmlValue = htmlValue.replace('Lieber Herr', 'Sehr geehrter Herr');
                    plainTextValue = plainTextValue.replace('Lieber Herr', 'Sehr geehrter Herr');
                }            
                
                if(htmlValue.contains('Liebe Frau')){
                    htmlValue = htmlValue.replace('Liebe Frau', 'Sehr geehrte Frau');
                    plainTextValue = plainTextValue.replace('Liebe Frau', 'Sehr geehrte Frau');
                }              
                
                htmlValue = EmailTemplateHelper.setRegion(htmlValue, opportunityId );
                plainTextValue = EmailTemplateHelper.setRegion(plainTextValue, opportunityId ).replaceAll('<br/>', ''); 
                
                htmlValue = EmailTemplateHelper.setUserfields(htmlValue, UserInfo.getUserId());  
                plainTextValue = EmailTemplateHelper.setUserfields(plainTextValue, UserInfo.getUserId());                      
                
                mail.setHtmlBody(htmlValue);
                mail.setPlainTextBody(plainTextValue);
                mail.setSubject(et.Subject);     

                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setContentType('application/pdf');
                attach.setFileName('Checkliste.pdf');   
                
                if(emptyFormFlag) {
                    if(has2fach) {
                        staticResource sr = [select id, name, body from staticResource where name = 'Selfmailer_2fach_gesamt' LIMIT 1];
                        if(sr != null) attach.body = sr.body;
                    }
                    
                    if(has3fach) {
                        staticResource sr = [select id, name, body from staticResource where name = 'Selfmailer_3fach_gesamt' LIMIT 1];
                        if(sr != null) attach.body = sr.body;                    
                    }
                }
                else {
                    PageReference pref;
                    
                    if(has2fach) pref = Page.Selfmailer_2fach_pdf;     
                    if(has3fach) pref = Page.Selfmailer_3fach_pdf;  
                    
                    setPdfContent(pref);                     
                    
                    Blob content;
                    if (! Test.IsRunningTest())
                    {
                        content = pref.getContent();
                        attach.Body = content;
                    }                    
                }  
                
                mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});        
                
                return mail;                          
    }
    
    public void setPdfContent(PageReference pref){
        pref.getParameters().put('cust_fname', customer.firstname);  
        pref.getParameters().put('cust_street', customer.MailingStreet);        
        pref.getParameters().put('cust_phone', customer.Phone);  
        
        pref.getParameters().put('cust_lname', customer.LastName); 
        pref.getParameters().put('cust_pcode', customer.MailingPostalCode); 
        pref.getParameters().put('cust_city', customer.MailingCity);
        pref.getParameters().put('cust_email', customerEmail);
        
        if(toCustomer) {
            pref.getParameters().put('cb1', 'X');             
        }
        
        if(toAlternative) {
            pref.getParameters().put('cb2', 'X');  
        }       
        
        pref.getParameters().put('alt_fname', alternative.firstname);  
        pref.getParameters().put('alt_street', alternative.MailingStreet);        
        pref.getParameters().put('alt_phone', alternative.Phone);  
        
        pref.getParameters().put('alt_lname', alternative.LastName); 
        pref.getParameters().put('alt_pcode', alternative.MailingPostalCode); 
        pref.getParameters().put('alt_city', alternative.MailingCity);
        pref.getParameters().put('alt_email', alternative.Email);                                                
        
        if(KlasBasisPaket){                
                pref.getParameters().put('kbp', 'X');          
        }
                   
        if(ModBasisPaket) {
                pref.getParameters().put('mbp', 'X');        
        }
            
        if(ModServicePaket) {
                pref.getParameters().put('msp', 'X');      
        }           
        
        if(has3fach)  {                                
            if(KlasServicePaket){
                pref.getParameters().put('ksp', 'X');           
            }
        }        
            
        /*
        if(hasPflegegrad) {
            pref.getParameters().put('cb3', 'X');  
        } 
        
        if(hasZuschuss) {
            pref.getParameters().put('cb4', 'X');            
        }
        
        if(sendAntragsformular) {
            pref.getParameters().put('cb5', 'X');        
        }
        */
        
        if(terminPhone != '') {
            pref.getParameters().put('cb6', 'X');      
        }
        
        pref.getParameters().put('phone', terminPhone);             
        
    }
    
    public void createNachtelefonie(Opportunity opp){
        System.debug('mansi::: in createNachtelefonie');
        Nachtelefonie__c n = new Nachtelefonie__c();
        n.Name='NT - '+ opp.Name;
        n.Opportunity__c = opp.Id;
        n.Produkt_Kategorie__c = opp.Produkt_Kategorie__c;
        n.Familie__c = opp.AccountId;
        n.Freitext_Feld__c = 'Bitte bzgl. des Selfmailers anrufen';
        n.Status__c = 'Selfmailer nachtelefonieren';
            
        List<RecordType> oppRtList =[select id, name,sobjecttype from recordType where name = :opp.recordType.name and sobjecttype  = 'Nachtelefonie__c' limit 1];
        if(oppRtList != null && oppRtList.size()>0){
           n.RecordTypeId = oppRtList[0].Id;
        }
       
        //List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
         
        List<OpportunityContactRole> role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId = :opp.Id and ( Role = 'PB' or Role = 'PB = ASP')];
        if(role_list != null && role_list.size()>0){
            n.Pflegebed_rftiger__c = role_list[0].ContactId;
        }

        role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId = :opp.Id and ( Role = 'ASP' or Role = 'PB = ASP')];
        if(role_list != null && role_list.size()>0){
            n.Ansprechpartner__c = role_list[0].ContactId;
        }
                
        List<user> user_list = [select id, name from User where name = 'IT Support' limit 1];
        if(user_list!= null && user_list.size()>0){
            n.OwnerID = user_list[0].id;
        }
        
        NachtelefonieZeitpunkt2 nz = new NachtelefonieZeitpunkt2();
        n.F_lligkeitsdatum__c = nz.getMorningTimeFrameIn4Days();        
       
        try {
            insert n;
        }
        catch(system.exception e) {
            system.debug('######BT2017 : Neue Nachtelefonie konnte nicht erstellt werden !');
        }                   
    }
    
    private void setContacts(){
        if(opportunityId == null){    
            return;
        }
        List<OpportunityContactRole> contactRoles = [select ContactId, Role, IsPrimary  from OpportunityContactRole where OpportunityId = :opportunityId and IsDeleted = false];
        boolean EmailBounced = false;
        string BouncedReason = null;
        if(contactRoles != null && contactRoles.size()>0){
            for( OpportunityContactRole cr : contactRoles  ){
                String contactQuery = 'select Id, salutation,firstName, lastname, Name, Phone, Email, mailingStreet, MailingCity, MailingPostalCode, Pflegegrad__c from Contact where Id = \''+cr.ContactId+'\' limit 1';
                List<Contact> contactList =  Database.query(contactQuery);
                if(contactList != null && contactList.size() > 0){
                    if(cr.Role == PLZTool_Basis.contactRoleSame ){
                        toCustomer = true;
                        toAlternative = false;
                        customer = contactList[0];                        
                        alternative = contactList[0];
                    }
                    if(cr.Role == PLZTool_Basis.contactRoleInsured){
                        //toCustomer = false;
                        //toAlternative = false;                    
                        alternative = contactList[0];                    
                    }               
                    if(cr.Role == PLZTool_Basis.contactRoleContact){
                        toCustomer = false;
                        toAlternative = true;
                        customer = contactList[0];
                    }
                    
                    if(customer != null) customerEmail = customer.Email;
                    if(customerEmail == null) customerEmail = '';
                } 
            }
            terminPhone = customer.Phone;
        }
        
        hasPflegegrad();
        system.debug('#########BT2017  toCustomer: ' + toCustomer);
        system.debug('#########BT2017  toAlternative: ' + toAlternative);        
    }
    
    private void setPartnerProduct(PLZTool_PartnerProduct selectedProduct){
        product = selectedProduct;
        if(product.pp.Produktgruppe__c == selfmailer2Fach ){
            has2Fach = true;
            has3Fach = false;
            fach1Label = 'Hausnotruf Basis';            
            fach2Label = 'Mobiler Notruf';
            fach3Label = 'Notrufhandy';
            fach4Label = '';            
        }
        if(product.pp.Produktgruppe__c == selfmailer3Fach ){
            has2Fach = false;
            has3Fach = true;
            fach1Label = 'Hausnotruf Basis';
            fach2Label = 'Hausnotruf Service';
            fach3Label = 'Mobiler Notruf';
            fach4Label = 'Notrufhandy';
        }
    }
    
    public void emptyForm(){
        System.debug('Mansi::: emptyFormFlag:::'+ emptyFormFlag);
        customerEmail = '';
        
        if(emptyFormFlag){
            customer = new Contact();
            alternative = new Contact();            
            toCustomer = false;
            toAlternative = false;
            KlasBasisPaket = false;
            KlasServicePaket = false;
            ModBasisPaket = false;
            ModServicePaket = false; 
            terminPhone = '';
        }else{
            setContacts();
        }
    }    
    
    private void updateContacts() {
        if(customer != null && customer.id != null){
            customer.Email = customerEmail;
            try{
                update customer;            
            }
            catch(system.exception e) {
                system.debug('############BT2017 Kontakt mit ID: ' + customer.id + ' konnte nicht upgedatet werden !');
            }
        }
        
        if(alternative != null && alternative.id != null){
            try{
                update alternative;            
            }
            catch(system.exception e) {
                system.debug('############BT2017 Kontakt mit ID: ' + alternative.id + ' konnte nicht upgedatet werden !');
            }
        }        
    }        
}