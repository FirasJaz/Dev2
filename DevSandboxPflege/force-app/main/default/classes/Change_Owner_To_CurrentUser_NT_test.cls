@isTest
public class Change_Owner_To_CurrentUser_NT_test {
    
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
        PageReference pRef = Page.Change_Owner_To_CurrentUser_Nachtel;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);
        Change_Owner_To_CurrentUser_NT co = new Change_Owner_To_CurrentUser_NT(sc);
        
        co.Change_owner();
    }
    
    static testMethod void myUnitTest_ownerIsITUser() {
        List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
        
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        if(user_list != null && user_list.size()>0){
            nt.ownerID= user_list[0].id;
        }
        insert nt;
        
        ApexPages.StandardController sc = new ApexPages.standardController(nt);
        PageReference pRef = Page.Change_Owner_To_CurrentUser_Nachtel;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);
        Change_Owner_To_CurrentUser_NT co = new Change_Owner_To_CurrentUser_NT(sc);
        
        co.Change_owner();
    }

}