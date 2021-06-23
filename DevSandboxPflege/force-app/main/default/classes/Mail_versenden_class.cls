//****************************************************************************************************************************
// Erstellt 12.04.2017     von BT
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
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Sendet Mails an Kunden
//
//
//****************************************************************************************************************************
//Änderungen:
//    12.05.2017    BT    Anhang bei der E-Mail
//    17.05.2017    BT    keine Fehlermeldung und kein Mailversand, wenn keine E-Mail-Adresse vorhanden ist.
//****************************************************************************************************************************

public class Mail_versenden_class {
    public static User currentUser;   
    public static boolean error;
    
    public static void sendMail(Set<id> KundenIdSet, string etName) {
        error = false;
        map<id, Contact> pdIdToContMap = new map<id, Contact>();
        
        List<EmailTemplate> etList =  new List<EmailTemplate>([select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  
                                              from EmailTemplate 
                                              where DeveloperName =: etName limit 1]);
        
        List<Anschrift__c> anList = new List<Anschrift__c>([select e_mail__c, Anrede__c, Name, Art_der_Anschrift__c,
                                     Standardlieferanschrift__c, Kunde__c, Kunde__r.Pflegedienst__c
                                     from Anschrift__c
                                     where Kunde__c IN: KundenIdSet
                                     and Standardlieferanschrift__c = true]);                                                                          
        
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
            
            for(Anschrift__c ans: anList) {
                if(ans.Art_der_Anschrift__c == 'Pflegedienst') {
                    pdIdSet.add(ans.Kunde__r.Pflegedienst__c);                    
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
        
        for(Anschrift__c an: anList) {
            if(etList.size() > 0) {
                try {
                    if(etName == 'Curabox_ist_PG51_gew_nscht' && an.Art_der_Anschrift__c != 'Pflegedienst' ||
                                        etName.contains('Curabox_Ablehnung')) {
                        String[] toAddresses;
                        String htmlValue;
                    
                        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage(); 
                        msg.setWhatId(an.Kunde__c);
                        msg.setOrgWideEmailAddressId(owID);
                                                         
                        htmlValue = etList[0].htmlValue;
                        
                        if(an.Art_der_Anschrift__c != 'Kundenadresse') {
                            List<Kunde__c> kdList = [select id, Anrede__c, Name, Name__c from Kunde__c where id =: an.Kunde__c];
                            htmlValue = setKdRecipientFields(htmlValue, etName, kdList[0].Anrede__c, kdList[0].Name);
                        } 
                        
                        if(etName.contains('Curabox_Ablehnung') && an.Art_der_Anschrift__c == 'Pflegedienst') {
                            if(pdIdToContMap.get(an.Kunde__r.Pflegedienst__c) != null) {
                                htmlValue = setCtRecipientFields(htmlValue, pdIdToContMap.get(an.Kunde__r.Pflegedienst__c).salutation, pdIdToContMap.get(an.Kunde__r.Pflegedienst__c).Name);
                                toAddresses = new String[] {pdIdToContMap.get(an.Kunde__r.Pflegedienst__c).Email}; 
                            }
                        }
                        else {
                            htmlValue = setCtRecipientFields(htmlValue, an.Anrede__c, an.Name);
                            toAddresses = new String[] {an.e_mail__c}; 
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
                    system.debug('#########BT2017 Mail konnte nicht erstellt werden !');
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
                    str = str.replace('{!Kunde__c.Anrede_Formel_Email__c}', 'Sehr geehrter Herr');
                }
                
                if(salutation == 'Frau') {
                    str = str.replace('{!Kunde__c.Anrede_Formel_Email__c}', 'Sehr geehrte Frau');
                }
            }
            else{
                str = str.replace('{!Kunde__c.Anrede_Formel_Email__c}', ' ');
            }
            
            if(lastname != null)  {
                if(lastname.contains(',')) {
                    if(lastname.substring(lastname.indexOf(',') + 1, lastname.length()) == 'null') {
                        str = str.replace('{!Kunde__c.Name__c}', lastname.substring(0, lastname.indexOf(',')));
                    }
                    else {
                        str = str.replace('{!Kunde__c.Name__c}', lastname.substring(lastname.indexOf(',') + 1, lastname.length()) + ' ' + lastname.substring(0, lastname.indexOf(',')));
                    }
                } else {
                    str = str.replace('{!Kunde__c.Name__c}', lastname);
                }                
            }
            else{
                str = str.replace('{!Kunde__c.Name__c}', ' ');
            }
            
            return str; 
    }       
    
    public static String setKdRecipientFields(String str, String etName, String kdAnrede, String kdname) {
            String kd_anrede = '';
            String kd_name = '';
            if(kdAnrede != null) {
                kd_anrede = kdAnrede;
            }            
            
            if(kdname.substring(kdname.indexOf(',') + 2, kdname.length()) == 'null') {
                kd_name = kdname.substring(0, kdname.indexOf(','));
            }
            else {
                kd_name = kdname.substring(kdname.indexOf(',') + 2, kdname.length()) + ' ' + kdname.substring(0, kdname.indexOf(','));
            }                           
                
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