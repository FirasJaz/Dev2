/****************************************************************************************************************************
// Erstellt 30.10.2017 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  040 23882986
//                         Fax.:  040 23882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: no
//
//****************************************************************************************************************************
//
// Beschreibung: test for checkKsgLoaderLog
//****************************************************************************************************************************
//  Änderungen
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@istest
public class checkKsgLoaderLog_test {
    static testMethod void  testSchedule() {
        Test.startTest();
        asMail__c au = new asMail__c(Name='ksgLoader',subject__c = 'KSGLoader report', toAddr__c = 'kontakt@klosesrockepartner.de', toCC__c = 'kontakt@klosesrockepartner.de');
        insert au;        
        ksgLoader__c ksgLoader = new ksgLoader__c();
        insert ksgLoader;
        attachment at = new attachment(ParentId = ksgLoader.id);
        at.name = 'joblog.txt';
        string  csv = 'v2.0 - Upload zu Hartmann ###################################################\r\n';
        csv += 'v2.0 - XML-Dateien DES von Hartmann erhalten  ###################################################\r\n';
        csv += 'v2.0 - XML-Dateien POD von Hartmann erhalten  ###################################################\r\n';
        csv += 'v2.0 - Download Lieferpositionen zum Abrechnen  ###################################################\r\n';
        csv += 'v2.0 - Lieferpositionen zum Abrechnen gefunden  ###################################################\r\n';
        csv += 'v2.0 - Rechnung gelesen  ###################################################\r\n';
        csv += 'v2.0 - Rechnugspositionen erstellt  ###################################################\r\n';
        csv += 'v2.0 - Upload PDF Rechnung  ###################################################\r\n';
        csv += 'v2.0 - / Update Info-Satz  ###################################################\r\n';
        at.body = blob.valueOf(csv);
        insert at;
        checkKsgLoaderLog mobject = new checkKsgLoaderLog();
        String sch = '0 0 5 * * ?';
        system.schedule('Schedule TEST', sch, mobject);
        Test.stopTest(); 
    }
}