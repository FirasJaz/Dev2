/*/****************************************************************************************************************************
// Erstellt 29.11.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frankenstrasse 29
//                         20093 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: none
// 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//  - löscht vorhandene Instanzen von "checkInfoPool" scheduled jobs
//  - erstellt n (default 12) neue Einträge in job schedule
//
//****************************************************************************************************************************
// Test: azhWebClient_test 
//****************************************************************************************************************************
//Änderungen:       
//****************************************************************************************************************************
*/
public with sharing class azhStartCheckInfoPool implements  Schedulable {
    private static integer n = 12;

    public void execute(SchedulableContext sc){
        List<CronTrigger> ctList = [SELECT id FROM CronTrigger WHERE CronJobDetailId IN (SELECT id FROM CronJobDetail WHERE name LIKE 'checkInfoPool%')];
        if((ctList != null) && (ctList.size() > 0)) {
            for(CronTrigger ct : ctList) {
                system.abortJob(ct.id);
            }
        }
        String h = string.valueOf(datetime.now().hour());
        for(integer i = 1; i < n; i++) {
            string min = string.valueOf(i * 5);
            System.schedule('checkInfoPool ' + h + ' ' + string.valueOf(i), '0 ' + min+ ' ' + h + ' * * ?', new azhCheckInfoPool());
        }
        
        azhWebClient.checkInfopool();
    }
}