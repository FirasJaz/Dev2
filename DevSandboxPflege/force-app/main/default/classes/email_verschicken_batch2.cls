/*/****************************************************************************************************************************
// Erstellt 22.07.2016 von BT
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// verschickt Email an Kunden/Angehörige, wenn 6 Tage, Interessent und keine Telefonnummer
// 
//****************************************************************************************************************************
//Änderungen:    
// 27.10.2016   AM  alle SQL aus for{} raus. Da "Too many SOQL"    
// 02.11.2016   AM  Einbau von OrgWideEmailAddress         
// 27.02.2018   BT  Entfernen von dummy-Zeilen
// 15.08.2018   SD  Case 1595 (SD1595)
//                  Den Kundenstatus-Satz erst nach der zweite Erinnerungsemail als abgeschlossen markieren
// 09.10.2018	MS	Case 1752
// 					Dritte Erinnerungsmail nach 90 Tagen.
// 					Jeder Kunde über 90 Tagen, der noch Status=Interessent hat, kriegt eine Email und dann wird der Vorgang geschlossen                                   
//****************************************************************************************************************************
*/
global class email_verschicken_batch2 implements Database.Batchable<sObject>{

    global Date datum6; 
    global Date datum15; 
    global Date datum91;
    
    // public List<Kunde__c> kdList = new List<Kunde__c>();
    // public set<Id> kdIdSet = new set<Id>();
    public User currentUser;

    global email_verschicken_batch2() {
        this.datum6 = date.today().addDays(-6);
        this.datum15 = date.today().addDays(-15);
        this.datum91 = date.today().addDays(-91);
    }
    
    global Database.querylocator start(Database.BatchableContext BC) {
        
        string query = 'SELECT id, Kunde__c, Produktgruppe__c, Anzahl_Erinnerung_Email__c, Status__c, ' + 
                        'Kunde__r.Betreuer__c, Kunde__r.Betreuer__r.Email, Kunde__r.e_mail__c, Kunde__r.Betreuer__r.lastname, ' +
                        'Kunde__r.Anrede_Formel_Email__c, Kunde__r.Name__c, Kunde__r.Betreuer__r.Anrede_Text_Marketing__c, Kunde__r.Erstelldatum__c ' +
                        'FROM Kundenstatus__c ' +
                        'WHERE ( Produktgruppe__c = \'PG54\' or Produktgruppe__c = \'PG51\' ) ' +
                        'AND (Anzahl_Erinnerung_Email__c < 3 OR Anzahl_Erinnerung_Email__c = null) ' +
                        'AND Status__c = \'Interessent\' ' + 
                        'AND ( Kunde__r.Erstelldatum__c = :datum15 ' +
                        	'OR Kunde__r.Erstelldatum__c = :datum6 ' +
                        	'OR Kunde__r.Erstelldatum__c <= :datum91 )'; 
                       // 'AND Kunde__r.Email_Opt_Out__c = false';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        set<Id> kdIdSet = new set<Id>();
        set<Id> sendetKdIdSet = new set<Id>();
        set<Id> plannedForNachtelefonieSet = new set<Id>();   
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
        
        List<EmailTemplate> etKdList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  
                                            from EmailTemplate 
                                            where DeveloperName = 'Pflege_zuhause_kostenfreie_Unterst_tzung_erhalten' limit 1];

        List<EmailTemplate> etAgList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  
                                            from EmailTemplate 
                                            where DeveloperName = 'Pflege_zuhause_kostenfreie_Unterst_tzung_erhalten_ang' limit 1];                            
        
        list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>();  

        List<Kundenstatus__c> ksList =(List<Kundenstatus__c>)scope;   
        for(Kundenstatus__c ks : ksList) {  
            kdIdSet.add(ks.Kunde__c);
        }

        //** exclude customers that are planned for follow-up via telephone  
        if(kdIdSet != null && kdIdSet.size() != 0) {
            list<task> tkList = [SELECT id, whatId, subject
                                    FROM task
                                    WHERE  whatId IN: kdIdSet
                                    AND subject = 'Nachtelefonie von Interessenten'];   
            if(tkList != null && tkList.size() != 0) {               
                for(Task tk: tkList) {
                    plannedForNachtelefonieSet.add(tk.whatId);
                }
            }
        }


        for(Kundenstatus__c ks : ksList) {
            if(!plannedForNachtelefonieSet.contains(ks.Kunde__c)) {
                if(!sendetKdIdSet.contains(ks.Kunde__c)) {
                    try {
                        sendetKdIdSet.add(ks.Kunde__c);                                        
                        String[] toAddresses;                
                        String htmlValue;                  
                        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();                            
                        msg.setWhatId(ks.Kunde__r.id);
                        msg.setOrgWideEmailAddressId(owID);
                        if(ks.Kunde__r.e_mail__c != null || ks.Kunde__r.Betreuer__r.Email != null) {   
                            if(ks.Anzahl_Erinnerung_Email__c == null) {
                                ks.Anzahl_Erinnerung_Email__c = 0;
                            }
                            if(((ks.Anzahl_Erinnerung_Email__c == 1) && (ks.Kunde__r.Erstelldatum__c == this.datum15)) 
                            || ((ks.Anzahl_Erinnerung_Email__c == 0) && (ks.Kunde__r.Erstelldatum__c == this.datum6)) 
                            || ks.Kunde__r.Erstelldatum__c <= this.datum91) {

                                ks.Anzahl_Erinnerung_Email__c++;
                                
                                if(ks.Anzahl_Erinnerung_Email__c == 3
                                  || ks.Kunde__r.Erstelldatum__c <= this.datum91) {
                                      // If Erstelldatum__c more than 90 days ago => close Vorgang
                                      // because otherwise it is possible that some stay "Interessent" forever...
                                    ks.Status__c = 'Vorgang geschlossen';
                                }

                                if(ks.Kunde__r.e_mail__c != null) {                  
                                    toAddresses = new String[] {ks.Kunde__r.e_mail__c};                   
                                    htmlValue = etKdList[0].htmlValue;
                                    htmlValue = setKdRecipientFields(htmlValue, ks.Kunde__r.Anrede_Formel_Email__c, ks.Kunde__r.Name__c);
                                    htmlValue = setUserfields(htmlValue);   
                                    msg.setTemplateId(etKdList[0].Id);   
                                    msg.setToAddresses(toAddresses);              
                                    msg.setPlainTextBody(etKdList[0].body);
                                    msg.setSubject(etKdList[0].subject);
                                    msg.setHtmlBody(htmlValue);
                                }
                                else if(ks.Kunde__r.Betreuer__r.Email != null){                  
                                    htmlValue = etAgList[0].htmlValue;
                                    htmlValue = setAgRecipientFields(htmlValue, ks.Kunde__r.Betreuer__r.Anrede_Text_Marketing__c, ks.Kunde__r.Betreuer__r.lastname);
                                    htmlValue = setUserfields(htmlValue);   
                                    msg.setTemplateId(etAgList[0].Id);               
                                    msg.setTargetObjectId(ks.Kunde__r.Betreuer__c);                  
                                    msg.setPlainTextBody(etAgList[0].body);
                                    msg.setSubject(etAgList[0].subject);        
                                    msg.setHtmlBody(htmlValue);          
                                }
                                mails.add(msg);   
                            }          
                        }   
                    }
                    catch(system.exception e){
                        system.debug('##############BT2016: Email Erstellen fehlgeschagen ' + e);
                    } 
                }
            }                    
        }
        try {
            Messaging.sendEmail(mails);
            update ksList; 
        }
        catch(system.exception e){
            system.debug('##############BT2016_01: Email Versenden fehlgeschagen ' + e);
        }                              
    }
    
    public void setCurrentUser(){
            List<User> uList = [select Id, Fax, phone, email from User where Id = :UserInfo.getUserId() limit 1];       
            if(uList != null && uList.size()>0){
                currentUser = uList [0];
            }   
    }

    public String setUserfields(String str){    
            if(currentUser  != null){
                if(currentUser.Phone!= null) { str = str.replace('{!User.Phone}', currentUser.Phone);}else{str = str.replace('{!User.Phone}', ' ' );}
                if(currentUser.Fax!= null) { str = str.replace('{!User.Fax}', currentUser.Fax);}else{str = str.replace('{!User.Fax}', ' ');}
                if(currentUser.Email!= null) { str = str.replace('{!User.Email}', currentUser.Email );}else{str = str.replace('{!User.Email}', ' ' );}
            }
            return str;
    }

    public String setAgRecipientFields(String str, String salutation, String lastname){
            if(salutation != null) {str = str.replace('{!Contact.Anrede_Text_Marketing__c}', salutation);}else{str = str.replace('{!Contact.Anrede_Text_Marketing__c}', ' ');}
            if(lastname != null) {str = str.replace('{!Contact.LastName}', lastname);}else{str = str.replace('{!Contact.LastName}', ' ');}
            return str; 
    }      
        
    public String setKdRecipientFields(String str, String salutation, String lastname){
            if(salutation != null) {str = str.replace('{!Kunde__c.Anrede_Formel_Email__c}', salutation);}else{str = str.replace('{!Kunde__c.Anrede_Formel_Email__c}', ' ');}
            if(lastname != null) {str = str.replace('{!Kunde__c.Name__c}', lastname);}else{str = str.replace('{!Kunde__c.Name__c}', ' ');}
            return str; 
    }   
    
    global void finish(Database.BatchableContext BC){}        
}