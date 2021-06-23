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
// The programm generates an activity on the opportunity for calling and an email to customer
//
//
//****************************************************************************************************************************
//Changes:
//
// 02.09.2016     wds    some smaller modification to get the right data to EmailTemplateHelper which generates the email
// 05.09.2016     BT     Die Prozesse "Nachtelefonie individuell einrichten" und "Nächsten Zeitpunkt definieren" laufen 
//                        über die Klasse NachtelefonieZeitpunkt2
// 10.11.2016     MZ     remove sending email to customers 
// 16.12.2016     MZ     "In 4 days" option and "Offen – Kat. 1,5" added.
// 19.12.2016     MZ     set the Nachtelefonie recordType based on opportunity recordType
// 20.02.2017     MZ     set opportunity status to 'Wiedervorlage' when NT is selected as Kat.2
// 27.02.2017     MZ     set Nachtelefonie.Produkt with opportunity.Produkt value
// 16.01.2018     MZ     #154212180
// 24.07.2018	  MZ	 00001549 adjusting NT for Badumabu project
// 26.07.2018	  MZ	 badumbau email template added.
//****************************************************************************************************************************
public class NachtelefonieZeitpunkt2{

    private static String ownerError = 'Zur Weiterverarbeitung musst du Inhaber des Datensatzes sein';
    
    public Nachtelefonie__c formObj = new Nachtelefonie__c();
    public Opportunity opp = new Opportunity();
    public Id opportunityId;
    public Nachtelefonie__c dummyObj1 = new Nachtelefonie__c();
    public Nachtelefonie__c dummyObj2 = new Nachtelefonie__c();
    private Id nachtelefonieId;
    
    private boolean enableNextButton = true;
    private String preferredTimeframe = '';
    
    public string type {get; set;}
    public string pagetitle {get; set;}
    public string display_value {get; set;}
    public boolean ntButton {get; set;}
    public boolean oppButton {get; set;}
    
    public Boolean successFlag{set;get;}
    
    public Boolean erreichtCheckBox{set;get;}
    public Boolean nichtErreichtCheckBox{set;get;}
    
    public Boolean noEmail{set;get;}
    public Boolean showCategory{set;get;}
    
    public Boolean ZeitCheckbox = true;
    public Boolean ZeitCheckbox4Tagen{set;get;}
    public String selectedTime{set;get;}
    public String selectedTimeErreicht{set;get;}
    public String defaultCategory = '2';  
    public String selectedCategory = defaultCategory ;
    
    
    private static string status_opp_kat2 = 'Wiedervorlage Kat. 2';
    private static string status_opp_kat1 = 'Wiedervorlage';
    private static string status_opp_selfmailer = 'Selfmailer versendet';
    private static string status_kat2 = 'Offen - Kat. 2';
    private static string status_kat1 = 'Offen - Kat. 1';
    private static string status_kat15 = 'Offen – Kat. 1,5';
    private static string status_selfmailer = 'Selfmailer nachtelefonieren';
    
    private map<String, String> categoryMap= new map<String, String>();
    
    private map<Integer, String> timeFramesMap= new map<Integer, String>();
    private map<Integer, Datetime> timeFrames= new map<Integer, Datetime>();
    
    public Boolean isOwner;
    public string NtTypeDisplayValue{get; set;}
    
    private void initializeCategoryMap(){
        //categoryMap.put('0', '--None--');
        categoryMap.put('1', status_kat1);
        categoryMap.put('2', status_kat2);
    }
    
