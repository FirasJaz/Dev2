@isTest
public class Change_Owner_To_CurrentUser_Op_test {
    
    static testMethod void myUnitTest() {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        ApexPages.StandardController sc = new ApexPages.standardController(opp);
        PageReference pRef = Page.Change_Owner_To_CurrentUser_Opport;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        Change_Owner_To_CurrentUser_Op co = new Change_Owner_To_CurrentUser_Op(sc);
        
        co.Change_owner();
    }

    static testMethod void myUnitTest_ownerIsITUser() {
        List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
        
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        if(user_list != null && user_list.size()>0){
            opp.ownerID= user_list[0].id;
        }
        insert opp;
        
        
        ApexPages.StandardController sc = new ApexPages.standardController(opp);
        PageReference pRef = Page.Change_Owner_To_CurrentUser_Opport;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        Change_Owner_To_CurrentUser_Op co = new Change_Owner_To_CurrentUser_Op(sc);
        
        co.Change_owner();
    }
}