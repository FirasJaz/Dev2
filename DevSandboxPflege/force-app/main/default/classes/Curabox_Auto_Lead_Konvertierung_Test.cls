/****************************************************************************************************************************
// Created 22.07.2019 von  AD
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter:
//****************************************************************************************************************************
//
// Description:       
//  Test Klasse.
//****************************************************************************************************************************
// Changes:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
private class Curabox_Auto_Lead_Konvertierung_Test {
   
   @isTest static void convertLead(){
        // create campaign
        Campaign cam = new Campaign();
        cam.Name = 'Curabox';
        cam.IsActive = true;
        insert cam;
        // 
        Lead lead = new Lead();
        lead.Salutation = 'Herr';
        lead.FirstName = 'Alex';
        lead.LastName = 'TDAS';
        lead.Email = 'stephanealex72@yahoo.de';
        lead.Company = 'KSG';
        lead.Status = 'Open';
        lead.OM_Tracking_Order_ID__c = 'ADJDKIEZE13THEDIE8U9IKRE';
        lead.OM_Wizard_Version__c = 'V16.3';
        lead.OM_Wizzard_Name2__c = cam.Id;
        //lead.CreatedDate = System.today();
        insert lead;
        // 
        // Test convertLead (List<Lead> leadList)
        List<Lead> leadList = [SELECT Salutation, FirstName, LastName, Email, Phone, Company, Status, OM_Tracking_Order_ID__c, OM_Wizard_Version__c, OM_Wizzard_Name2__c, CreatedDate FROM Lead];
        Curabox_Auto_Lead_Konvertierung.convertLead(leadList);
        System.assertEquals(1, leadList.size());
   }

}