/****************************************************************************************************************************
// Created 12.07.2018 von  MS
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
//	controller for VF-page OpportunityViewAbrechnungsunterlagenInfo
//	which shows on opportunity detail view how many Abrechnungsunterlagen (Bath_Billing__c) the opportunity has
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public class OpportunityViewAbrechnungsunterlagenInfo {
    public String opportunityId {get; set;}
    /**
     * contains the string later shown in the VF-page saying
     * how many Abrechnungsunterlagen the given opportunity has
     */
    public String abrechnungsunterlagenDescription {get; set;}

    /**
     * constructor
     * sets opportunityID and calls getAbrechnungsunterlagenInfo()
     */
    public OpportunityViewAbrechnungsunterlagenInfo(ApexPages.StandardController controller) {
        opportunityId = ((Opportunity)controller.getRecord()).id;
        getAbrechnungsunterlagenInfo();
    }
    
    /**
     * pulls all Abrechnungsunterlagen__c where Opportunity__c is given ID
     * and sets abrechnungsunterlagenDescription to the according text.
    */
    private void getAbrechnungsunterlagenInfo(){
        List<Abrechnungsunterlagen__c> abrechnungsunterlagenList = [select id, Name from Abrechnungsunterlagen__c where opportunity__c =:opportunityId];
        
        if(abrechnungsunterlagenList != null && abrechnungsunterlagenList.size() > 0){
            abrechnungsunterlagenDescription = 'Opportunity hat '+abrechnungsunterlagenList.size()+' Abrechnungsunterlagen. Abrechnungsunterlagen sind im Reiter Verwandt.';                
        }else{
            abrechnungsunterlagenDescription = 'Opportunity hat keine Abrechnungsunterlagen.';
        }
    } 
}