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
//	to send a new email based on selected template 
//****************************************************************************************************************************
// test class: OpportunityComment_Badumbau_test
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class OpportunityComment_Badumbau {
    private static String KEINE = '--keine--';
    
    @AuraEnabled
    public static List<OpportunityComments__c> searchOnComments(String oppId, String srchCorrespondence, String srchComment) {
        String query = ' select id, Comment__c,  Correspondence__c, CreatedDate,  CreatedBy.Name from OpportunityComments__c where opportunity__c = \''+ oppId +'\'';
        
        if(!String.isEmpty(srchCorrespondence) && srchCorrespondence != KEINE){
            query += ' and Correspondence__c = \''+ srchCorrespondence +'\' ';
        }
        if(!String.isEmpty(srchComment)){
             query += ' and Comment__c like \'%'+ srchComment +'%\' ';
		}  
        query += ' order by createdDate desc limit 1000 ';
        
        return (list<OpportunityComments__c>) Database.query(query);
    }
    
	@AuraEnabled
    public static List<String> getCorrespondenceList()
    {
        List<String> correspondenceList = new List<String>();
        Schema.DescribeFieldResult fieldResult = OpportunityComments__c.Correspondence__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            correspondenceList.add(f.getLabel());
        }
        return correspondenceList;
    }  
    
    @AuraEnabled
    public static OpportunityComments__c getNewComment(String oppId){
        OpportunityComments__c oppComment = new OpportunityComments__c();
        oppComment.Opportunity__c = oppId;
        oppComment.Correspondence__c = 'Allgemein';
        return oppComment;
    }
    
    @AuraEnabled
    public static String saveOppComment(OpportunityComments__c oppComment){
        try{
            insert oppComment;
        }catch(Exception e){
            return 'Error: ' + e.getMessage();
        }
        return 'Kommentar erfolgreich hinzugefügt!' ;
    }

}