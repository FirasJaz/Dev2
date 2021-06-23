/*/****************************************************************************************************************************
// Erstellt 10.03.2016 von AM
//          Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//          Nordkanalstrasse 58
//          20097 Hamburg 
//          Tel.:  04064917161
//          Fax.:  04064917162
//          Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung: Emails bearbeiten 
//                      
//
//
//****************************************************************************************************************************
// Änderungen:
// 18.03.2016 - Änderung Email von Thomas Kaplanski zu Mara Engel
// 21.03.2016 von AM - #115928089 Custom Settings Einbauen (Empf_nger_Email_Adresse__c)
// 24.10.2016 von AM - trim() auf campaign Name beim Zuordnen. Wenn nicht gefunden - error
//****************************************************************************************************************************/
public class ksgEmailBearbeiten { 
    private list<contact> ctList = new list<contact>();
    private list<task> tsList = new list<task>();
    private list<attachment> atList = new list<attachment>();
    private set<string> fwSet = new set<string>();
    private String fromAddr = null;
    private id asid = UserInfo.getUserId();
    
    private lead LD = new lead(Company = 'curabox');
    
    private Emailtolead__c emailtolead {get; set;}
    
    // public ksgEmailBearbeiten() {}
    
    public ksgEmailBearbeiten(Messaging.InboundEmail email) {
        
        if(email.plainTextBody != null) {
            boolean error = false;
            String emailBody = email.plainTextBody;
            String[] emailBodyList = emailBody.split('\n', 0);  
            String fwMail = null;
            boolean anfang = false;
            boolean ende = false;
            if(emailBodyList.size() > 0) {
                for(integer i= 0; i<emailBodyList.size(); i++) {
                    system.debug('###############################plaintext i=' + i + ' line=' + emailBodyList[i]);
                    if(emailBodyList[i].contains('Nächster Schritt')) anfang = true;
                    if(emailBodyList[i].contains('CRM Ticket ')) ende = true;
                    if(anfang) {
                        error = fieldsMapping(emailBodyList[i]);
                    }
                    if(ende) break;                 
                }
            }
            if(LD.lastname != null) {
                id rtid = null;                                
                list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name = 'Curabox'];
                if((rtList != null) && (rtList.size() > 0)) {
                    rtId = rtList[0].id;
                }
                LD.RecordTypeID = rtid;
                
                try {
                    insert LD;
                }
                catch(System.Exception e) {
                    system.debug('############################### insert lead error e=' + e);
                }               
            }
            else {
                createUnresolvedItem(email);
            }
        }
        
        if(email.htmlBody != null) {
            String htmlBody = email.htmlBody;
            String[] htmlBodyList = htmlBody.split('\n', 0);  
            String fwMail = null;
            if(htmlBodyList.size() > 0) {
                for(integer i= 0; i<htmlBodyList.size(); i++) {
                                   
                    try{
                        system.debug('###############################html i=' + i + ' line=' + htmlBodyList[i]);
                    }
                    catch (System.Exception e) {}
                    
                }
            }           
        }
    }
        
    public boolean fieldsMapping(string inputLine) {
        boolean error = false;
            try {
                string[] mLine = inputLine.split(':');
                if (mLine[0].contains('Angehöriger')) {
                    if (mLine[0].contains('Angehöriger Anrede')) {
                        LD.Angehoeriger_Anrede__c = mLine[1];
                    } else if (mLine[0].contains('Angehöriger Vorname')) {
                        LD.Angehoeriger_Vorname__c = mLine[1];
                    } else if (mLine[0].contains('Angehöriger Nachname')) {
                        LD.Angehoeriger_Nachname__c = mLine[1];
                    } else if (mLine[0].contains('Angehöriger Stra')) {
                        LD.Angehoeriger_Strasse__c = mLine[1];
                    } else if (mLine[0].contains('Angehöriger PLZ')) {
                        LD.Angehoeriger_PLZ__c = mLine[1];
                    } else if (mLine[0].contains('Angehöriger Ort')) {
                        LD.Angehoeriger_Ort__c = mLine[1];
                    } else if (mLine[0].contains('Angehöriger Telefon')) {
                        LD.Angehoeriger_Telefon__c = mLine[1];
                    } else if (mLine[0].contains('Angehöriger Mobile')) {
                        LD.Angeh_riger_Mobile__c = mLine[1];                
                    } else if (mLine[0].contains('Angehöriger Email')) {
                        LD.Angehoeriger_Email__c = mLine[1];
                    } else {
                        error = true;
                    }           
                }
                else {
                    if(mLine[0].contains('Nächster Schritt')) {
                        LD.next_Step__c = mLine[1];
                    } else if (mLine[0].contains('Salutation')) {
                        LD.Salutation = mLine[1];
                    } else if (mLine[0].contains('First Name')) {
                        LD.firstname = mLine[1];
                    } else if (mLine[0].contains('Last Name')) {
                        LD.lastname = mLine[1];
                    } else if (mLine[0].contains('Street')) {
                        LD.Street = mLine[1];
                    } else if (mLine[0].contains('Zip')) {
                        LD.PostalCode = mLine[1];
                    } else if (mLine[0].contains('City')) {
                        LD.City = mLine[1];
                    } else if (mLine[0].contains('Email')) {
                        LD.Email = mLine[1];
                    } else if (mLine[0].contains('Phone')) {
                        LD.Phone = mLine[1];
                    } else if (mLine[0].contains('Mobile')) {
                        LD.MobilePhone = mLine[1];  
                    } else if (mLine[0].contains('Ursprungsanfrage')) {
                        string caName = mLine[1].trim();
                        List<Campaign> cmplist = [select id, name from Campaign where name =: caName LIMIT 1];        
                        if(cmplist != null && cmplist.size() > 0) { 
                            LD.OM_Wizzard_Name2__c = cmplist[0].Id; 
                        }
                        else {
                            system.debug('################################ error: Campaign nicht gefunden. Campaign Name: '  + caName);
                            return true;
                        }
                    } else if (mLine[0].contains('Mitarbeiter')) {
                        LD.Mitarbeiter__c = mLine[1];
                    } else if (mLine[0].contains('Pflegestufe')) {
                        LD.Pflegestufe__c = mLine[1];
                    } else if (mLine[0].contains('Pflegegrad')) {
                        LD.Pflegegrad__c = mLine[1];                        
                    } else if (mLine[0].contains('CRM Ticket ID')) {
                        LD.CRM_Ticket_ID__c = mLine[1];                     
                    } else {
                        error = true;
                    }
                }
            } 
            catch (System.Exception e) {
                error = true;
            }
        return error;
    }
        
    public void createUnresolvedItem(Messaging.InboundEmail email) {
        string mailto = 'mara.engel@pflege.de';
        try {
            mailto = Emailtolead__c.getValues('curabox').Empf_nger_Email_Adresse__c;
        } catch(System.Exception e) {}
        
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();         
        mail.setToAddresses(new String[] {mailto});
        mail.setSubject(email.subject);
        mail.setPlainTextBody(email.plainTextBody);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });             
            }
        catch (System.Exception e)
        {
            system.debug('#########################email####### error '  + e);
        }
    }   
    
}