    private void initializeTimeFrames(){
        timeFramesMap.put(0, '--None--');
        timeFramesMap.put(1, 'Vormittag (8 bis 12 Uhr)');
        timeFramesMap.put(2, 'Mittag (12 bis 15 Uhr)');
        timeFramesMap.put(3, 'Nachmittag (15 bis 18 Uhr)');
        timeFramesMap.put(4, 'Abend (18 bis 20 Uhr)');
        
        Datetime today = Datetime.now();
        Integer y = today.year();
        Integer m = today.month();
        Integer d  = today.day();
        
        Datetime Vormittag = Datetime.newInstance(y, m, d, 8, 0, 0);
        Datetime Mittag = Datetime.newInstance(y, m, d, 12, 0, 0);
        Datetime Nachmittag = Datetime.newInstance(y, m, d, 15, 0, 0);
        Datetime Abend = Datetime.newInstance(y, m, d, 18, 0, 0);
        
        timeFrames.put(1, Vormittag );
        timeFrames.put(2, Mittag );
        timeFrames.put(3, Nachmittag );
        timeFrames.put(4, Abend );
    }
    
    public NachtelefonieZeitpunkt2(String dummyParameter){
        initializeTimeFrames();
    }
    
    public NachtelefonieZeitpunkt2(){
        NtTypeDisplayValue = 'none';
        showCategory = true;
        Id ownerId;
        initializeTimeFrames();
        initializeCategoryMap();
        nichtErreicht();
        nachtelefonieId = ApexPages.currentPage().getParameters().get('id');
        
        Nachtelefonie__c[] nList = [ select Id,
                                            Owner.Id,
                                            Name, 
                                            Opportunity__c, 
                                            Status__c, 
                                            F_lligkeitsdatum__c, 
                                            Kunde_wurde_bereits_erreicht__c, 
                                            Anzahl_der_Versuche__c, 
                                            Ansprechpartner__c,
                                            Ansprechpartner__r.salutation,
                                            Ansprechpartner__r.lastname,
                                            Ansprechpartner__r.phone,
                                            recordTypeId, 
                                            recordType.name,
                                            Familie__c,
                                            Preferred_timeframe__c,
                                    		NT_Badumbau_Type__c
                                            from Nachtelefonie__c where Id = :nachtelefonieId limit 1];
        if(nList!= null && nList .size()>0){
            formObj= nList[0];  
            ownerId = nList[0].Owner.Id; 
            type = 'zeitpunkt';  
            pagetitle = 'Nächsten Zeitpunkt definieren'; 
            preferredTimeframe = nList[0].Preferred_timeframe__c;
            display_value = 'none';  
            ntButton = true;
            oppButton = false;
            if(formObj.Status__c == status_selfmailer){
                showCategory = false;
            } 
            if(formObj.RecordType.Name == PLZTool_Basis.rtBadumbau){
                showCategory = false;
            }
        }else{
            System.debug('error in Nachtelefonie !!! ::: no Nachtelefonie found with Id: ' + this.nachtelefonieId );
            
            nachtelefonieId = null;
            opportunityId = ApexPages.currentPage().getParameters().get('id');
            List<Opportunity> opp_list = [select id,Owner.Id, name, AccountId, recordTypeId, recordType.name, Produkt_Kategorie__c, stageName, Preferred_timeframe__c from Opportunity where id = :opportunityId limit 1];
            if(opp_list!= null && opp_list.size()>0){
                opp = opp_list[0];
                
                List<RecordType> rtList =[select id, name,sobjecttype from recordType where name = :opp.recordType.name and sobjecttype  = 'Nachtelefonie__c' limit 1];
                if(rtList != null && rtList.size()>0){
                    formObj.RecordTypeId = rtList[0].Id;
                }
                
                formObj.Name ='NT - '+ opp.Name;
                formObj.Opportunity__c = opp.Id;
                formObj.Familie__c = opp.AccountId;
                formObj.Produkt_Kategorie__c = opp.Produkt_Kategorie__c;
                formObj.Preferred_timeframe__c = opp.Preferred_timeframe__c;
                ownerId = opp.Owner.Id;
                type = 'individuell';
                pagetitle = 'Nachtelefonie individuell einrichten';
                preferredTimeframe = opp.Preferred_timeframe__c;
                display_value = 'block';
                oppButton = true;
                ntButton = false;
                
                if(opp.stageName == status_opp_selfmailer){
                    showCategory = false;
                }
                
                if(opp.RecordType.Name == PLZTool_Basis.rtBadumbau){
                    showCategory = false;
                    NtTypeDisplayValue = 'block';
                }
            }   
            else{
                System.debug('error in Opportunity !!! ::: no Opportunity found with Id: ' + this.opportunityId );
            }     
        }
        formObj.F_lligkeitsdatum__c = null;
        isOwner = isOwner(ownerId);
    }
    
