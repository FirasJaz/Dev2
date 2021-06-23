/*/****************************************************************************************************************************
// Erstellt 22.07.2016 von BT
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
// 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// verschickt Email an Kunden/Angehörige, wenn 6 Tage, Interessent und keine Telefonnummer
//
//
//****************************************************************************************************************************
//Änderungen:    
// 27.10.2016   AM  alle SQL aus for{} raus. Da "Too many SOQL"                                                    
//****************************************************************************************************************************
*/
global class email_verschicken_batch implements Database.Batchable<sObject>{
    global String query = 'Select Id from Kunde__c LIMIT 1';
    public List<Kunde__c> kdList = new List<Kunde__c>();
    public set<Id> kdIdSet = new set<Id>();
    public User currentUser;
   
    
    global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){                              
      Date heute = date.today()-6;
      Date datum = heute;
      
      kdList = [select id, Telefon__c, Erstelldatum__c
                 from Kunde__c
                 where Erstelldatum__c <=: datum
                 and Telefon__c = null];  

      if(kdList != null && kdList.size() != 0){
          for(Kunde__c kd: kdList){
              kdIdSet.add(kd.id);
          }
      }
      List<Kundenstatus__c> ksList = new List<Kundenstatus__c>();
      if(kdIdSet != null && kdIdSet.size() != 0) {
          ksList = [select id, Kunde__c, Produktgruppe__c, Status__c
                                          from Kundenstatus__c
                                          where Kunde__c IN: kdIdSet
                                          and ( Produktgruppe__c = 'PG54' or Produktgruppe__c = 'PG51' )
                                          and Status__c = 'Interessent'];
          
          if(ksList != null && ksList.size() != 0){
              kdIdSet.clear();
              
              for(Kundenstatus__c ks: ksList){
                  kdIdSet.add(ks.Kunde__c);
              }
          }
       }
       
       if(kdIdSet != null && kdIdSet.size() != 0) {
           List<Task> tkList = [select id, whatId, subject
                                from Task
                                where  whatId IN: kdIdSet
                                and subject = 'Nachtelefonie von Interessenten'];
           
           if(tkList != null && tkList.size() != 0) {               
               for(Task tk: tkList){
                   kdIdSet.remove(tk.whatId);
               }
           }
       }
       
       if(kdIdSet != null && kdIdSet.size() != 0) {
            kdList = [select id, Betreuer__c, Betreuer__r.Email, e_mail__c, Betreuer__r.lastname,
                     Kunde__c.Anrede_Formel_Email__c, Name__c, Betreuer__r.Anrede_Text_Marketing__c
                     from Kunde__c
                     where id IN: kdIdSet]; 
                     
            setCurrentUser();

            List<EmailTemplate> etKdList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  
                                              from EmailTemplate 
                                              where DeveloperName = 'Pflege_zuhause_kostenfreie_Unterst_tzung_erhalten' limit 1];

            List<EmailTemplate> etAgList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  
                                              from EmailTemplate 
                                              where DeveloperName = 'Pflege_zuhause_kostenfreie_Unterst_tzung_erhalten_ang' limit 1];                            
           
            list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>();      
            for(Kunde__c kd :kdList) {
          // Kunde__c kd = kdList[0];                       
                try {                                           
                    String[] toAddresses;                
                    String htmlValue;
                  
                    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();                            
                    msg.setWhatId(kd.id);
                  
                    if(kd.e_mail__c != null || kd.Betreuer__r.Email != null) {                
                        if(kd.e_mail__c != null) {                  
                              toAddresses = new String[] {kd.e_mail__c};                   
                              htmlValue = etKdList[0].htmlValue;
                              htmlValue = setKdRecipientFields(htmlValue, Kd.Anrede_Formel_Email__c, Kd.Name__c);
                              htmlValue = setUserfields(htmlValue);   
                              msg.setTemplateId(etKdList[0].Id);   
                              msg.setToAddresses(toAddresses);              
                              msg.setPlainTextBody(etKdList[0].body);
                              msg.setSubject(etKdList[0].subject);
                              msg.setHtmlBody(htmlValue);
                        }
                        else if(kd.Betreuer__r.Email != null){                  
                              //toAddresses = new String[] {kd.Betreuer__r.Email}; 
                              htmlValue = etAgList[0].htmlValue;
                              htmlValue = setAgRecipientFields(htmlValue, kd.Betreuer__r.Anrede_Text_Marketing__c, Kd.Betreuer__r.lastname);
                              htmlValue = setUserfields(htmlValue);   
                              msg.setTemplateId(etAgList[0].Id);               
                              msg.setTargetObjectId(kd.Betreuer__c);                  
                              msg.setPlainTextBody(etAgList[0].body);
                              msg.setSubject(etAgList[0].subject);        
                              msg.setHtmlBody(htmlValue);          
                        }
                        mails.add(msg);
                        // Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg });               
                    }   
                    system.debug('######BT2016  gut gelaufen !!!');
                }
                catch(system.exception e){
                    system.debug('##############BT2016: Email Erstellen fehlgeschagen ' + e);
                }                     
            }
            try {
                Messaging.sendEmail(mails);
            }
            catch(system.exception e){
                system.debug('##############BT2016_01: Email Versenden fehlgeschagen ' + e);
            }           
            
            for(Kundenstatus__c ks : ksList){
                    ks.Status__c = 'Vorgang geschlossen';
            }
            try {
                update ksList; 
            }
            catch (System.Exception e) {
                system.debug('##############BT2016: update ksList e=' + e);
            }
                     
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
    
        // wird nicht aufgerufen! Nur für Testabdeckung!!!  
    public class dummyZeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;} 
                        public string th {get; set;}
                        public string thu {get; set;}
                        public string lDatum {get; set;}
                        public string stern {get; set;}
    }

    // wird nicht aufgerufen! Nur für Testabdeckung!!!       
    public void setLeereZeilen() {
            List<dummyZeile> pZeilen = new List<dummyZeile>();
            dummyZeile dZeile = new dummyZeile();
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
                        dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);
                        dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);
                        dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);
                        dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 5';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 6';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile); 
            
            dZeile.Rpos = '. 7';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);
    
    }     
}