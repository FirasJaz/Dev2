@isTest
private class PP_account_pausieren_test {
    /*static testMethod void myUnitTest() {

        ID batchprocessid = Database.executeBatch(new PP_account_batch());
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP,  new PP_account_pausieren_start());    
        
        PP_account_pausieren_batch batch_test = new PP_account_pausieren_batch();
        
    }*/

    public static testMethod void testBatch() {
       Account c  = new Account();
       c.name = 'testBatch_account';
       c.pausiert_ab__c = Date.today();
       c.pausiert__c = false;
       
       insert c;
       
       Test.StartTest();
       ID batchprocessid = Database.executeBatch(new PP_account_pausieren_batch());
       Test.StopTest();
 
    }
    
}