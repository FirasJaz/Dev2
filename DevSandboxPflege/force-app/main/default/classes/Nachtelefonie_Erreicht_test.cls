@isTest
public class Nachtelefonie_Erreicht_test {

    static testMethod void myUnitTest() {
    
      Profile p = [SELECT Id FROM Profile WHERE Name='ZWB - Standardbenutzer'];
      User u2 = new User(Alias = 'nwUsrtst', Email='newuser@testorg.com',
         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
         LocaleSidKey='en_US', ProfileId = p.Id,
         TimeZoneSidKey='America/Los_Angeles', UserName='nwUsrtst@nwUsrtst.com');

      System.runAs(u2) {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        //opp.ownerId = UserInfo.getUserId();
        insert opp;
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        //nt.ownerId = UserInfo.getUserId();
        
        insert nt;
        
        ApexPages.StandardController sc = new ApexPages.standardController(nt);
        PageReference pRef = Page.Nachtelefonie_Erreicht;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);  
        Nachtelefonie_Erreicht ne = new Nachtelefonie_Erreicht(sc);
        ne.erreicht();
      }
    }
}