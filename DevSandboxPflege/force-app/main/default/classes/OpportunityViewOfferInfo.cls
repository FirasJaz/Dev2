/****************************************************************************************************************************
// Created 07.06.2018 von  MZ
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
//	to show Offer status on opportunity layout
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class OpportunityViewOfferInfo {
    public String opportunityId {get; set;}
    public List<offer__c> offerList;
    public String OfferDescription {get; set;}

    public OpportunityViewOfferInfo(ApexPages.StandardController controller) {
        opportunityId = ((Opportunity)controller.getRecord()).id;
        getOfferInfo();
    }
    
    private void getOfferInfo(){
        offerList = [select id, Name, Angebot_Status_intern__c, estimate_status__c from Offer__c where opportunity__c =:opportunityId limit 100];
        if(offerList != null && offerList.size() > 0){
             OfferDescription = 'Opportunity hat '+offerList.size()+' KVAs und Angebote. KVAs und Angebote sind im Reiter Verwandt.';
        }else{
            OfferDescription = 'Opportunity hat keine KVAs und Angebote.';
        }
    }
}