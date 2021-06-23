/****************************************************************************************************************************
// Erstellt 11.07.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: opportunity 
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//             Ersetzt Brief_Schreiben (Kundenkommunikation)
//
//****************************************************************************************************************************
// Test:  
//*****************************************************************************************************************************
// Änderungen:   
//    02.10.2019    BT    checking if there are no role in opportunity contact role record    
//    01.11.2019    AM    00002177 - Umstellen von FollowUp zu Task
//    06.03.2020    DZ    Template Ordner auf "SF_Lightning_curabox' eingeschränkt. 
//    04.05.2021    DZ    Added new folder "SF_curabox_Storno"
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class createLetter {
    private opportunity opp;
    private string retPage;
    private boolean isTemplateSelect = false; 
    
    private mail_template_holen mth {get; set;} 
    public string betreff {get;set;}
    public string schreiben {get;set;}
    public string htmlt {get;set;}

    public string etid {get;set;}
    public Id fromId {get; set;}
    
    public EmailTemplate et {get;set;}
    public EmailTemplate[] EmailTemplates {get;set;}
    public CompanyInfo__c FirmenInfo {get; set;}
    
    // public Brief_schreiben_adresse empf {get; set;}
    // public List<SelectOption> selRCPT = new List<SelectOption>();
    public string selectedRcpt = 'PB';   
    public id pbId {get; set;}

    private List<opportunityContactRole> ocrList = new List<OpportunityContactRole>(); 

    public class empSatz {
        public string empType {get; set;}
        public string empAnrede {get; set;}
        public string empName {get; set;}
        public string empMail {get;set;}
        public string empAnredeformel {get;set;}
        public string empStrasse {get; set;}
        public string empPLZ {get; set;}
        public string empOrt {get; set;}
        public string empFax {get; set;}
        public string empPhone {get; set;}
        public id empRcpt {get; set;}
        public boolean hasMail {get; set;}
        public boolean empHasAddr {get; set;}
    }
    public empSatz adr {get; set;}

    public map<string, empSatz> empMap = new map<string, empSatz>();
    // public empSatz AddressRecord {get; set;}
    
    public string tempBodyText {get;set;}
    public string tempBodyHTML {get;set;}
    public string tempSubject {get;set;}  

    public createLetter() {}

    public createLetter(ApexPages.StandardController sc) {
        fromId = userInfo.getUserId();
        // CompanyInfo
        FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
            if(FirmenInfo.GF__c.contains(', ')){
                String[] GF = FirmenInfo.GF__c.split(', ',2);
                FirmenInfo.GF__c = GF[0] + '<br />'+GF[1];
            }
        }  
        
        ocrList = [SELECT Role, ContactId, Contact.Salutation, Contact.firstname, contact.lastname, contact.email, 
                        contact.MailingStreet, contact.MailingPostalCode, contact.MailingCity, contact.Versicherungsnummer__c,
                        Opportunity.RecordType.Name, Contact.Pflegedienst__c
                    FROM OpportunityContactRole
                    WHERE OpportunityId =: sc.getId()];
        if((ocrList != null) &&(ocrList.size() > 0)) {
            fillAddressTable();           
        }
        
    }

    public PageReference processCreateLetter() {   
        // try {
        //     selectedRcpt = ApexPages.currentPage().getParameters().get('Rcpt');
        //     // this.changeRcpt();
        //     }
        //     catch (System.exception e) {} 
   
        return null;
    }

    @TestVisible private void fillAddressTable() {
        String opportunityRecordTypeName = null;
        id pdid = null;
        for(OpportunityContactRole ocr : ocrList) {
            // 02.10.2019 BT  checking if there are no role in opportunity contact role record
            if(ocr.Role != null) {
                if(ocr.Role.Contains('PB')) {
                    pbId = ocr.ContactId;
                    if(ocr.Contact.Pflegedienst__c != null) {
                        pdid = ocr.Contact.Pflegedienst__c;
                    }
                }
            }
            empSatz addr = new empSatz();
            addr.empRcpt = ocr.ContactId;
            
            // 02.10.2019 BT  checking if there are no role in opportunity contact role record
            if(ocr.Role != null) {
                addr.empType = ocr.Role;
            }
            else {
                addr.empType = '';
            }
            
            addr.empAnrede = ocr.contact.Salutation;
            if(ocr.contact.firstname != null) {
                addr.empName = ocr.contact.firstname + ' ' + ocr.contact.lastname;
            }
            else {
                addr.empName = ocr.contact.lastname;
            }
            
            addr.empMail = ocr.contact.email;
            system.debug('############## email:' + addr.empMail);
            if(String.isEmpty(addr.empMail)) {
                addr.hasMail = false;
            }
            else {
                addr.hasMail = true;
            }
            addr.empStrasse = ocr.contact.MailingStreet;
            addr.empPLZ = ocr.contact.MailingPostalCode;
            addr.empOrt = ocr.contact.MailingCity;
            if((addr.empStrasse == null) || (addr.empPLZ == null) || (addr.empOrt == null)) {
                addr.empHasAddr = false ;
            } 
            else {
                addr.empHasAddr = true ;
            } 
            If (!String.isEmpty(addr.empAnrede)) {
                If (addr.empAnrede.contains('Herr') ) { 
                    addr.empAnredeformel = 'Sehr geehrter ' + addr.empAnrede + ' ' + ocr.contact.LastName +',';
                }
                If (addr.empAnrede.contains('Frau') ) { 
                    addr.empAnredeformel = 'Sehr geehrte ' + addr.empAnrede + ' ' + ocr.contact.LastName +',';
                }                   
            }                        
            if(addr.empAnredeformel == null) {
                addr.empAnredeformel = 'Sehr geehrte Damen und Herren, ';
            }        
            if(adr == null) {
                selectedRcpt = addr.empRcpt;
                adr = addr;
            }             
            empMap.put(addr.empType, addr);
            opportunityRecordTypeName = ocr.Opportunity.RecordType.Name;
        }
        if(opportunityRecordTypeName != null) {
            fromId = ksgFunctions.getEmailFromId(opportunityRecordTypeName);
        }
        if(pdid != null) {
            account pd = [SELECT id, name, BillingStreet, BillingCity, BillingPostalCode, Email_Firma__c, Weitere_E_Mail__c FROM account WHERE id = : pdid];
            empSatz addr = new empSatz();
            addr.empRcpt = pd.Id;
            addr.empType = 'Pflegedienst';
            addr.empAnrede = null;
            addr.empAnredeformel = 'Sehr geehrte Damen und Herren, ';
            addr.empName = pd.name;
            if(pd.Email_Firma__c != null) {
                addr.empMail = pd.Email_Firma__c;
            }
            else if (pd.Weitere_E_Mail__c != null) {
                addr.empMail = pd.Weitere_E_Mail__c;
            }
            
            system.debug('############## email:' + addr.empMail);
            if(String.isEmpty(addr.empMail)) {
                addr.hasMail = false;
            }
            else {
                addr.hasMail = true;
            }

            addr.empStrasse = pd.BillingStreet;
            addr.empPLZ = pd.BillingPostalCode;
            addr.empOrt = pd.BillingCity;
            if((addr.empStrasse == null) || (addr.empPLZ == null) || (addr.empOrt == null)) {
                addr.empHasAddr = false ;
            } 
            else {
                addr.empHasAddr = true ;
            }  
            empMap.put(addr.empType, addr);           
        } 
    }

    public void changeRcpt() {        
        adr = empMap.get(SelectedRcpt);        
    }

    public PageReference Brief_schreiben_Pdf(){
        // Follow_Up_Task_Helper.insertFollowUpTask(adr.empRcpt, 
        //                                         'Brief versandt', 
        //                                         'Brief mit folgendem Inhalt versandt:\n\n'
        //                                             +'Betreff:\n'+betreff+'\n\n'
        //                                             +'Schreiben:\n'+schreiben, 
        //                                         date.today(), 
        //                                         'Geschlossen');
        Task th = new Task(ActivityDate = Date.today(),
                    Subject='Brief versandt',
                    // WhoId = adr.empRcpt,
                    Description = 'Brief mit folgendem Inhalt versandt:\n\n'
                                +'Betreff:\n'+betreff+'\n\n'
                                +'Schreiben:\n'+schreiben,
                    OwnerId = UserInfo.getUserId(),
                    Status='Geschlossen');
        String objType = adr.empRcpt.getSObjectType().getDescribe().getName();
        if((objType.equalsIgnoreCase('contact')) || (objType.equalsIgnoreCase('lead'))) {
            th.WhoId = adr.empRcpt;
        }
        else {
            th.WhatId = adr.empRcpt;
            th.WhoId = pbId;
        }
        insert th;        
        return Page.createLetterPdf;
    }    
    
    public PageReference perEmail(){ 
        system.debug('############### Alex200 ' + adr); 
        if(etid != null) {
            mth = new mail_template_holen(adr.empRcpt, id.valueOf(etid));
               
            schreiben = mth.getPlaintextBody();
            htmlt = mth.getHTMLbody();
            betreff = mth.getBetreff();
        }
        else {
            mth = new mail_template_holen(adr.empRcpt);
            tempBodyHTML = mth.getHTMLbody();
            tempBodyText = mth.getPlaintextBody();
            tempSubject = mth.getBetreff();
        }     

         string plaintext;
         
         if(schreiben != null) { 
            if(etid != null) {
                plaintext = schreiben;  
            }
            else {
                htmlt = tempBodyHTML.replace('$emailtext$', schreiben);
                htmlt = htmlt.replace('$betreff$', betreff);
                htmlt = htmlt.replace('$anredeformel$', adr.empAnredeformel);
                plaintext = tempBodyText.replace('$emailtext$', schreiben);         
            }
         }
         else {
             schreiben = ' ';
             plaintext = schreiben;
         }
         
         Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();         
         mail.setSubject(betreff);   
         String[] toAddress =  new String[]{adr.empMail};                  
         String[] toCcAddress =  new String[]{};                  
         mail.setToAddresses(toAddress);
         mail.setBccAddresses(toCcAddress); 
         
         mail.setPlainTextBody(plaintext);
         mail.setHTMLBody(htmlt);

        if(fromId != userInfo.getUserId()){
            mail.setOrgWideEmailAddressId(fromId);
        }

         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Mail gesendet an ' + adr.empMail)); 
        //  Follow_Up_Task_Helper.insertFollowUpTask(adr.empRcpt, 
        //                                         'Brief per Email versandt', 
        //                                         'Brief per Email versandt an ' 
        //                                                         + adr.empName + ' (' + adr.empMail + ') Betreff:\n' +betreff+'\n\n'+'Schreiben:\n'+schreiben, 
        //                                         date.today(), 
        //                                         'Geschlossen');
        Task th1 = new Task(ActivityDate = Date.today(),
                            Subject='Brief per Email versandt',
                            // WhoId = adr.empRcpt,
                            Description = 'Brief per Email versandt an ' + adr.empMail + ' (' + adr.empMail + ') Betreff:\n' +betreff+'\n\n'+'Schreiben:\n'+schreiben,
                            OwnerId = UserInfo.getUserId(),
                            Status='Geschlossen');
        String objType = adr.empRcpt.getSObjectType().getDescribe().getName();
        if((objType.equalsIgnoreCase('contact')) || (objType.equalsIgnoreCase('lead'))) {
            th1.WhoId = adr.empRcpt;
        }
        else {
            th1.WhatId = adr.empRcpt;
            th1.WhoId = pbId;
        }
        insert th1;  
        return null;                  
    }


    public PageReference GotoTemplateSelect()
    {
        PageReference pg = new PageReference('/apex/CustomEmailTemplateSelect');
        String returnUrlStr= '/apex/createLetterForm?id=' + ApexPages.currentPage().getParameters().get('id');
        pg.getParameters().put('returnURL', returnUrlStr);
        pg.getParameters().put('Rcpt', selectedRcpt);
        pg.setRedirect(true);
        return pg;
    }

    public PageReference selectCustomTemplate() {
        isTemplateSelect = true;
        EmailTemplates = [SELECT Name, Description FROM EmailTemplate where folderId in (select Id from Folder where developerName = 'SF_Lightning_curabox' OR developerName = 'SF_curabox_Storno')ORDER BY Name];
        return null;
    }

    public PageReference PassTemplateIdToReturnURL() {
        isTemplateSelect = false;
        if(etid != null) {
            mth = new mail_template_holen(adr.empRcpt, id.valueOf(etid));               
            schreiben = mth.getPlaintextBody();
            htmlt = mth.getHTMLbody();
            betreff = mth.getBetreff();
        }
        return null;
    }

    public PageReference zurueck() {
        PageReference returnPage = new PageReference(retPage);
        returnPage.setRedirect(true);
        return returnPage;
    }

    public empSatz getadr() {
        return adr;
    } 

    public string getSelectedRcpt() {
        return selectedRcpt;
    }

    public boolean getisTemplateSelect() {
        return isTemplateSelect;
    }

    public void setSelectedRcpt(string selectedRcpt) {
        this.selectedRcpt = selectedRcpt;
    }  

    public List<SelectOption> selRCPT {
        get {
            List<SelectOption> options = new List<SelectOption>();
            for(string key : empMap.keySet()) {
                empSatz es = empMap.get(key);
                options.add(new SelectOption(key, ES.empType));
            }
            return options;
        }
        set;
    }

    public String getSchreiben_Formatted(){
        // replaces < and > with ( and ) because of security issues (e.g. injection)
        return schreiben.replaceAll('<','(').replaceAll('>',')').replaceAll('\n','<br/>');
    }

    public List<SelectOption> fromAddr {
        set;
        get {
            return ksgFunctions.getFromOptions();
        }
    }

    public id getFromId(){
        return this.fromId;
    }

    public void setFromId(id fromId){
        this.fromId = fromId;
    }
}