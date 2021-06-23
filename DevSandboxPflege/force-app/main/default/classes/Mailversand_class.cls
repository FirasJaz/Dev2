//****************************************************************************************************************************
// Created on 02.08.2019   by BT
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// None
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//          Sends mails to contacts
//
//
//****************************************************************************************************************************
//Änderungen:
//    
//****************************************************************************************************************************

public class Mailversand_class {
    public static User currentUser;   
    public static boolean error;
    
    public static void sendMail(Set<id> KundenIdSet, string etName) {
        error = false;
        map<id, Contact> pdIdToContMap = new map<id, Contact>();
        
        List<EmailTemplate> etList =  new List<EmailTemplate>([select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  
                                              from EmailTemplate 
                                              where DeveloperName =: etName limit 1]);
        
        List<contact_address__c> anList = new List<contact_address__c>([select Email__c, Contact__r.Salutation, Name, Type_of_Address__c,
                                     Standard_shipping_address__c, Contact__c, Contact__r.Pflegedienst__c
                                     from contact_address__c
                                     where Contact__c IN: KundenIdSet
                                     and Standard_shipping_address__c = true]);                                                                          
        
        ID owID = null;
        List<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress WHERE DisplayName = 'Curabox Kundenservice' limit 1];
            
        try {
            owID = owa[0].id;    
        }
        catch (System.Exception e) {
            System.debug(logginglevel.error, '########################## keine OrgWideEmailAddress gefunden!'); 
            owID = null;
        }
        
        setCurrentUser();
        
        list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>();
                
        if(etName.contains('Curabox_Ablehnung')) {
            set<id> pdIdSet = new set<id>();
            
            for(contact_address__c ans: anList) {
                if(ans.Type_of_Address__c == 'Pflegedienst') {
                    pdIdSet.add(ans.Contact__r.Pflegedienst__c);                    
                }                                
            }
            
            List<Contact> contList = new List<Contact>([select id, Email, salutation, AccountId, Name
                                                            from Contact
                                                            where AccountId in: pdIdSet
                                                            order by Name]);
            
            for(Contact cont: contList) {
                if(pdIdToContMap.get(cont.AccountId) == null) pdIdToContMap.put(cont.AccountId, cont);
            }
        }
        
        for(contact_address__c an: anList) {
            if(etList.size() > 0) {
                try {
                    if(etName == 'Curabox_ist_PG51_gew_nscht' && an.Type_of_Address__c != 'Pflegedienst' ||
                                        etName.contains('Curabox_Ablehnung')) {
                        String[] toAddresses;
                        String htmlValue;
                    
                        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage(); 
                        msg.SetTargetObjectId(an.Contact__c);                        
                        msg.setOrgWideEmailAddressId(owID);
                                                         
                        htmlValue = etList[0].htmlValue;
                        
                        if(an.Type_of_Address__c != 'Kundenadresse') {
                            List<Contact> kdList = [select id, Salutation, Name, LastName from Contact where id =: an.Contact__c];
                            htmlValue = setKdRecipientFields(htmlValue, etName, kdList[0].salutation, kdList[0].Name);
                        } 
                        
                        if(etName.contains('Curabox_Ablehnung') && an.Type_of_Address__c == 'Pflegedienst') {
                            if(pdIdToContMap.get(an.Contact__r.Pflegedienst__c) != null) {
                                htmlValue = setCtRecipientFields(htmlValue, pdIdToContMap.get(an.Contact__r.Pflegedienst__c).salutation, pdIdToContMap.get(an.Contact__r.Pflegedienst__c).LastName);
                                toAddresses = new String[] {pdIdToContMap.get(an.Contact__r.Pflegedienst__c).Email}; 
                            }
                        }
                        else {
                            htmlValue = setCtRecipientFields(htmlValue, an.Contact__r.Salutation, an.Name);
                            toAddresses = new String[] {an.Email__c}; 
                        }
                        
                        htmlValue = setUserfields(htmlValue);                       
                        msg.setTemplateId(etList[0].Id);   
                        msg.setToAddresses(toAddresses);              
                        msg.setPlainTextBody(etList[0].body);
                        msg.setSubject(etList[0].subject);
                        msg.setHtmlBody(htmlValue);
                        
                        if(etName == 'Curabox_Ablehnung_anderer_LE') {
                            
                            List<StaticResource> objPDF = [Select body, name from StaticResource where Name = 'Abtretungserklaerung'];
                                                
                            if(objPDF != null && objPDF.size() > 0) {
                                Messaging.EmailFileAttachment[] emAtt = new Messaging.EmailFileAttachment[1];
                                Messaging.EmailFileAttachment pdfAtt = new Messaging.EmailFileAttachment();
                                pdfAtt.setBody(objPDF[0].Body);
                                pdfAtt.setFileName('Abtretungserklärung.pdf');
                                emAtt[0] = pdfAtt;
                                msg.setFileAttachments(emAtt);  
                            }                  
                        }
                        
                        if(etName == 'Curabox_ist_PG51_gew_nscht'){
                            
                            List<StaticResource> objPDF = [Select body, name from StaticResource where Name = 'Formular_Betteinlagen'];
                                                
                            if(objPDF != null && objPDF.size() > 0) {
                                Messaging.EmailFileAttachment[] emAtt = new Messaging.EmailFileAttachment[1];
                                Messaging.EmailFileAttachment pdfAtt = new Messaging.EmailFileAttachment();
                                pdfAtt.setBody(objPDF[0].Body);
                                pdfAtt.setFileName('Formular_Betteinlagen.pdf');
                                emAtt[0] = pdfAtt;
                                msg.setFileAttachments(emAtt);  
                            }                       
                        }
                        
                        if(toAddresses == null || toAddresses != null && toAddresses[0] == null){
                            error = true;
                        }
                        else {
                            mails.add(msg);                                                                                            
                        }                     

                    }              
                }
                catch(system.exception e) {
                    system.debug('#########BT2017 Mail konnte nicht erstellt werden ! error =' + e.getMessage());
                }
            }  
            else {
                system.debug('###########BT2017 Es konnte keine E-Mail-Vorlage gefunden werden !');
            }          
       }      
        
