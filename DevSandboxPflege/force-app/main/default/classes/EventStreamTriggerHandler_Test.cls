@isTest
public with sharing class EventStreamTriggerHandler_Test {
    @isTest static void testCreateEvent(){
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.StoreAccessToken');
        EventStream__c e = new EventStream__c();
        e.EventType__c='Instant';
        e.Contact_Key_ID__c='00Q1l000004ftM2EAI';
        e.Email__c ='test@test.de';
        e.EventStream_Description__c='DOI_Journey';
        test.startTest();
        insert e ; 
        test.stopTest();
        DateTime expiry = (DateTime)orgPart.get('expiry');
        System.assertEquals(system.now().addSeconds(3600), expiry);
    }
    @isTest static void testgetAccessToken(){
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.StoreAccessToken');
        test.startTest();
        EventStreamService.getAccessToken();
        test.stopTest();
        String cacheAccessToken = (String)orgPart.get('token');
        System.assertEquals('78314322820e4922b47700dcdd65f844', cacheAccessToken);
    }
}