/****************************************************************************************************************************
// Created 24.07.2018 von  MS
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Description:       
//	controller for RelatedEmails-lightning component
//
//****************************************************************************************************************************
// test class: RelatedEmails_test
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public without sharing class RelatedEmails {
    /**
     * returns a list of emailMessages which are related to given OpportunityId
     **/
	@AuraEnabled
    public static List<EmailMessage> findAllEmailsByOppId(String oppId) {
         return [SELECT Id, subject, MessageDate, ToAddress, FromAddress, TextBody
                   FROM EmailMessage
                   WHERE relatedToId =: oppId
                	ORDER BY MessageDate DESC];
    }
    
    /**
     * to get list of attachments of a selected email message. the list will be shown in overlay.
     * */
    @AuraEnabled
    public static List<Attachment> getAllEmailAttachments(Id messageId){
        List<Attachment> attList = new List<Attachment>();
        attList = [SELECT id, ParentId, Name, Body from attachment where ParentId = :messageId ];
        return attList;
    }
    
}