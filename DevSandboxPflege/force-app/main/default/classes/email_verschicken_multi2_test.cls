@isTest
private class email_verschicken_multi2_test {
    static testMethod void myUnitTest() {

        
        Test.StartTest();   
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        email_verschicken_multi2 evm = new email_verschicken_multi2();
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP,  evm);
        evm.execute(null);
        Test.StopTest(); // causes all asynchronous tasks to execute.
       
 
}
}