       if(mails.size() > 0) {
            try {
                Messaging.sendEmail(mails);
            }
            catch(system.exception e) {
                system.debug('#########BT2017 Mails konnten nicht versendet werden !');
            }
       }          
    }   

    public static void sendMail(id kdId, string etName) {
        sendMail(new set<id>{kdId}, etName);
    }            
    
    public static void setCurrentUser(){
            List<User> uList = [select Id, Fax, phone, email from User where Id = :UserInfo.getUserId() limit 1];
       
            if(uList != null && uList.size()>0){
                currentUser = uList [0];
            }   
    }
    
    public static String setUserfields(String str){    
            if(currentUser  != null){
                if(currentUser.Phone!= null) { str = str.replace('{!User.Phone}', currentUser.Phone);}else{str = str.replace('{!User.Phone}', ' ' );}
                if(currentUser.Fax!= null) { str = str.replace('{!User.Fax}', currentUser.Fax);}else{str = str.replace('{!User.Fax}', ' ');}
                if(currentUser.Email!= null) { str = str.replace('{!User.Email}', currentUser.Email );}else{str = str.replace('{!User.Email}', ' ' );}
            }
            return str;
    }          
        
    public static String setCtRecipientFields(String str, String salutation, String lastname){    
            if(salutation != null) {
                if(salutation == 'Herr') {
                    str = str.replace('{!Contact.Anrede_Text_Marketing__c}', 'Sehr geehrter Herr');
                }
                
                if(salutation == 'Frau') {
                    str = str.replace('{!Contact.Anrede_Text_Marketing__c}', 'Sehr geehrte Frau');
                }
            }
            else{
                str = str.replace('{!Contact.Anrede_Text_Marketing__c}', ' ');
            }
            
            if(lastname != null)  {
                if(lastname.contains(',')) {
                    if(lastname.substring(lastname.indexOf(',') + 1, lastname.length()) == 'null') {
                        str = str.replace('{!Contact.LastName}', lastname.substring(0, lastname.indexOf(',')));
                    }
                    else {
                        str = str.replace('{!Contact.LastName}', lastname.substring(lastname.indexOf(',') + 1, lastname.length()) + ' ' + lastname.substring(0, lastname.indexOf(',')));
                    }
                } else {
                    str = str.replace('{!Contact.LastName}', lastname);
                }                
            }
            else{
                str = str.replace('{!Contact.LastName}', ' ');
            }
            
            return str; 
    }       
    
    public static String setKdRecipientFields(String str, String etName, String kdAnrede, String kdname) {
            String kd_anrede = '';
            String kd_name = '';
            if(kdAnrede != null) {
                kd_anrede = kdAnrede;
            }            
            
            kd_name = kdname;
                                     
                
            if(etName == 'Curabox_ist_PG51_gew_nscht' || etName == 'Curabox_Ablehnung_kein_Pflegegrad' || etName == 'Curabox_Ablehnung_anderer_LE') {
                if(kd_anrede.contains('Herr')) {
                    str = str.replace('in Form der curabox', 'in Form der curabox für Herrn ' + kd_name);
                }
                if(kd_anrede.contains('Frau')) {
                    str = str.replace('in Form der curabox', 'in Form der curabox für Frau ' + kd_name);
                }
                
                if(etName == 'Curabox_Ablehnung_kein_Pflegegrad' || etName == 'Curabox_Ablehnung_anderer_LE') {
                    str = str.replace('Ihre Pflegekasse', 'Die Pflegekasse');
                }
                
                if(etName == 'Curabox_Ablehnung_anderer_LE') {
                    if(kd_anrede.contains('Herr')) {
                        str = str.replace('Wenn Sie Ihren Bedarf zukünftig', 'Wenn Herr ' + kd_name + ' seinen Bedarf zukünftig');
                        str = str.replace('über uns beziehen möchten', 'über uns beziehen möchte');
                    }
                    if(kd_anrede.contains('Frau')) {
                        str = str.replace('Wenn Sie Ihren Bedarf zukünftig', 'Wenn Frau ' + kd_name + ' ihren Bedarf zukünftig');
                        str = str.replace('über uns beziehen möchten', 'über uns beziehen möchte');
                    }         
                    
                    str = str.replace('Schritte für Sie und können Ihnen zeitnah die curabox', 'Schritte und können die curabox zeitnah');           
                }
                
            }
            
            if(etName == 'Curabox_Ablehnung_keine_Pflegeperson'){
                if(kd_anrede.contains('Herr')) {
                    str = str.replace('sehr gerne würden wir Sie', 'sehr gerne würden wir Sie für Herrn ' + kd_name);
                    str = str.replace('bzw. haben Sie', 'bzw. hat Herr ' + kd_name);
                }
                if(kd_anrede.contains('Frau')) {
                    str = str.replace('sehr gerne würden wir Sie', 'sehr gerne würden wir Sie für Frau ' + kd_name);  
                    str = str.replace('bzw. haben Sie', 'bzw. hat Frau ' + kd_name);              
                }
            }
                       
            return str;
    }
    
}