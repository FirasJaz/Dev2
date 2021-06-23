@isTest
private class invoke_magento_test {
    static testMethod void myUnitTest() {
        invoke_magento im = new invoke_magento('dummy');
        PageReference pRef = Page.invoke_magento;
        Test.setCurrentPage(pRef);  
        im.setLeereZeilen();
    }
}