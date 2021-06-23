@isTest
public class NewFamilyMemberTest {

    static testMethod void myUnitTest() {
        Account a = new Account();
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        Contact con = new Contact();
        con.lastName = 'cunitest';
        insert con;
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        OpportunityContactRole role = new OpportunityContactRole();
        role.contactId = con.id;
        role.role = 'ASP';
        role.opportunityId = opp.id;
        insert role;
        
        PageReference pRef = Page.NewFamilyMemeberPage;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        NewFamilyMember_Opp nfmo = new NewFamilyMember_Opp();
        NewFamilyMember nfm = new NewFamilyMember(opp.id ,true);
        nfm.start();
        nfm.formObj.Lastname = 'test contact family';
        nfm.zuOpportunity();
        nfm.speichern();
        
        nfm.getBekannteKrankheitenOptions();
        nfm.updateContactRoles();
        nfm.setPrimary();
        
        nfm.abbruch();
    }
}