/****************************************************************************************************************************
// Erstellt 04.01.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: set<id> attachments (joblog.txt)
//
//****************************************************************************************************************************
//
// Description: 
//              
//
//****************************************************************************************************************************
// Änderungen:   
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class ksgloader_joblog {

    @future(callout=true)
    public static void sendCSV(set<id> attIdSet) {
        list<attachment> atList = [SELECT id, body FROM attachment WHERE Id IN : attIdSet];
        if((atList != null) && (atList.size() > 0)) {
            for(attachment at : atList) {
                string logfile = at.body.toString();  
                prepareJobLog(logfile);
            }       
        }
    }

    public static void prepareJobLog(String logfile) {
        string CRLF = '\r\n';
        Map<String, String> pidMap = new Map<String, String>();
        while (logfile.length() > 1) {
            String row = logfile.subString(0, logfile.indexOf(CRLF));
            logfile = logfile.subString(logfile.indexOf(CRLF) + CRLF.length(), logfile.length());
            if(row.Contains('id:')) {
                if(row.Contains('Rechnung CB-RG')) {
                    String pid = row.substring(row.indexOf('id:'), row.indexOf(' ', 12));
                    string rechnung = row.substring(43);
                    rechnung = rechnung.replace('Rechnung ', '').trim();
                    rechnung = rechnung.substring(0, rechnung.indexOf(' ')).trim();
                    if(pidMap.containsKey(pid)) {
                        String zeile = pidMap.get(pid) + ',' + rechnung;
                        pidMap.put(pid, zeile);
                    }
                    else {
                        pidMap.put(pid, rechnung);
                    }
                }
            }   
        }
        if(!pidMap.isEmpty()) {
            for(String param : pidMap.values()) {
                string[] rgnamen = param.split(',');
                List<Rechnung__c> rgList = [SELECT id, PDF_generiert__c FROM Rechnung__c WHERE name IN : rgnamen AND PDF_generiert__c = false];
                if((rgList != null) && (rgList.size() > 0)) {
                    ASB_CSV.createAndSendBoth(param);
                    for(Rechnung__c rg : rgList) {
                        rg.PDF_generiert__c = true;
                    }    
                    List<Database.SaveResult> sr = Database.update(rgList, false); 
                }
            }
        }
    }

}