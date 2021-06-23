/****************************************************************************************************************************
// Created 02.05.2019 von  AD
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//  Contact Id
//  Receiver (client, nursing service or mentor)
//****************************************************************************************************************************
//
// Description:       
//  Diese Klasse ist für das Senden des Antragsformulars an Kunde, Angehöriger oder Pflegedienst zuständig.
//  Die Hauptmethoden hierbei sind, die die mit @AuraEnabled gekennzeichnet sind. Diese werden bei dem Lightning controller aufgerufen.
//****************************************************************************************************************************
// Changes: 
// 02.04.2020     DZ    "Nachtelefonie von Interessenten" ausgeklammert
// 25.05.2020     BT    00002469 - fill pdf with customer number
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Curabox_Formular_Versenden {

    // handle change of email receiver
    @AuraEnabled
    public static String setDefaultReceiver(String contactId){
        String returnValue = '';
        String role = Curabox_Helper.getOpportunityByContact(contactId).Role;
        Contact con = Curabox_Helper.getContactById(contactId);
        if (role != null && !String.isEmpty(role)) {
            if (role == 'PB') {
                returnValue = 'Pflegebedürftiger,' + getReceiverEmail(contactId, 'Pflegebedürftiger');
                if (con.Betreuer__r.LastName != null) returnValue = returnValue + ',AJ';
                if (con.Pflegedienst__r.Name != null ) returnValue = returnValue + ',PJ';
            }
            else if (role == 'ASP') {
                returnValue = 'AnsprechpartnerIn,' + getReceiverEmail(contactId, 'Pflegebedürftiger');
                if (con.Pflegedienst__r.Name != null ) returnValue = returnValue + ',PJ';
            }
            else {
                returnValue = 'PBASP,' + getReceiverEmail(contactId, 'Pflegebedürftiger');
                if (con.Pflegedienst__r.Name != null ) returnValue = returnValue + ',PJ';
            }
        }
        else{
            returnValue = 'Keine ContactRole';
        }
        return returnValue;
    }
    
    // send application form to client or nursing service or mentor.
    @AuraEnabled
    public static string sendMailToClient(String contactId, String receiver){
        Contact contact = Curabox_Helper.getContactById(contactId);
        EmailTemplate template = Curabox_Helper.getTemplateByName('curabox_blanko_per_email');
        Date dueDate = Follow_Up_Task_Helper.getDueDate(Due_Date__c.getValues('Formularversand').Follow_Up_Task_Due_Date__c);
       
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //replace merge fields --> Contact and Account
        String emailBody = setEmailData(contact, receiver, template.Body);
        String emailText = setEmailData(contact, receiver, template.HtmlValue);
            
        mail.setSaveAsActivity(true);
        mail.setSubject(template.Subject);
        mail.setPlainTextBody(emailBody);
        mail.setHtmlBody(emailText);
        String email = getReceiverEmail(contactId, receiver);
        String[] toAddress = new String[] {email};
        mail.setToAddresses(toAddress);
       
        try {
            mail.setFileAttachments(getAntragFormular(contactId));
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );
            Follow_Up_Task_Helper.insertFollowUpTask(contact.Id, 'Formular per Email an '+ receiver +' versendet', 'Versand Formular an Interessent', System.today(), 'Geschlossen');
            //Follow_Up_Task_Helper.insertFollowUpTask(contact.Id, 'Nachtelefonie von Interessenten', 'Versand Formular an Interessent', dueDate, 'Offen');
            return 'Email wurde erfolgreich Versendet!';

        } catch (Exception e) {
            System.debug('Antrag_Formular' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }  
    }

    // send filled formular to client
    @AuraEnabled
    public static string sendFilledFormular(String contactId, String receiver){
        Contact contact = Curabox_Helper.getContactById(contactId);
        EmailTemplate template = Curabox_Helper.getTemplateByName('curabox_vorausgefuellt_per_email');
        Date dueDate = Follow_Up_Task_Helper.getDueDate(Due_Date__c.getValues('Formularversand').Follow_Up_Task_Due_Date__c);
       
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //replace merge fields --> Contact and Account
        String emailBody = setEmailData(contact, receiver, template.Body);
        String emailText = setEmailData(contact, receiver, template.HtmlValue);
            
        mail.setSaveAsActivity(true);
        mail.setSubject(template.Subject);
        mail.setPlainTextBody(emailBody);
        mail.setHtmlBody(emailText);
        String email = getReceiverEmail(contactId, receiver);
        String[] toAddress = new String[] {email};
        mail.setToAddresses(toAddress);
       
        try {
            mail.setFileAttachments(getFilledFormular(contactId));
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );
            Follow_Up_Task_Helper.insertFollowUpTask(contact.Id, 'Vorausgefüllter Formular per Email an ' + receiver +' versendet', 'Versand Formular an Interessent', System.today(), 'Geschlossen');
            //Follow_Up_Task_Helper.insertFollowUpTask(contact.Id, 'Nachtelefonie von Interessenten', 'Versand Formular an Interessent', dueDate, 'Offen');
            return 'Email wurde erfolgreich Versendet!';

        } catch (Exception e) {
            System.debug('Vorausgefüllt Antrag_Formular' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }  
    }

    // send confirmation mail to client or nursing service or mentor.
    @AuraEnabled
    public static string sendConfirmationToClient(String contactId, String receiver){
        Contact contact = Curabox_Helper.getContactById(contactId);
        EmailTemplate template = new EmailTemplate();
        if (contact.Kranken_Pflegekasse__r.Kanal_Unterpunkt__c == 'privat') {
            template = Curabox_Helper.getTemplateByName('curabox_empfangsschreiben_privat');
        }
        else if (contact.Kranken_Pflegekasse__r.Kanal_Unterpunkt__c == 'gesetzlich') {
            template = Curabox_Helper.getTemplateByName('curabox_empfangsschreiben_gesetzlich');
        }
        else {
            template = Curabox_Helper.getTemplateByName('curabox_empfangsschreiben_gesetzlich');
        }
       
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //replace merge fields --> Contact and Account
        String emailBody = setEmailData(contact, receiver, template.Body);
        String emailText = setEmailData(contact, receiver, template.HtmlValue);
            
        mail.setSaveAsActivity(true);
        mail.setSubject(template.Subject);
        mail.setPlainTextBody(emailBody);
        mail.setHtmlBody(emailText);
        String email = getReceiverEmail(contactId, receiver);
        String[] toAddress = new String[] {email};
        mail.setToAddresses(toAddress);
       
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );
            return 'Email wurde erfolgreich Versendet!';

        } catch (Exception e) {
            System.debug('Antrag_Formular' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }  
    }

    // get receiver email by contact and return this
    @AuraEnabled
    public static String getReceiverEmail(String contactId, String receiver){
        String email ='';
        Contact contact = Curabox_Helper.getContactById(contactId);
        String role = Curabox_Helper.getOpportunityByContact(contactId).Role;
        switch on receiver {
            when 'Pflegedienst' {
                email = contact.Pflegedienst__r.Email_Firma__c;
            }
            when 'AnsprechpartnerIn' {
                if (role == 'ASP') {
                    email = contact.Email;
                }
                else {
                    email = contact.Betreuer__r.Email;
                }
            }
            when 'Pflegebedürftiger' {
                email = contact.Email;
            }
            when else {
                email = null;  
            }
        } 
        return email;
    }

    // get receiver Id to generate correspondence and confirmation pdf.
    @AuraEnabled
    public static String getReceiverId(String contactId, String receiver){
        String receiverId ='';
        Contact contact = Curabox_Helper.getContactById(contactId);
        String role = Curabox_Helper.getOpportunityByContact(contactId).Role;
        switch on receiver {
            when 'Pflegedienst' {
                receiverId = contact.Pflegedienst__c;
            }
            when 'AnsprechpartnerIn' {
                if (role == 'ASP') {
                    receiverId = contact.Id;
                }
                else {
                    receiverId = contact.Betreuer__c;
                }
            }
            when 'Pflegebedürftiger' {
                receiverId = contact.Id;
            }
            when else {
                receiverId = null;  
            }
        } 
        return receiverId;
    }

    // set Filled Formular visibility
    @AuraEnabled
    public static Boolean setFilledButton(String contactId){
        Boolean retValue = false;
        ContentVersion attachment = fetchContentDocument(contactId);

        if (attachment.Id != null && String.isNotEmpty(attachment.Id)) {
            retValue = true;
        }
        return retValue;
    }

    // get the curabox 'Antrag Formular': Blanko
    public static  Messaging.EmailFileAttachment[] getAntragFormular(String contactId){
        Messaging.EmailFileAttachment[] fileAttachmentList = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        Contact c = [SElECT Account.Familien_ID__c FROM Contact WHERE ID = :contactId];
        //StaticResource attachment = [Select Id, Body from StaticResource where Name = 'Antrag_Formular' limit 1];
        Id pdfFormId = PDFForm.getFilledPdfForm('Antragsformular_Email', c.Account.Familien_ID__c, contactId);        
        if(pdfFormId != null){
            ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE ID = :pdfFormId];
            fileAttachment.setBody(cv.VersionData);
            fileAttachment.setFileName('Antrag_Formular.pdf');
            fileAttachment.setContentType('application/pdf');   
            fileAttachmentList.add(fileAttachment);
        }
        return fileAttachmentList;
    }

    // get the curabox 'Antrag Formular' by Contact: Vorausgefüllt
    public static  Messaging.EmailFileAttachment[] getFilledFormular(String contactId){
        Messaging.EmailFileAttachment[] fileAttachmentList = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        String role = Curabox_Helper.getOpportunityByContact(contactId).Role;
        if (role == 'PB') {
            Contact contact = Curabox_Helper.getContactById(contactId);
            if (contact.Betreuer__c != null && String.isNotEmpty(contact.Betreuer__c)) {
                contactId = contact.Betreuer__c;
            } 
        }
        // set attachment document for sending Email
        List<Id> idList = new List<Id>();
        List<ContentDocumentLink> cdl =[select Id,LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId =: contactId];
        if (cdl != null && cdl.size() > 0) {
            for (ContentDocumentLink cd : cdl) {
                idList.add(cd.ContentDocumentId);
            }
        }
        if (idList != null && idList.size() >0) {
            ContentVersion attachment = [select ID, versionData, FileType, Title From ContentVersion where IsLatest= true AND Title like 'CB_Formular%' AND ContentDocumentId In:idList order by CreatedDate Desc][0];
            if(attachment != null){
                fileAttachment.setBody(attachment.versionData);
                fileAttachment.setFileName('Antragsformular.pdf');
                fileAttachment.setContentType('application/pdf');   
                fileAttachmentList.add(fileAttachment);
            } 
        }
        return fileAttachmentList;
    }

    // replace fields in email text
    public static String setEmailData(Contact contact, String receiver, String emailBody){
        String role = Curabox_Helper.getOpportunityByContact(contact.Id).Role;
        switch on receiver {
            when 'Pflegedienst' {
                emailBody = emailBody.replace('$anredeformel$', 'Sehr geehrte Damen und Herren');
            }
            when 'AnsprechpartnerIn' {
                if (role == 'ASP') {
                    emailBody = emailBody.replace('$anredeformel$', getSalutation(contact.Salutation)+' '+ contact.Firstname +' '+ contact.LastName);
                }
                else {
                    emailBody = emailBody.replace('$anredeformel$', getSalutation(contact.Betreuer__r.Salutation)+' '+ contact.Betreuer__r.Firstname +' '+ contact.Betreuer__r.LastName);
                }
            }
            when 'Pflegebedürftiger' {
                emailBody = emailBody.replace('$anredeformel$', getSalutation(contact.Salutation)+' '+ contact.Firstname +' '+ contact.LastName);
            }
            when else { 
            }
        }
        return emailBody;
    }

    //
    public static String getSalutation(String salutation){
        String returnValue = '';
        if (salutation != null && !String.isEmpty(salutation)) {
            if (salutation == 'Frau') {
                returnValue = 'Sehr geehrte Frau';
            }
            else if (salutation == 'Herr') {
                returnValue = 'Sehr geehrter Herr';
            }
        }
        return returnValue;
    }

    // get application form to print
    @AuraEnabled 
    public static ContentVersion fetchContentDocument(String contactId){
        String role = Curabox_Helper.getOpportunityByContact(contactId).Role;
        // get Document to print
        List<Id> idList = new List<Id>();
        ContentVersion attachment = new ContentVersion();
        List<ContentDocumentLink> cdl =[select Id, LinkedEntityId, ContentDocumentId from ContentDocumentLink where LinkedEntityId =: contactId];
        if (cdl != null && cdl.size() > 0) {
            for (ContentDocumentLink cd : cdl) {
                idList.add(cd.ContentDocumentId);
            }
        }
        if (idList != null && idList.size() >0) {
            attachment = [select Id, versionData, FileType, Title, ContentDocumentId From ContentVersion where IsLatest= true AND Title like 'CB_Formular%' AND ContentDocumentId In:idList order by CreatedDate Desc][0];
        }
        return attachment;
    }

}