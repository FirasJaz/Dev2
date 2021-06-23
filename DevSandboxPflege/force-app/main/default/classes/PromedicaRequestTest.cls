/********************************************************************************************************************************************
// Created on 23.07.2020 von BT
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frankenstraße. 29
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Description:             
//                  		Test class for the class PromedicaRequest
//********************************************************************************************************************************************
//  Changes:
//  
//********************************************************************************************************************************************
*/
@isTest
private class PromedicaRequestTest {    
    @isTest(seeAllData=true)
    static void testSendRequest(){               
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opp = [SELECT Id, Promedica_Request__c, Promedica_Response__c FROM Opportunity LIMIT 1];
        String oppId = opp.Id;
        System.assert(String.isBlank(opp.Promedica_Request__c));
        System.assert(String.isBlank(opp.Promedica_Response__c));
        
		String uniqueUserName = 'adminuser' + DateTime.now().getTime() + '@testorg.com';       
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' or Name='Systemadministrator'];
        User u = new User(Alias = 'admin', Email='adminuser@testorg.com', FirstName='Admin',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);        
                
        Test.startTest();   
        Test.setMock(HttpCalloutMock.class, new PromedicaRequestMock());
        System.runAs(u) {        
            PromedicaRequest.sendRequest(opp.Id, c.Id, UserInfo.getFirstName(), UserInfo.getLastName());                        
        }
        Test.stopTest();                
    }
}