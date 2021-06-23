@isTest
private class mail_template_holen_test {
    static testMethod void myUnitTest() { 
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        insert k;
        try {
        mail_template_holen mth1 = new mail_template_holen(k.id);
        mth1.getBetreff();
        mth1.getPlaintextBody();
        mth1.getHTMLbody();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {                
            EmailTemplate mt = new EmailTemplate(Name='AM test', DeveloperName='AM_test',  TemplateType='text', isActive = true, FolderId = UserInfo.getUserId(), Subject ='test');
            insert mt;
            mail_template_holen mth2 = new mail_template_holen(k.id, mt.id);           
        } 
        }
        catch (System.Exception e) {}
    }
}