/****************************************************************************************************************************
// Erstellt 30.10.2017 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: no 
//
//****************************************************************************************************************************
//
// Beschreibung: read log from ksgLoader and send email
//
//****************************************************************************************************************************
//  Änderungen:
// 18.12.2018 AM 00001856 - Einbau "check for error" und ausgabe in Betreff 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/
global class checkKsgLoaderLog implements Schedulable{

    global void execute(SchedulableContext sc) {
        
        asMail__c asMail = asMail__c.getValues('ksgLoader');
        String subject, toAddr, toCC;
        try {
            subject = asMail.subject__c;
            toAddr = asMail.toAddr__c;
            toCC = asMail.toCC__c;
        }
        catch (System.Exception e) {
            subject = 'KSGLoader report';
            toAddr = 'kontakt@klosesrockepartner.de';
            toCC = null;
        }
        string CRLF = '\r\n';
        
        DateTime heute0Uhr = DateTime.newInstance(date.today(), Time.newInstance(0, 0, 0, 0));
        if(Test.isRunningTest()) {
            heute0Uhr = heute0Uhr.addDays(2);
        }
        list<string> msgList = new List<string>();
        list<ksgLoader__c> ksgList = [SELECT id, createddate FROM ksgLoader__c WHERE createddate < : heute0Uhr ORDER BY createddate DESC LIMIT 1];
        list<attachment> atList = [SELECT id, body FROM attachment WHERE ParentId = : ksgList[0].id LIMIT 1];
        if( (atList != null) && (atList.size() > 0) ) {
            string logfile = atList[0].body.toString();    
            boolean hasError = false;  
            while (logfile.length() > 1) {
                String row = logfile.subString(0, logfile.indexOf(CRLF));
                logfile = logfile.subString(logfile.indexOf(CRLF) + CRLF.length(), logfile.length());
                if(row.Contains('v2.0')) {
                    if(row.Contains('Upload zu Hartmann')) msgList.Add(row.substring(21));
                    if(row.Contains('XML-Dateien DES von Hartmann erhalten')) msgList.Add(row.substring(21));
                    if(row.Contains('XML-Dateien POD von Hartmann erhalten')) msgList.Add(row.substring(21));
                    if(row.Contains('kann nicht zugerodnet werden')) {
                        hasError = true;
                        msgList.Add(row.substring(21));
                    }

                    if(row.Contains('Download Lieferpositionen zum Abrechnen')) msgList.Add(row.substring(21));
                    if(row.Contains('Lieferpositionen zum Abrechnen gefunden')) msgList.Add(row.substring(21));
                    if((row.Contains('Rechnung')) && (row.Contains('gelesen'))) msgList.Add(row.substring(21));
                    if(row.Contains('Rechnugspositionen erstellt')) msgList.Add(row.substring(21));
                    if(row.Contains('Upload PDF Rechnung')) msgList.Add(row.substring(21));
                    if(row.Contains('/ Update Info-Satz')) msgList.Add('======================================================================');
                }
            }
            string mailText = 'ksgLoader Logfile report,\r\n';
            for(string msgtext : msgList) mailText += msgtext + CRLF;
            Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            String[] toAddress = toAddr.split(',');
            mail.setToAddresses(toAddress);
            if(toCC != null) {
                String[] toCcAddress = toCC.split(',');
                mail.setCcAddresses(toCcAddress);
            }
            if(hasError) {
                subject += ' Es ist ein Fehler aufgetreten.' ;
            }
            mail.setSubject(subject);            
            mail.setPlainTextBody(mailText);
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            catch (System.Exception e)
            {

            }
        }
    }
}