    public void setZeitCheckbox(Boolean val){
        zeitCheckbox = val;
    }
    
    public Boolean getZeitCheckbox(){
        return zeitCheckbox;
    }
    
    public void setZeitCheckbox4Tagen(Boolean val){
        zeitCheckbox = val;
    }
    
    public Boolean getZeitCheckbox4Tagen(){
        return zeitCheckbox;
    }
    
    public Nachtelefonie__c getFormObj(){
        return formObj;
    }
    
    public Nachtelefonie__c getDummyObj1 (){
        return dummyObj1 ;
    }
    public Nachtelefonie__c getDummyObj2 (){
        return dummyObj2 ;
    }
    public void erreicht(){
        erreichtCheckBox = true;
        nichtErreichtCheckBox = false;
        ZeitCheckbox = false;
        ZeitCheckbox4Tagen = false; 
    }
    
    public void nichtErreicht(){
        ZeitCheckbox = true;
        neNextFrame();
    }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('0', timeFramesMap.get(0)));
        options.add(new SelectOption('1', timeFramesMap.get(1)));
        options.add(new SelectOption('2', timeFramesMap.get(2)));
        options.add(new SelectOption('3', timeFramesMap.get(3)));
        options.add(new SelectOption('4', timeFramesMap.get(4)));
        return options;
    }
    
    public List<SelectOption> getTypeItems(){
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Nachtelefonie__c.NT_Badumbau_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }
    
    public List<SelectOption> getCatItems() {
        List<SelectOption> options = new List<SelectOption>();
        //options.add(new SelectOption('0', categoryMap.get('0')));
        options.add(new SelectOption('1', categoryMap.get('1')));
        options.add(new SelectOption('2', categoryMap.get('2')));
        return options;
    }
    
    public Datetime getNextTimeframe(){
        Datetime dt = Datetime.now();
        Datetime next = timeFrames.get(1).addDays(1);
        if(dt < timeFrames.get(1)){
            if( (Integer.valueOf((timeFrames.get(1).getTime() - dt.getTime())/(1000*60*60))) <2  ){
                next = timeFrames.get(2);
            }else{
                next = timeFrames.get(1);
            }
        }else if(dt < timeFrames.get(2)){
            if( (Integer.valueOf((timeFrames.get(2).getTime() - dt.getTime())/(1000*60*60))) <2  ){
                next = timeFrames.get(3);
            }else{
                next = timeFrames.get(2);
            }
        }else if(dt < timeFrames.get(3)){
            if( (Integer.valueOf((timeFrames.get(3).getTime() - dt.getTime())/(1000*60*60))) <2  ){
                next = timeFrames.get(4);
            }else{
                next = timeFrames.get(3);
            }
        }else if(dt < timeFrames.get(4)){
            if( (Integer.valueOf((timeFrames.get(4).getTime() - dt.getTime())/(1000*60*60))) <2  ){
                next = timeFrames.get(1).addDays(1);
            }else{
                next = timeFrames.get(4);
            }
        }
        return next;
    }
    
    public Datetime getNextPreferredTimeframe(String Preferred_timeframe){
        if(String.isEmpty(Preferred_timeframe)){
            return getNextTimeframe();
        }
        Datetime today = Datetime.now();
        
        Integer y = today.year();
        Integer m = today.month();
        Integer d  = today.day();
        
        Datetime preferedTimeFrame;
        if(Preferred_timeframe.containsignoreCase('nachmittag') || Preferred_timeframe.containsignoreCase('18')){
            preferedTimeFrame = Datetime.newInstance(y, m, d, 15, 0, 0);
        }
        else if(Preferred_timeframe.containsignoreCase('vormittag') || Preferred_timeframe.containsignoreCase('8')){
            preferedTimeFrame = Datetime.newInstance(y, m, d, 8, 0, 0);
        }
        else{
            preferedTimeFrame = Datetime.newInstance(y, m, d, 12, 0, 0);
        }
        
        Datetime next = preferedTimeFrame.addDays(1);
        Datetime dt = Datetime.now();
        if(dt < preferedTimeFrame){
            if( (Integer.valueOf((preferedTimeFrame.getTime() - dt.getTime())/(1000*60*60))) <2  ){
                next = preferedTimeFrame.addDays(1);
            }else{
                next = preferedTimeFrame;
            }
        }
        return next;
    }
    
    public Datetime getMorningTimeFrameIn4Days(){
        Datetime dt = Datetime.now();
        Datetime next = timeFrames.get(1).addDays(4);
        
        return next ;
    }
    
    public void  setSelectedCategory (String val ){
        selectedCategory = val;
    } 
    
    public String getSelectedCategory  (){
        return selectedCategory ;
    }
    
    public Datetime getSelectedTimeFrame(String value){
        Datetime dt = Datetime.now();
        Datetime next = timeFrames.get(Integer.valueof(value));
        if(dt > next ){
            next = next .addDays(1);
        }
        return next ;
    }
    
    public PageReference Speichern(){
        if ( ! isOwner ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ownerError ));
            return null;
        }
        try{
        if(nichtErreichtCheckBox){
            if(zeitCheckbox){
                formObj.F_lligkeitsdatum__c = getNextPreferredTimeframe(preferredTimeframe); //getNexttimeFrame();
            }else if(selectedTime != '0'){
                formObj.F_lligkeitsdatum__c = getSelectedTimeFrame(selectedTime );
            }else if(dummyObj1 .F_lligkeitsdatum__c != null ){
                if(Datetime.now() > dummyObj1 .F_lligkeitsdatum__c ) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Bitte legen Sie ein gültiges Datum und Uhrzeit für Individueller Termin fest.'));
                    return null;
                }
                formObj.F_lligkeitsdatum__c = dummyObj1.F_lligkeitsdatum__c;
            }else if(ZeitCheckbox4Tagen){
                formObj.F_lligkeitsdatum__c = getMorningTimeFrameIn4Days();
                if(showCategory){ // if NT or OPP is selfmailer the status of NT and OPP should not change - 14.06.2017
                    formObj.Status__c = status_kat15;
                }
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select one of the options'));
                return null;
            }
        }else if(erreichtCheckBox){
            if(selectedTimeErreicht!= '0'){
                formObj.F_lligkeitsdatum__c = getSelectedTimeFrame(selectedTimeErreicht);
            }else if(dummyObj2.F_lligkeitsdatum__c != null ){
                if(Datetime.now() > dummyObj2 .F_lligkeitsdatum__c ) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Bitte legen Sie ein gültiges Datum und Uhrzeit für Individueller Termin fest.'));
                    return null;
                }
                formObj.F_lligkeitsdatum__c = dummyObj2.F_lligkeitsdatum__c;            
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Bitte wähle eine der Optionen aus!'));
                return null;
            }
            // if NT is selfmailer the status of NT and OPP should not change - 14.06.2017
            // if it is Badumabu, status of NT and Opp should not change - 18.07.2018
            if(showCategory){ 
                if(selectedCategory == defaultCategory && formObj.Wiedervorlage_Kat_2_Grund__c == null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Bitte wähle einen Grund für Kat. 2 aus!'));
                    return null;
                }
                formObj.Status__c = categoryMap.get(selectedCategory);
                updateOpportunitystatus();
            }
            formObj.Kunde_wurde_bereits_erreicht__c = true;
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Bitte wähle eines der Kontrollkästchen "Erreicht" oder "nicht erreicht" aus.'));
            return null;
        }   
            if(type == 'zeitpunkt'){
                formObj.Anzahl_der_Versuche__c += 1;
                
                List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
                if(user_list != null && user_list.size()>0){
                    formobj.ownerID = user_list[0].id;           
                }
                
                update(formObj); 
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm , 'Die neuen Änderungen wurden angewendet' ));
                return zuNachtelefonie();            
            }
            else { 
                
                if( !noEmail ){
                    sendEmailToCustomer();
                }
                           
                List<OpportunityContactRole> role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId = :opportunityId and ( Role = 'PB' or Role = 'PB = ASP')];
                if(role_list != null && role_list.size()>0){
                    formObj.Pflegebed_rftiger__c = role_list[0].ContactId;
                }
    
                role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId = :opportunityId and ( Role = 'ASP' or Role = 'PB = ASP')];
                if(role_list != null && role_list.size()>0){
                    formObj.Ansprechpartner__c = role_list[0].ContactId;
                }     
                
                List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
                if(user_list != null && user_list.size()>0){
                    formobj.ownerID = user_list[0].id;           
                    opp.ownerID = user_list[0].id;     
                }           
                
                update opp;
                insert formObj;
                
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm , 'Die neuen Änderungen wurden angewendet' ));
                return zuOpportunity();              
            }                
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage() ));       
        }
        return null;
    }
    
    public void updateOpportunitystatus(){
        String oppSts = status_opp_Kat1;
        String kat2Grund = formObj.Wiedervorlage_Kat_2_Grund__c;
        if(selectedCategory == defaultCategory){
            oppSts = status_opp_Kat2;
        }
        if(type == 'zeitpunkt'){
            List<Opportunity> oppList = [select id, StageName from opportunity where id = :formObj.Opportunity__c];
            Opportunity opp;
            if(oppList != null && oppList .size() > 0){
                opp= oppList [0];
            }else{
                System.debug('error in updateOpportunitystatus:: Mansi:::: opportunity not found');
                throw new applicationException ('Opportunity not found!');
            }
            opp.Wiedervorlage_Kat_2_Grund__c = kat2Grund;
            opp.stageName = oppSts ;
            update opp;
        }
        else{
            if(opp != null){
                opp.Wiedervorlage_Kat_2_Grund__c = kat2Grund;
                opp.StageName = oppSts ;
            }
        }
    }
    
    public void sendEmailToCustomer(){
        String templateName = 'Nachtelefonie_customer';
        if(opp.recordType.name == PLZTool_Basis.rtBadumbau){
        	templateName = 'Kunde_erstmalig_nicht_erreicht';
        }
        String htmlValue;
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
        
        Contact c = getContact();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        htmlValue = EmailTemplateHelper.setRecipientFields(et.HtmlValue, c.salutation, c.lastname, c.phone);
        htmlValue = EmailTemplateHelper.setRegion(htmlValue, opp.Id );
        htmlValue = EmailTemplateHelper.setUserfields(htmlValue, UserInfo.getUserId());
        
        mail.setHtmlBody(htmlValue);
        mail.setPlainTextBody(et.body);
        mail.setSubject(et.Subject);
        
        if(opp.recordType.name == PLZTool_Basis.rtBadumbau){
            mail.setHtmlBody(EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, htmlValue, UserInfo.getUserId()));
            mail.setPlainTextBody(EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, et.body, UserInfo.getUserId()));
            mail.setSubject(EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, et.Subject, UserInfo.getUserId()));
            mail.setWhatId(formObj.Opportunity__c);
            List<OrgWideEmailAddress> orgWideAddresses = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Badumbau'];
            if(orgWideAddresses != null && orgWideAddresses.size()>0){
                mail.setOrgWideEmailAddressId(orgWideAddresses[0].Id);
                mail.setReplyTo(orgWideAddresses[0].Address);
            }
        }
        
        if(c == null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'The opportunity has no ASP contact'));
                return ;
        }
        mail.setTargetObjectId(c.id);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }
    
    private Contact getContact(){
        List<OpportunityContactRole> contactRoles = [select ContactId, Role, IsPrimary  from OpportunityContactRole where OpportunityId = :opp.Id and IsDeleted = false and ( Role = :PlzTool_basis.contactRoleContact or Role = :PlzTool_basis.contactRoleSame )];
        if(contactRoles != null && contactRoles.size()>0){
            for( OpportunityContactRole cr : contactRoles  ){
                String contactQuery = 'select Id, Name,lastname, Salutation, Phone, Email, mailingStreet, MailingCity, MailingPostalCode from Contact where Id = \''+cr.ContactId+'\' limit 1';
                                       
                List<Contact> contactList =  Database.query(contactQuery);
                 
                
                return contactList[0];
            }
        }else{
            System.debug('error in setIntendedContacts:::: Mansi::: no contact role found !!!');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No contact role is defined for the opportunity! '));
        }
        return null;
    }
    
    
    public class applicationException extends Exception{}
    
    
    public void neNextFrame(){
        if(ZeitCheckbox == true){
            erreichtCheckBox = false;
            nichtErreichtCheckBox = true;
            selectedTime = '0';
            selectedTimeErreicht = '0';
            ZeitCheckbox4Tagen = false;
            dummyObj1.F_lligkeitsdatum__c = null;
            dummyObj2.F_lligkeitsdatum__c = null;
        }
    }
    
    public void neGivenFrame(){
        if(selectedTime != '0'){
            erreichtCheckBox = false;
            nichtErreichtCheckBox = true;
            ZeitCheckbox = false;
            selectedTimeErreicht = '0';
            ZeitCheckbox4Tagen = false;
            dummyObj1.F_lligkeitsdatum__c = null;
            dummyObj2.F_lligkeitsdatum__c = null;
        }
    }
    
    public void neTermin(){
        if(dummyObj1.F_lligkeitsdatum__c != null){
            erreichtCheckBox = false;
            nichtErreichtCheckBox = true;
            ZeitCheckbox = false;
            selectedTime = '0';
            selectedTimeErreicht = '0';
            ZeitCheckbox4Tagen = false;
            dummyObj2.F_lligkeitsdatum__c = null;
        }
    }
    
    public void ne4Tagen(){
        if(ZeitCheckbox4Tagen == true){
            erreichtCheckBox = false;
            nichtErreichtCheckBox = true;
            ZeitCheckbox = false;
            selectedTime = '0';
            selectedTimeErreicht = '0';
            dummyObj1.F_lligkeitsdatum__c = null;
            dummyObj2.F_lligkeitsdatum__c = null;
        }
    }
    
    public void eGivenFrame(){
        if(selectedTimeErreicht != '0'){
            erreichtCheckBox = true;
            nichtErreichtCheckBox = false;
            ZeitCheckbox = false;
            selectedTime = '0';
            ZeitCheckbox4Tagen = false;
            dummyObj1.F_lligkeitsdatum__c = null;
            dummyObj2.F_lligkeitsdatum__c = null;
        }
    }
    
    public void eTermin(){
        if(dummyObj2.F_lligkeitsdatum__c != null){
            erreichtCheckBox = true;
            nichtErreichtCheckBox = false;
            ZeitCheckbox = false;
            selectedTime = '0';
            selectedTimeErreicht = '0';
            ZeitCheckbox4Tagen = false;
            dummyObj1.F_lligkeitsdatum__c = null;
        }
    }
    
    public void eKat2Grund(){
        if(selectedCategory != defaultCategory){
            formObj.Wiedervorlage_Kat_2_Grund__c = null;
        }
    }
    
    public void eKat2(){
        if(formObj.Wiedervorlage_Kat_2_Grund__c != null){
            selectedCategory = defaultCategory;
        }
    }
   
    
    public PageReference zuNachtelefonie(){
               PageReference PageRef = new PageReference('/' + formObj.Id);
               PageRef.setRedirect(true);
                          
               return PageRef;
        }
    
    public PageReference zuOpportunity(){
        PageReference PageRef = new PageReference('/' + opportunityId);
        PageRef.setRedirect(true);
        
        return PageRef;
    }
    
    public boolean isOwner(Id ownerId){
            if(ownerId != UserInfo.getUserId()){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ownerError ));
                    return False;
            }
            return True;
    } 
     
}