//****************************************************************************************************************************
// Erstellt ?              von ?
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
// läuft vor dem update des Kundenstatuses setzt das Datum "Antrag_eingegangen am" auf today
//
//
//****************************************************************************************************************************
//Änderungen:
//
// 
// 28.08.2015 von wds #102163008 Status auf Kündigung setzen wenn Kunde verstorben
//                    #102163008 Kündigungsdatum mitbefüllen
// 30.08.2015 von wds #          Wenn Kündigungsdatum gesetzt, dann auch Status "Kündigung" setzen"
// 
// 08.02.2016 von wds #111866605 Status auf Kündigung setzen, wenn "Kunde/In geht ins Pflegeheim"
// 06.12.2016 von BT  #132997285 Kündingungsbemerkung wird in allen anderen Kundenstatus übernommen, wenn Kündingungsbemerkung 
//                    einer Kundenstatus "verstorben" oder "Kunde/In geht ins Pflegeheim" lautet
//  15.08.2017  AM  Bei "verstorben" oder "Kunde/In geht ins Pflegeheim" sollen nur aktive Stati geändert werden.
//                  Generelle Änderungen wegen SOQL und DML in for-loop 
//***************************************************************************************************************
trigger before_update_kundenstatus on Kundenstatus__c (before update) {
    set<id> kdVerstorbenSet = new set<id>();
    set<id> kdPflegeheimSet = new set<id>();
    set<id> ksVerstorbenSet = new set<id>();
    set<id> ksPflegeheimSet = new set<id>();

    map<id, Kundenstatus__c> kdMap = new map<id, Kundenstatus__c>();


    for (Kundenstatus__c KS : Trigger.new) {
        if ((trigger.OldMap.get(KS.id).Status__c == 'Interessent') 
             &&  (KS.Status__c == 'Kandidat' || KS.status__c == 'Kunde' ) 
             && KS.Produktgruppe__c != 'Inko' && KS.Antrag_eingegangen_am__c == null) {
                KS.Antrag_eingegangen_am__c = date.today();
        }
        if (ks.K_ndigungsdatum__c != null){
             ks.status__c = 'Kündigung';
        }    

        if (ks.K_ndigungsbemerkung__c == 'verstorben') {
            Ks.status__c = 'Kündigung';
            kdVerstorbenSet.add(KS.kunde__c);
            ksVerstorbenSet.add(KS.id);
            // list<Kundenstatus__c> kstatus = [select status__c 
            //                                 from kundenstatus__c  
            //                                 where kunde__c =: KS.kunde__c and id !=: KS.id];
                                            
                                            
            // for (Kundenstatus__c kst : kstatus) { 
            //     kst.status__c = 'Kündigung';
            //     kst.K_ndigungsgrund__c = KS.K_ndigungsgrund__c;
            //     kst.K_ndigungsbemerkung__c = 'verstorben';
            //     kst.K_ndigungsdatum__c = KS.K_ndigungsdatum__c;
            // }                                 
            // try {
            //         update kstatus;
            //     }
            // catch(system.exception e) {
            //         system.debug('######################### error update tsList ' + e);
            //     }  

        }
 
        if (ks.K_ndigungsbemerkung__c == 'Kunde/In geht ins Pflegeheim'){
            Ks.Status__c = 'Kündigung';
            kdPflegeheimSet.add(KS.kunde__c);
            ksPflegeheimSet.add(KS.id);
        //  list<Kundenstatus__c> kstatuspf = [select status__c 
        //                                     from kundenstatus__c  
        //                                     where kunde__c =: KS.kunde__c and id !=: KS.id];
                                            
                                            
        //  for (Kundenstatus__c kstpf : kstatuspf) { 
        //      kstpf.status__c = 'Kündigung';
        //      kstpf.K_ndigungsgrund__c = KS.K_ndigungsgrund__c;
        //      kstpf.K_ndigungsbemerkung__c = 'Kunde/In geht ins Pflegeheim';
        //      kstpf.K_ndigungsdatum__c = KS.K_ndigungsdatum__c;
        //        }                                 
        //      try {
        //             update kstatuspf;
        //         }
        //         catch(system.exception e) {
        //             system.debug('######################### error update tsList ' + e);
        //         }               
            }   
        if(KS.Status__c == 'Kündigung') kdMap.put(KS.Kunde__c, KS);              
         
    }

    if(!kdVerstorbenSet.isEmpty()) {
        list<Kundenstatus__c> kstatus = [SELECT Status__c, Kunde__c 
                                            FROM Kundenstatus__c  
                                            WHERE Kunde__c IN : kdVerstorbenSet 
                                            AND id NOT IN : ksVerstorbenSet
                                            AND Status__c NOT IN ('Vorgang geschlossen', 'Kündigung')];
            for (Kundenstatus__c kst : kstatus) { 
                kst.Status__c = 'Kündigung';
                kst.K_ndigungsbemerkung__c = 'verstorben';
                if(kdMap.containsKey(kst.Kunde__c)) {
                    kst.K_ndigungsgrund__c = kdMap.get(kst.Kunde__c).K_ndigungsgrund__c;
                    kst.K_ndigungsdatum__c = kdMap.get(kst.Kunde__c).K_ndigungsdatum__c;
                }
            }                                 
            try {
                    update kstatus;
                }
            catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                } 
                                        
    }  

    if(!kdPflegeheimSet.isEmpty()) {
        list<Kundenstatus__c> kstatus = [SELECT Status__c, Kunde__c 
                                            FROM Kundenstatus__c  
                                            WHERE Kunde__c IN : kdPflegeheimSet 
                                            AND id NOT IN : ksPflegeheimSet
                                            AND Status__c NOT IN ('Vorgang geschlossen', 'Kündigung')];
            for (Kundenstatus__c kst : kstatus) { 
                kst.Status__c = 'Kündigung';
                kst.K_ndigungsbemerkung__c = 'Kunde/In geht ins Pflegeheim';
                if(kdMap.containsKey(kst.Kunde__c)) {
                    kst.K_ndigungsgrund__c = kdMap.get(kst.Kunde__c).K_ndigungsgrund__c;
                    kst.K_ndigungsdatum__c = kdMap.get(kst.Kunde__c).K_ndigungsdatum__c;
                }
            }                                 
            try {
                    update kstatus;
                }
            catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                } 
                                        
    }                                           
     
}