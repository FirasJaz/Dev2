@isTest
public class notification_test {

    static testMethod void notification_test() {
        
        notification n = new notification();
        
        Account testAcc = new Account( Name = 'testAccount');
        insert testAcc;
        ApexPages.StandardController ctr = new ApexPages.StandardController(testAcc);
        n = new notification(ctr);
        
        n.getDatumZeit();
        n.countleads();
        n.getTotalOpps();
        n.getTotalLeads();
        n.getTotalLeadsTL();
        n.getTotalLeadsBEL();
        n.getTotalLeadsHNR();
        n.getTotalLeadsHNR_Prio();
        n.getTotalLeadsPI();
        n.getTotalLeadsWS();
        n.getTotalLeadsBAD();
        n.getNewEmailsBadumbau();
        n.getneueEmails();
        String t = n.filterIdEmail;
        t = n.filterId;
   }
}