/****************************************************************************************************************************
// Erstellt 06.06.2019 von AD
//  					   Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//						   Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Lead
//
//****************************************************************************************************************************
//
// Beschreibung:
// Automatische Konvertierung von Curabox Leads zu Opportunities              
//
//****************************************************************************************************************************
// Changes:
//
//****************************************************************************************************************************
*/
trigger Curabox_Auto_Lead_Convert_Trigger on Lead (after insert) {
    List<Lead> leadList = new List<Lead>();
    // get curabox recordTypeId
    List<RecordType> recordTypList = [SELECT Id, sObjectType FROM RecordType WHERE Name = 'Curabox' and sObjectType = 'Lead'];
    leadList = [Select Id, 
                    Owner.Id, 
                    Firstname, 
                    Lastname, 
                    Email,
                    Salutation, 
                    Phone,
                    next_Step__c,
                    OM_Tracking_Order_ID__c,
                    OM_Wizzard_Name2__c,
                    OM_Wizard_Version__c,
                    RecordTypeId,
                    createdDate 
                    FROM Lead 
                    WHERE Id IN :Trigger.New
                    AND RecordTypeId =: recordTypList[0].Id
                    AND next_Step__c ='blanko per Email an Versicherten' 
                    AND OM_Tracking_Order_ID__c != null
                    ];
            
    Curabox_Auto_Lead_Konvertierung.convertLead(leadList);
}