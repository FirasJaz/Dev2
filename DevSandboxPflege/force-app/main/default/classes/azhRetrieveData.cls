/*/****************************************************************************************************************************
// Erstellt 24.07.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: genId - GenehmigingId
//            function ('retrieveAnhangEntscheidung', 'retrieveKostenvoranschlagData')  
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//  start scheduled job
//  
//
//****************************************************************************************************************************
//Änderungen:       
//****************************************************************************************************************************
*/
public with sharing class azhRetrieveData  implements  Schedulable {
    public string genid {get; set;}
    public string function {get; set;}

    public azhRetrieveData(string function, string genid) {
        this.genid = genid;
        this.function = function;
    }

    public void execute(SchedulableContext sc) {
        if(function == 'retrieveAnhangEntscheidung') {
            azhWebClient.retrieveAnhangEntscheidung(genId);
        }
        if(function == 'retrieveKostenvoranschlagData') {
            azhWebClient.retrieveKostenvoranschlagData(genId);
        }
        if(function == 'sendKostenvoranschlagData') {
            azhWebClient.sendKostenvoranschlagData(genId);
        }

        CronTrigger ct = [SELECT id FROM CronTrigger WHERE Id = :sc.getTriggerId()];
        System.abortJob(ct.id);

    }
}