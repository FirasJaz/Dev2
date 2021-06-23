@isTest
public class Change_Owner_To_IT_SUPPORT_NT_test {
    static testMethod void myUnitTest() {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        insert nt;
        
        ApexPages.StandardController sc = new ApexPages.standardController(nt);
        PageReference pRef = Page.Change_Owner_To_IT_SUPPORT_NT;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);
        Change_Owner_To_IT_SUPPORT_NT co = new Change_Owner_To_IT_SUPPORT_NT(sc);
        
        co.Change_owner();
    }
}