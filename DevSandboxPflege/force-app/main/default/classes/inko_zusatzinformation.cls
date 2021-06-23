/****************************************************************************************************************************
// Erstellt 16.09.2015 von AM, GL
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
//****************************************************************************************************************************
//
// Beschreibung:
// #105112188
// Email "INKO - Nachfassen von Zusatzinformationen" wird 7 Tage nach Versand der Inko-Muster verschickt. 
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
*/
global class inko_zusatzinformation implements Database.Batchable<sObject> {
    global mail_template_holen mth {get; set;}
    global datetime chkDate = datetime.now().addDays(-7);
    global string ldat = chkDate.format('yyyy-MM-dd');
    global String query = 'Select Kunde__c, INKO_Zusatzinformation__c, Lieferanschrift__r.e_mail__c, name ' 
            + 'FROM Lieferschein__c ' 
            + 'WHERE Liefertext__c = \'Muster-Artikel\' AND INKO_Zusatzinformation__c = false ' 
            + ' AND Lieferanschrift__c <> null '
            + ' AND Lieferdatum__c < ' + ldat;
            
    global list<Lieferschein__c> lsToSendList = new list<Lieferschein__c>();
    global list<Lieferschein__c> lsErrorList = new list<Lieferschein__c>();
    global list<string> fehler = new list<string>();
    
    global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> lsList) {
        boolean error = false;
        for(sObject s : lsList) {
            Lieferschein__c LS = (Lieferschein__c)s;
            if(LS.Lieferanschrift__r.e_mail__c != null) {
                lsToSendList.add(LS);
            }
            else {
                lsErrorList.add(LS);
            }
        } 
        // mail-templates
        ID owID = null;
        List<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress limit 1];
        owID = owa[0].id;
        if(!lsToSendList.isEmpty()) {
            ID etid = null;
            Messaging.SingleEmailMessage[] mlist = new Messaging.SingleEmailMessage[]{};

            list<EmailTemplate> etList = [SELECT id, Name FROM EmailTemplate WHERE name = 'INKO - Nachfassen von Zusatzinformationen'];
            if((etList != null) && (etList.size() > 0)) { 
                etid = etList[0].id;
                for(Lieferschein__c LS : lsToSendList) {
                    mth = new mail_template_holen(LS.Kunde__c, etid);                   
                    Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                    String[] toAddress = new String[] {LS.Lieferanschrift__r.e_mail__c};
                    mail.setToAddresses(toAddress);
                    mail.setPlainTextBody(mth.getPlaintextBody());
                    mail.setHTMLBody(mth.getHTMLbody());
                    mail.setSubject(mth.getBetreff());
                    mail.setOrgWideEmailAddressId(owID);
                    mlist.add(mail);
                    fehler.add('Gesendet an ' + LS.Lieferanschrift__r.e_mail__c);
                }
                system.debug('######################### mlist.size()='  + mlist.size());
                if(!mlist.isEmpty()) {
                    try {
                        Messaging.sendEmail(mlist);
                    }
                    catch (System.Exception e) {
                        error = true;
                        system.debug('#########################email####### error '  + e);
                        fehler.add(string.valueOf(e));
                    }                   
                }
                if(!error) {
                    for(Lieferschein__c LS : lsToSendList) LS.INKO_Zusatzinformation__c = true;
                    try {
                        update lsToSendList;
                    }
                    catch (System.Exception e) {
                        system.debug('################################ error update lsToSendList: '  + e);
                    }                   
                }
                fehler.add('Gesendet: ' + mlist.size() + ' emails.' );
                system.debug('#########################fehler.isEmpty()=' + fehler.isEmpty());
                
            }
            else {
                fehler.add('Email-Template nicht gefunden.');
            }
            
        }
        // mail mit joblog
        if(!lsErrorList.isEmpty()) {
            fehler.add('========================================\nFehler:');
            for(Lieferschein__c LS : lsErrorList) fehler.add('LS: ' + LS.name + '. Kunde hat keine Email-Adresse.');
        }
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        String[] toAddress = new String[] {'alex.mischenko@freenet.de', 'thomas.kaplanski@pflege.de'};
        mail.setToAddresses(toAddress);
        mail.setOrgWideEmailAddressId(owID);
        mail.setSubject('INKO - Nachfassen von Zusatzinformationen - joblog');
        string pt = 'Zusammenfassung:\n';
        system.debug('#########################fehler.isEmpty()=' + fehler.isEmpty());
        if(!fehler.isEmpty()) {
            for(string z : fehler) pt = pt + z + '\n'; 
        }
        mail.setPlainTextBody(pt);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });     
            // setLeereZeilen();                    
        }
        catch (System.Exception e)
        {
            system.debug('#########################Email error ' + e);
        }       
    }
    
    global void finish(Database.BatchableContext BC) {  
        setLeereZeilen();    
    }
    public class dummyZeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;}
                        public string th {get; set;}
                        public string thu {get; set;}
                        public string lDatum {get; set;}
                        public string stern {get; set;}
        }

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
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
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
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  

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
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
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
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
       }
}