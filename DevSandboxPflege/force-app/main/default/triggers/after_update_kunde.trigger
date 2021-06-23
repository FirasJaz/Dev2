//****************************************************************************************************************************
// Erstellt 04.06.2015 von wds
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
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
// Trigger after update Kunde
// Hier wird überprüft ob sich der Status des Kunden sich auf "Kunde" geändert hat. Wenn das der Fall ist,
// werden alle zughörigen Lieferpositionen mit Unterschrift auf abrechenbar gesetzt.
//
//
//****************************************************************************************************************************
//Änderungen:
//
// 19.06.2015 von AM:   Mantis 152
//                      Schließen einer offenen Aufgabe "Nachfassen..." bei Status "Vorgang geschlossen"
// 24.06.2015 von AM:   Mantis 152
//                      Schließen einer offenen Aufgabe "Nachfassen..."  und "Nachtelefonie von Interessenten"
// 25.08.2015 von wds:  #101102186 nachträgliche Ablehnung durch Pflegekasse Abrechnungsstatus LPos geändert
//
// 25.08.2015 von AM    #100636896 Kundenstatus als Object
// 22.09.2015 von wds   Magento durch zusätzlichen Kundenstatus Eintragung
// 19.11.2015 von wds   #108324372 Kundenstatus darf nicht automatisch auf gekündigt gesetzt werden, wenn im KD-Stamm die Produkt
//                      gruppe nicht mehr vorhanden ist
//****************************************************************************************************************************


trigger after_update_kunde on kunde__c (after update){
    set<id> kdAbgSet = new set<id>();
// AM 25.08.2015
    map<id, Kunde__c> kdPgMap = new map<id, Kunde__c>();
    map<string, Kundenstatus__c> kdKsMap = new map<string, Kundenstatus__c>();
    map<string, id> rtMap = new map<string, id>();
    list<Kundenstatus__c> ksUpdate = new list<Kundenstatus__c>();
    list<Kundenstatus__c> ksInsert = new list<Kundenstatus__c>();
    list<string> pgList = new list<string>();
    
    pgList.add('PG54');
    pgList.add('PG51');
    pgList.add('Inko');
    pgList.add('Shop');
    id rtid = null;  
    for (Kunde__c KD : Trigger.new){
        if(KD.Produktgruppe__c != trigger.OldMap.get(KD.id).Produktgruppe__c) {
            kdPgMap.put(KD.id, KD);
        }
    }
    
    if(!kdPgMap.isEmpty()) {
                                      
        list<RecordType> rtList1 = [SELECT Id, Name FROM RecordType WHERE sObjectType='Kundenstatus__c'];
        if((rtList1 != null) && (rtList1.size() > 0)) {
            for(RecordType rt : rtList1) {
                if(rt.Name.contains('51')) rtMap.put('PG51', rt.id);
                if(rt.Name.contains('54')) rtMap.put('PG54', rt.id);
                if(rt.Name.contains('Inko')) rtMap.put('Inko', rt.id);
                if(rt.Name.contains('Shop')) rtMap.put('Shop', rt.id);
            }
        } 
        
        
        list<Kundenstatus__c> ksList = [SELECT id, Kunde__c, Status__c, Produktgruppe__c, 
                                                K_ndigungsgrund__c, K_ndigungsdatum__c, K_ndigungsbemerkung__c 
                                        FROM Kundenstatus__c
                                        WHERE Kunde__c IN :kdPgMap.keySet()
                                        AND Status__c IN ('Interessent', 'Kunde', 'Kandidat')];
        if((ksList != null) && (ksList.size() > 0)) {
            for(Kundenstatus__c KS : ksList ) {
                string key = KS.Produktgruppe__c + string.valueOf(KS.Kunde__c);
                kdKsMap.put(key, KS);
            }
        }
    
        for (Kunde__c KD : kdPgMap.values()) {
                for(string ksp : pgList) {
                    rtid = rtMap.get(ksp);  
                    string key = ksp + string.valueOf(KD.id);
                    if (KD.Produktgruppe__c != Null && KD.Produktgruppe__c.contains(ksp)) {                        
                        if(!kdKsMap.containsKey(key)) {
                            Kundenstatus__c KS = new Kundenstatus__c(Kunde__c = KD.id, Status__c = 'Interessent', Produktgruppe__c = ksp, RecordTypeId = rtid);
                            ksInsert.add(KS);
                        }                       
                    }
                    else {
                        if(kdKsMap.containsKey(key)) {
// ausgesternt am 19.11.15                        
//                            Kundenstatus__c KS = kdKsMap.get(key);
//                            KS.Status__c = 'Kündigung';
//                            KS.K_ndigungsdatum__c = date.today();
//                            KS.K_ndigungsbemerkung__c = 'Produktgruppe bei Kunde geändert';
//                            KS.K_ndigungsgrund__c = 'Kündigung eines bestehenden Kunden';
//                            ksUpdate.add(KS);                                               
                        }
                    }
                    
                }
        }
        
        
        if(!ksInsert.isEmpty()) {
            try {
                insert ksInsert;
            }
            catch (System.Exception e) {
                system.debug('######################### error insert ksInsert' + e);
            }
        }   
        if(!ksUpdate.isEmpty()) {
            try {
                update ksUpdate;
            }
            catch (System.Exception e) {
                system.debug('######################### error update ksUpdate' + e);
            }
        }                   

    }
// AM 25.08.2015 end    
    
}