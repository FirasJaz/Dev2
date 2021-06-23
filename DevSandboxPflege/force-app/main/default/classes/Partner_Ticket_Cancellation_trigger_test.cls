/*********************************************************************************************************************************************
// Created 06.12.2018 by MZ
//                      Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                      Nordkanalstraße 58
//                      20097  Hamburg 
//                      Tel.:  0423882986
//                      Fax.:  0423882986
//                      Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Description:    
//    test class of:
//  Partner_Ticket_Cancellation_trigger 
//********************************************************************************************************************************************
//  Changes:
//********************************************************************************************************************************************
*/
@isTest
public class Partner_Ticket_Cancellation_trigger_test{

 static testMethod void PartnerProduct_Test(){
 
     // create test data
     Account a = TestDataFactory.createPartnerAccount('test1');
     Partner_Produkte__c pp = TestDataFactory.createPartnerProduct('Treppenlift', a.Id);
     TestDataFactory.createProductPrice(pp.Id);
     Opportunity opp = TestDataFactory.createOpportunity('Treppenlift', 'triggertt');
     
        
     Partner_Ticket__c pt = new Partner_Ticket__c();
     pt.Opportunity__c = opp.Id;
     pt.Wert_des_Partner_Tickets_CPL__c = 12;
     insert pt;
     
     List< Partner_Ticket__c> ptList =[select id, Wert_des_Partner_Tickets_CPL__c from Partner_Ticket__c where id=: pt.id];
     System.assertequals(1, ptList.size());
     System.assertequals(12.00, ptList[0].Wert_des_Partner_Tickets_CPL__c );

     pt.Status_CPL__c = 'Storniert';
     update pt;
     
     ptList = [select id, Status_CPL__c, Wert_des_Partner_Tickets_CPL__c from Partner_Ticket__c where id=: pt.id];
     System.assertequals('Storniert', ptList[0].Status_CPL__c );
     System.assertequals(0.00, ptList[0].Wert_des_Partner_Tickets_CPL__c );
     
 }

}