@isTest
private class reset_Kontingent_Auslastung_test {
    static testMethod void myUnitTest() {

        ID batchprocessid = Database.executeBatch(new reset_Kontingent_Auslastung_batch());
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP,  new reset_Kontingent_Auslastung_start());    
        
        reset_Kontingent_Auslastung_batch batch_test = new reset_Kontingent_Auslastung_batch();
        batch_test.setLeereZeilen();               
    }
}