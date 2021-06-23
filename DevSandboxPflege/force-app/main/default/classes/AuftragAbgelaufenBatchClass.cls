/****************************************************************************************************************************
// Erstellt 22.04.2015 von AM, 
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstraße 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.:  04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: no 
//
//****************************************************************************************************************************
//
// Beschreibung: Löscht die LP's und AP's wenn AU abgelaufen 
//
//****************************************************************************************************************************
//Änderungen:
//
// 09.11.2017   AM  case 00001333. Die KUWV Aufträge wurden auch auf "abgelaufen" gesetzt. Sollen nur PG54
//****************************************************************************************************************************
*/

global class AuftragAbgelaufenBatchClass implements Database.Batchable<sObject> {

    global final String query = 'Select Genehmigungsstatus__c, Id '
                        + ' From Auftrag__c '
                        + ' WHERE Genehmigungsstatus__c <> \'abgelaufen\' '
                        + ' AND Bezeichnung__c != \'KUWV\' '
                        + ' AND Kunde__c IN (SELECT Kunde__c FROM Kundenstatus__c '
                        + ' WHERE Produktgruppe__c = \'PG54\' AND Status__c IN (\'Kündigung\', \'Vorgang geschlossen\')) ';
    
//    global final String query = 'Select Genehmigungsstatus__c, Id '
//                      + ' From Saniconnect__Auftrag__c '
//                      + ' WHERE genehmigt_bis__c < TODAY '
//                      + ' AND unbefristet_genehmigt__c <> true '
//                      + ' AND Genehmigungsstatus__c <> \'abgelaufen\'';


     global AuftragAbgelaufenBatchClass() {
                // Batch Constructor
     }
      

     
     // Start Method
     global Database.QueryLocator start(Database.BatchableContext BC) { 
      return Database.getQueryLocator(query);
     }
    
   
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Auftrag__c> setAbgelaufen = new List<Auftrag__c>(); 
        List<Auftragsposition__c> ApList = new List<Auftragsposition__c>();
        List<Lieferscheinposition__c> LpList = new List<Lieferscheinposition__c>(); 
        Set<ID> auSet = new Set<ID>{};
        Set<ID> apSet = new Set<ID>{};
        boolean istAU = false;
        boolean istAP = false;
        boolean istLP = false;
        for(sObject s : scope){            
            setAbgelaufen.add((Auftrag__c)s);
        }   
        system.debug('###################### Select setAbgelaufen.size()=' + setAbgelaufen.size() );
        if ((setAbgelaufen != null) && (setAbgelaufen.size() > 0)) {
            istAU = true;   
          for(Auftrag__c AU : setAbgelaufen){            
                AU.Genehmigungsstatus__c = 'abgelaufen';
                auSet.add(AU.Id);
             }          
            
            ApList = [ SELECT id, Restmenge__c
                        FROM Auftragsposition__c
                        WHERE Auftrag__c IN :auSet
                        // AND Restmenge__c > 0                
                ];
                system.debug('###################### Select ApList.size()=' + ApList.size() );
            if ((ApList != null) && (ApList.size() > 0)) {

                istAP = true;
                for (Auftragsposition__c AP : ApList) {
                    AP.Restmenge__c = 0;
                    apSet.add(AP.id);
                }   
                
                LpList = [ SELECT id, Menge__c, Status__c
                            FROM Lieferscheinposition__c
                            WHERE Auftragsposition__c IN :apSet
                            AND Status__c IN  ('Bedarf', 'jetzt liefern')
                            AND Menge__c > 0
                
                        ];
                system.debug('###################### Select LpList.size()=' + LpList.size() );
                if ((LpList != null) && (LpList.size() > 0)) {

                    istLP = true;
                    for (Lieferscheinposition__c LP : LpList) {
                        LP.Menge__c = 0;
                    }
                }
            }       
            
        } 
// update AU ====
        if (istAU) {
            system.debug('###################### setAbgelaufen.size()=' + setAbgelaufen.size() );
            try{
                update setAbgelaufen;
            }
            catch (system.Dmlexception d) {
                system.debug('########### Fehler update Auftrag ' + d );
            }                       
        }
// update AP ====
        if (istAP) {
            system.debug('###################### ApList.size()=' + ApList.size() );
            try{
                update ApList;
            }
            catch (system.Dmlexception d) {
                system.debug('########### Fehler update Auftragsposition ' + d );
            }                       
        } 
// update LP ====
        if (istLP) {
            system.debug('###################### LpList.size()=' + LpList.size() );
            try{
//              update LpList;
                delete LpList;
            }
            catch (system.Dmlexception d) {
                system.debug('########### Fehler update/delete Lieferscheinposition ' + d );
            }                       
        }                         
    }
   
    global void finish(Database.BatchableContext BC){
         // Logic to be Executed at finish
    }
 }