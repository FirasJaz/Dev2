//****************************************************************************************************************************
// Erstellt 12.08.2019 von AM
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
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Setzt estimatedAmount__c aus custom setting
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
trigger before_insert_opportunity on Opportunity (before insert) {
    decimal plannedAmount = 40.0;
    try {
            OpportunityEstimatedAmount__c oea = OpportunityEstimatedAmount__c.getValues('default');
            plannedAmount = oea.estimatedAmount__c;
        }
    catch (System.Exception e) {
        plannedAmount = 40.0;
    }
    id rtid = [SELECT id FROM RecordType WHERE sObjectType='opportunity' AND Name = 'Curabox'].id;
    for(opportunity op : trigger.new) {
        if(op.RecordTypeId == rtid) {
            if(op.plannedAmount__c == null) {
                op.plannedAmount__c = plannedAmount; 
            }
        }
    }
    
}