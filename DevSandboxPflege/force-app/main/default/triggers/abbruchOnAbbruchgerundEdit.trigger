/********************************************************************************************************************************************
// Created 23.01.2017 von MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
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
//
//********************************************************************************************************************************************
//  Changes:
//    23.08.2018    MZ    #159960296 don't check Stage 'Warten auf Rückmeldung Kunden' for Badumbau
//********************************************************************************************************************************************
*/
trigger abbruchOnAbbruchgerundEdit on Opportunity (before update) {
    for (Opportunity opp: Trigger.new){
        if( opp.Abbruchgrund__c != null ){
            opp.StageName = NachtelefonieAbbruch.status_opp_abbruch;
        }
        if(opp.StageName != NachtelefonieAbbruch.status_opp_kat2){
            opp.Wiedervorlage_Kat_2_Grund__c = null;
        }
        String oppRtName = Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(opp.recordtypeid).getname();
        if(oppRtName != PLZTool_Basis.rtBadumbau && opp.StageName != 'Warten auf Rückmeldung Kunden'){
            opp.Rueckmeldunggrund__c = null;
        }
    }
}