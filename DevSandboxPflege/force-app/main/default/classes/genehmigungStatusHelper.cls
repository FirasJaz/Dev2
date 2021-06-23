//****************************************************************************************************************************
// Erstellt 19.06.2019 von AM
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
// Diverse Methoden gür das Pflegen Curabox_Genehmigung__c
//
// Methoden:    creteNewStatusOnNewContactFromLead(list<contact> ctList ) - (trigger.new)
//                  Aufruf durch trigger Contact after insert
//                  Return: map<id, string>
//                  Key: contactId, value: Error Message
//    
//              Aufruf nach dem Hochladen des Antrags
//              setAntragEingegangen(string objId) 
//                  Setzt Status 'Kandidat' und das Datum
//                  objId - Curabox_Genehmigung__c oder Order__c id
//
//              setAntragEingegangen(id contactId, string Productgroup) 
//                  Propductgroup 'PG51' oder 'PG54'
//
//              Aufruf nach dem Hochladen der Genehmigung
//              setAntragGenehmigt(string objId) 
//                  Setzt Status 'Kunde' und das Datum
//                  objId - Curabox_Genehmigung__c oder Order__c id
//
//              setAntragGenehmigt(id contactId, string Productgroup) 
//                  Propductgroup 'PG51' oder 'PG54'
//****************************************************************************************************************************
//Änderungen:
// 25.09.2019 AM 00002193(#168531456) Keine Bedarfe genehrieren, da diese bereits bei deliverx_xml generiert.
// 24.10.2019 BT #2233 distinction between 54 and 51, status "abrechenbar" if 'Ablieferbelg' document exists
// 15.09.2020 AM 174817220 (2572) LP's ohne Verweis auf Order_line (temp. Produkte) werden nicht als 'abrechenbar' gesetzt
//****************************************************************************************************************************

public class genehmigungStatusHelper {
    public static void updateLines (Set<id> genId) {
        List<Curabox_Genehmigungsposition__c> gpList = [SELECT id, Ant_Menge_Stk__c, Gen_Menge_Stk__c, genehmigt_bis__c, unbefristet_genehmigt__c,
                                                                Genehmigung__r.genehmigt_bis__c, Genehmigung__r.unbefristet_genehmigt__c
                                                            FROM Curabox_Genehmigungsposition__c
                                                            WHERE Genehmigung__c IN : genId];
        if((gpList != null) && (gpList.size() > 0)) {
            for(Curabox_Genehmigungsposition__c gp : gpList) {
                if(gp.genehmigt_bis__c == null) gp.genehmigt_bis__c = gp.Genehmigung__r.genehmigt_bis__c;
                gp.unbefristet_genehmigt__c = gp.Genehmigung__r.unbefristet_genehmigt__c;
                if(gp.Gen_Menge_Stk__c == null) gp.Gen_Menge_Stk__c = gp.Ant_Menge_Stk__c;
            }
            Database.SaveResult[]  srList = Database.update(gpList, false); 
        }
    }

    // für die nachträgliche Genehmigung
    // setzt Abrechnungsstatus_Krankenkasse__c = 'abrechenbar'
    // erzeugt die Bedarfe
    public static void updateKrankenkassenabrechnung(List<Curabox_Genehmigung__c> gnList) {                
        set<id> contact54IdSet = new set<id>();
        set<id> contact51IdSet = new set<id>();
        List<Delivery_Line__c> dlList = new List<Delivery_Line__c>();
        
        for(Curabox_Genehmigung__c gn : gnList) {
            if(gn.Nach_Paragraph__c == '51') {
                contact51IdSet.add(gn.Contact__c);
            }
            else if(gn.Nach_Paragraph__c == '54') {
                contact54IdSet.add(gn.Contact__c);
            }                      
        }
        
        // BT 24.10.2019    #2233 distinction between 54 and 51, check if 'Ablieferbelg' document exists
        if(contact54IdSet != null && contact54IdSet.size() > 0) {
            for(Delivery_Line__c dl: [SELECT Abrechnungsstatus_Krankenkasse__c                                                    
                                                FROM Delivery_Line__c 
                                                WHERE Contact__c IN :contact54IdSet 
                                                AND Delivery_status__c = 'geliefert'
                                                AND Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar'
                                                AND Delivery_Note__c != null
                                                AND Delivery_Note__r.rescission__c = false
                                                AND ((Order_line__c = null) OR (Order_line__r.Order__r.Description__c like 'CB%'))
                                                AND Delivery_Note__r.pod_recieved__c = true]) {
                                                
                dlList.add(dl);
            }                   
         }
         
         if(contact51IdSet != null && contact51IdSet.size() > 0){
              for(Delivery_Line__c dl: [SELECT Abrechnungsstatus_Krankenkasse__c                                                    
                                                FROM Delivery_Line__c 
                                                WHERE Contact__c IN :contact51IdSet 
                                                AND Delivery_status__c = 'geliefert'
                                                AND Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar'
                                                AND Delivery_Note__c != null
                                                AND Delivery_Note__r.rescission__c = false
                                                AND Order_line__r.Order__r.Description__c = 'KUWV'
                                                AND Delivery_Note__r.pod_recieved__c = true]) {
                                                
                dlList.add(dl);
            } 
         }
        
        if((dlList != null) && (dlList.size() > 0)) {           
            for(Delivery_Line__c dl : dlList) {
                dl.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
            }
            // Bedarf

            // delivery_xml d = new delivery_xml(true);
            // d.makeGenehmigungMap(gnList);
            // for(id ctid : ctIdSet) {
            //     List<Delivery_Line__c> tempList = new List<Delivery_Line__c>();
            //     for(Delivery_Line__c dl : dlList) {
            //         if(dl.Contact__c == ctid) {
            //             tempList.add(dl);
            //         }
            //     }
            //     system.debug('###### tempList.size()=' + tempList.size());
            //     List<Delivery_Line__c> tempBedarfList = d.createBedarf(ctid,tempList);
            //     list<string> errorList = d.getErrorList();
            //     if(errorList.size() > 0) {
            //         for(string line : errorList) {
            //             system.debug('###### alex 7010 error:' + line);
            //         }
            //     }                
            //     if((tempBedarfList != null) && (tempBedarfList.size() > 0)) {
            //         for(Delivery_Line__c dl : tempBedarfList) {
            //             dl.Delivery_status__c = 'Bedarf';
            //             dl.Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar';
            //             bedarfList.add(dl);
            //         }
            //     }
            // }
            // system.debug('###### bedarfList.size()=' + bedarfList.size());
            Database.SaveResult[]  sruList = Database.update(dlList, false); 
            // Database.SaveResult[]  sriList = Database.insert(bedarfList, false); 
            // Integer i = 0;           
            // for (Database.SaveResult sr : sriList) {
            //     if (sr.isSuccess()) {
            //         // alles ok
            //         system.debug('#### ok');
            //     }
            //     else {
            //         for(Database.Error err : sr.getErrors()) {
            //             system.debug('#################alex7705 error=' + err.getMessage());    
            //         }
            //     }
            //     i++;
            // }               
        }
        

    }
}