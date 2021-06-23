@isTest(seealldata=true)
private class ksgInvokeScopevisioRequest_test {

    static testMethod void myUnitTest() {
        ksgInvokeScopevisioRequest ks = new ksgInvokeScopevisioRequest();
        //ks.sendSV();
        ks.getRspBody();
        ks.getsvXmlBody();
        ks.getAufruf();
        ks.getRgList();
        //ks.sendMailAnKunde();
        ks.setLeereZeilen() ;
    }
    
}