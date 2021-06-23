/****************************************************************************************************************************
// Erstellt 28.10.2016 von AM
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
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// start email_verschicken_batch2 
// Test aus Console:
//      email_verschicken_multi2 s=new email_verschicken_multi2();
//      s.excute(null) ;
//
// Note: SD 17.08.2018 
//       Kundenstatus records are automatically created with new customer records.
//       Although it is possible to add Kundenstatus records later for old customer records, it is not practically intended.
//       For that reason, this program is using the Customer (Kunde__c) creation date as basis for record retrieval instead of 
//       Kundenstatus record creation date.  
//
//****************************************************************************************************************************
// Änderungen:    
// 10.08.2018   SD  Case 1595  (SD1595)
//                  Zweite email nach 14 Tagen verschicken           
//
// 09.09.2018   AM  executeBatch darf nicht in einer Scleife sein. Dafür gibt es der zweite Paramter 
// 10.09.2018    AM Komplett überarbeitet
//****************************************************************************************************************************
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global class email_verschicken_multi2 implements Schedulable {  

    global void execute(SchedulableContext sc){
            email_verschicken_batch2 em = new email_verschicken_batch2();
            Database.executeBatch(em, 50); 
    }
}