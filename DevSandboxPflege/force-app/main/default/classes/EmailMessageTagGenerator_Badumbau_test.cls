/****************************************************************************************************************************
// Created 31.07.2018 by  MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Description:       
//	test class for "EmailMessageTagGenerator_Badumbau"
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class EmailMessageTagGenerator_Badumbau_test {
    
    static testMethod void resolveMergeFields(){
        
        //prepare data
        List<RecordType> oppRtList = [select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Opportunity' limit 1];
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId = oppRtList[0].Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Wanne zur Dusche';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.measurement_appointment__c = Date.today();
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_insured';
        c2.LastName = 'test class_insured';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22767';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'ASP';
        insert cr;
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.IsPrimary = true;
        cr2.Role = 'PB';
        insert cr2;
        
        Offer__c offer = new Offer__c();
        offer.opportunity__c = opp.Id;
        offer.rebate__c = 23;
        insert offer;
        
        String text = ' {!ASP.Salutation} {!PB.LastName} {!Opportunity.Id} {!User.Name} {!TimeValue(Opportunity.measurement_appointment__c)} {!offer__c.rebate__c}  ';
        
        EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, text, userInfo.getUserId());
        
        
    }
    

}