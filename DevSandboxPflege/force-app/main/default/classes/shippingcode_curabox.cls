/********************************************************************************************************************************************
// Erstellt 23.11.2016 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
// Parameter: no
//
//********************************************************************************************************************************************
//
// Beschreibung:             
//
//********************************************************************************************************************************************
//Änderungen:
//  04.01.2018  AM  #105284564 - auch für Art_der_Anschrift "Angehöriger" und "Betreuer"
//  29.01.2018  AM  ---- bool isSanBox wegen too many SOQL
//
//********************************************************************************************************************************************
*/

global class shippingcode_curabox implements Database.Batchable<sObject>, Database.Stateful {

    private boolean error = false;
    global String query = 'SELECT id, statusMsgId__c, Kunde__c, Kunde__r.e_mail__c, Kunde__r.Anrede__c, Kunde__r.Name__c, Kunde__r.Vorname__c, ' 
                        + ' mail_an_kunde_gesendet_am__c, Lieferschein__r.Lieferanschrift__r.e_mail__c '
                        + ' FROM Lieferbest_tigung__c '
                        + ' WHERE statusMsgId__c != null '
                        + ' AND mail_an_kunde_gesendet_am__c = null '
                        + ' AND Rechnung__c = null '
                        + ' AND (Lieferschein__r.Liefertext__c LIKE \'CB%\' OR Lieferschein__r.Liefertext__c = \'KUWV\') '
                        + ' AND Lieferschein__r.Lieferanschrift__r.Art_der_Anschrift__c IN (\'Kundenadresse\', \'Angehöriger\', \'Betreuer\' ) '
                        + ' AND Lieferschein__r.Lieferanschrift__r.Standardlieferanschrift__c = true '
                        + ' AND Lieferschein__r.Lieferanschrift__r.e_mail__c != null ';

    global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lieferbest_tigung__c> lbList) {
        String subject, templateBody;
        Boolean runInSandbox = runningInASandbox();
        if((lbList != null) && (lbList.size() > 0)) {   
            List<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress WHERE DisplayName = 'Curabox Kundenservice' limit 1];
            Messaging.SingleEmailMessage[] mlist = new Messaging.SingleEmailMessage[]{};

            list<Antragstext__c> mtList = [SELECT Betreff__c, RichText__c 
                                            FROM Antragstext__c 
                                            WHERE Textkey__c = 'DHL shipping code Curabox'
                                            LIMIT 1];  

            if((mtList != null) && (mtList.size() == 1)){
                templateBody = mtList[0].RichText__c;
                subject = mtList[0].Betreff__c;
            }            


            for(Lieferbest_tigung__c LB : lbList) {            
                String currentBody = templateBody;
                String toAddr;
                if(LB.Kunde__r.e_mail__c != null) {
                    toAddr = LB.Kunde__r.e_mail__c;
                } 
                else {
                    toAddr = LB.Lieferschein__r.Lieferanschrift__r.e_mail__c;
                }
                String Anredeformel = 'Sehr geehrte Damen und Herren, ';
                if (LB.Kunde__r.Anrede__c != null) {
                    if (LB.Kunde__r.Anrede__c.contains('Herr') ) {                 
                            Anredeformel = 'Sehr geehrter ' +(LB.Kunde__r.Anrede__c + ' ' + LB.Kunde__r.Name__c).trim() +',';                                                 
                    }
                    if (LB.Kunde__r.Anrede__c.contains('Frau') ) { 
                            Anredeformel = 'Sehr geehrte ' +(LB.Kunde__r.Anrede__c + ' ' + LB.Kunde__r.Name__c).trim() +',';                                                   
                    }         
                }   
                String dhlsnr = LB.statusMsgId__c;  
                String dhlurl = 'https://nolp.dhl.de/nextt-online-public/set_identcodes.do?idc=' + LB.statusMsgId__c;
                dhlurl = '<a href="' + dhlurl + '">' + LB.statusMsgId__c + '</a>';  
                currentBody = currentBody.replace('$anredeformel$', Anredeformel);
                currentBody = currentBody.replace('$dhlurl$', dhlurl);
                currentBody = currentBody.replace('$dhlsnr$', dhlsnr);

                Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                mail.setOrgWideEmailAddressId(owa[0].id);
                String[] toAddress;
                if(!runInSandbox) {
                    toAddress = new String[] {toAddr};
                }
                else {
                    toAddress = new String[] {'dana.birkholz@pflege.de'};
                }
                mail.setToAddresses(toAddress);
                mail.setSubject(subject);
                mail.setHtmlBody(currentBody);
                mail.setPlainTextBody(currentBody.replaceAll('<[^>]+>',' '));
                mlist.add(mail);
            } 
            if(!mlist.isEmpty()) {
                try {
                    Messaging.sendEmail(mlist);
                    for(Lieferbest_tigung__c LB : lbList) { 
                        LB.mail_an_kunde_gesendet_am__c = date.today();
                    }
                    update lbList;
                }
                catch (System.Exception e) {
                    error = true;
                    system.debug('#########################email####### error '  + e);
                } 
            }

        }
    }

    global void finish(Database.BatchableContext BC) {
        if(!error) {
            // irgend was
        }
    }

    global Boolean runningInASandbox() {
        return [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }    

}