//****************************************************************************************************************************
// Created  17.08.2017     by MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04023882986
//                         Fax.:  04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// xxxx
//
//****************************************************************************************************************************
//
// Description:
//                      
//          If D-weites Invest is marked in opportunity, the value for "Standort Richtung" should be cleared.
//
//****************************************************************************************************************************
//Changes:
//    
//****************************************************************************************************************************

trigger pi_updateLocationDirection on Opportunity (before update) {

    for (Opportunity opp: Trigger.new){
        if(Trigger.oldMap.get(opp.Id) != null &&
           Trigger.oldMap.get(opp.Id).location_direction__c == null &&
           Trigger.oldMap.get(opp.Id).D_weites_Invest__c &&
           opp.location_direction__c != null){
            opp.D_weites_Invest__c = false;
        }
        if( opp.D_weites_Invest__c){
            opp.location_direction__c = null;
        }
    }
}