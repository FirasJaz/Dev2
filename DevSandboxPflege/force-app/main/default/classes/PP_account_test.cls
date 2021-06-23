@isTest
private class PP_account_test {
    static testMethod void myUnitTest() {

        ID batchprocessid = Database.executeBatch(new PP_account_batch());
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP,  new PP_account_start());    
        
        PP_account_batch batch_test = new PP_account_batch();
        batch_test.setLeereZeilen();       
        
    }
}