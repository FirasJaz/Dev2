/****************************************************************************************************************************
// Created 12.06.2018 von  MZ
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
// 	opportunity Id
//
//****************************************************************************************************************************
//
// Description:       
//	test class for "OpportunityComment_Badumbau"
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class OpportunityComment_Badumbau_test {
    
	static testMethod void testAllMethods(){
        
        // prepare data
        List<RecordType> oppRtList = [select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Opportunity' limit 1];
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId = oppRtList[0].Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Wanne zur Dusche';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        OpportunityComment_Badumbau.searchOnComments(opp.Id, 'test', 'test');
            
        OpportunityComment_Badumbau.getCorrespondenceList();
            
        OpportunityComment_Badumbau.getNewComment(opp.Id);
        
        OpportunityComments__c oc = new OpportunityComments__c();
        oc.Opportunity__c = opp.Id;
        OpportunityComment_Badumbau.saveOppComment(oc);
            
    }
}