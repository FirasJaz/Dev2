@isTest
public class AdditionalInfoControllerTest {
    static testMethod void myUnitTest() {
        
        List<recordType> rtList =[select id, name,sobjecttype from recordType where name ='Notrufsysteme' and sobjecttype  = 'Opportunity' limit 1];
        recordType rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Weiterleitung';

        opp.Pflegedienst__c = True;
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        AdditionalInfoController aic = new AdditionalInfoController();
        aic.cont = c;
        aic.start(opp.Id, 'Alternative Versandadresse', 'ASP', true);
        aic.start(opp.Id, 'Alternative Versandadresse', 'PB', true);
        aic.saveAI();
        aic.abbruch();
    }
   
}