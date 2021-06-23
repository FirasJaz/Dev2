@isTest
private class email_verschicken_test {
    static testMethod void myUnitTest() {

        ID batchprocessid = Database.executeBatch(new email_verschicken_batch());
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP,  new email_verschicken_start());    
        
        email_verschicken_batch batch_test = new email_verschicken_batch();
        batch_test.setCurrentUser();
        
        batch_test.setLeereZeilen();      
        
        String htmlValue1 = '{!Kunde__c.Anrede_Formel_Email__c} {!Kunde__c.Name__c}';
        String htmlValue2 = '{!Contact.Anrede_Text_Marketing__c} {!Contact.LastName}';
        String htmlValue3 = '{!User.Phone} {!User.Fax} {!User.Email}';
        
        batch_test.setKdRecipientFields(htmlValue1, 'Sehr geehrter Herr', 'Wolfgang');
        batch_test.setAgRecipientFields(htmlValue2, 'Sehr geehrte Frau', 'Müller');
        
        batch_test.setKdRecipientFields(htmlValue1, '', '');
        batch_test.setAgRecipientFields(htmlValue2, '', '');
        
        batch_test.setUserfields(htmlValue3);
        
        

    }
}