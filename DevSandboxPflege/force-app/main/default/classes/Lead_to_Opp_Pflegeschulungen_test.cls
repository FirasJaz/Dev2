@isTest
public class Lead_to_Opp_Pflegeschulungen_test {

    static testMethod void  testConversion() {
    
        Campaign camp = new Campaign(name ='testKSGcontroller');
        insert camp;
        
        boolean doppelt = false;
        id rtid = null;       
        id ownerid = UserInfo.getUserId();
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name = 'Pflegeschulungen'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        
        lead l = new lead(Company='Pflegeschulungen', Status='Open');
        l.RecordTypeId = rtid;  
        l.OwnerID = ownerid;
        l.OM_created_at__c = '2017-01-19T11:17:31+01:00';
        l.OM_Tracking_Order_ID__c = '2113213b7c8e7632116168ffb-197e6980fc19';
        l.OM_Referrer__c = 'http://service-neu.pflege.localhost/24h-pflege';
        l.Email = 'test@test.de';
        l.Firstname = 'test';
        l.Lastname = 'test';
        l.Salutation = 'Frau';
        // check dulicate
        list<lead> doppList = [SELECT id FROM lead WHERE OM_Tracking_Order_ID__c = :l.OM_Tracking_Order_ID__c];
        if((doppList != null) && (doppList.size() > 0) ) doppelt = true;        
        // Ursprungsanfrage2
        List<Campaign> cmplist = [select id, name from Campaign where name =: 'testKSGcontroller' LIMIT 1];        
        if(cmplist != null && cmplist.size() != 0) {
            l.OM_Wizzard_Name2__c = cmplist[0].Id;      
        }
        //if(!doppelt) {
        //    try {
                insert l;
                Lead_to_Opportunity_Pflegeschulungen.convertLeadToOpportunity(l);
        //    }catch(Exception e){
        //    }
        //}
    }
}