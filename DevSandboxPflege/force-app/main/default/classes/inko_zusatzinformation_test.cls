@isTest
private class inko_zusatzinformation_test {
    static testMethod void myUnitTest() {

        ID batchprocessid = Database.executeBatch(new inko_zusatzinformation());
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('testScheduledApex', CRON_EXP,  new inko_zusatzinformation_start());
        
    }
}