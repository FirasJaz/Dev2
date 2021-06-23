@isTest
public class Change_Owner_To_IT_SUPPORT_Op_test {
	static testMethod void myUnitTest() {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        ApexPages.StandardController sc = new ApexPages.standardController(opp);
        PageReference pRef = Page.Change_Owner_To_IT_SUPPORT_Op;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        Change_Owner_To_IT_SUPPORT_Op co = new Change_Owner_To_IT_SUPPORT_Op(sc);
        
        co.Change_owner();
    }
}