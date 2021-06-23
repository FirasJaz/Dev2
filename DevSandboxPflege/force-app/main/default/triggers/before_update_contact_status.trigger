//****************************************************************************************************************************
// Created on 02.08.2019   by BT
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
// None
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//          Set date "Antrag_eingegangen am" to today
//
//
//****************************************************************************************************************************
//Änderungen:
//      26.08.2019  BT  set Antrag_bewilligt_abgelehnt_am__c if status is 'Kündigung'
//***************************************************************************************************************
trigger before_update_contact_status on Contact_Status__c (before update) {
    set<id> kdVerstorbenSet = new set<id>();
    set<id> kdPflegeheimSet = new set<id>();
    set<id> ksVerstorbenSet = new set<id>();
    set<id> ksPflegeheimSet = new set<id>();

    map<id, Contact_Status__c> kdMap = new map<id, Contact_Status__c>();


    for (Contact_Status__c KS : Trigger.new) {
        if ((trigger.OldMap.get(KS.id).Status__c == 'Interessent') 
             &&  (KS.Status__c == 'Kandidat' || KS.status__c == 'Kunde' ) 
             && KS.Productgroup__c != 'Inko' && KS.Antrag_eingegangen_am__c == null) {
                KS.Antrag_eingegangen_am__c = date.today();
        }
        if (ks.K_ndigungsdatum__c != null){
             ks.status__c = 'Kündigung';
        }    

        if (ks.K_ndigungsbemerkung__c == 'verstorben') {
            Ks.status__c = 'Kündigung';
            kdVerstorbenSet.add(KS.Contact__c);
            ksVerstorbenSet.add(KS.id);            
        }
 
        if (ks.K_ndigungsbemerkung__c == 'Kunde/In geht ins Pflegeheim'){
            Ks.Status__c = 'Kündigung';
            kdPflegeheimSet.add(KS.Contact__c);
            ksPflegeheimSet.add(KS.id);                  
            }   
        if(KS.Status__c == 'Kündigung') kdMap.put(KS.Contact__c, KS);              
         
    }

    if(!kdVerstorbenSet.isEmpty()) {
        list<Contact_Status__c> kstatus = [SELECT Status__c, Contact__c, Antrag_bewilligt_abgelehnt_am__c 
                                            FROM Contact_Status__c  
                                            WHERE Contact__c IN : kdVerstorbenSet 
                                            AND id NOT IN : ksVerstorbenSet
                                            AND Status__c NOT IN ('Vorgang geschlossen', 'Kündigung')];
            for (Contact_Status__c kst : kstatus) { 
                kst.Status__c = 'Kündigung';
                kst.K_ndigungsbemerkung__c = 'verstorben';
                kst.Antrag_bewilligt_abgelehnt_am__c = kdMap.get(kst.Contact__c).Antrag_bewilligt_abgelehnt_am__c;
                if(kdMap.containsKey(kst.Contact__c)) {
                    kst.K_ndigungsgrund__c = kdMap.get(kst.Contact__c).K_ndigungsgrund__c;
                    kst.K_ndigungsdatum__c = kdMap.get(kst.Contact__c).K_ndigungsdatum__c;
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
        list<Contact_Status__c> kstatus = [SELECT Status__c, Contact__c 
                                            FROM Contact_Status__c  
                                            WHERE Contact__c IN : kdPflegeheimSet 
                                            AND id NOT IN : ksPflegeheimSet
                                            AND Status__c NOT IN ('Vorgang geschlossen', 'Kündigung')];
            for (Contact_Status__c kst : kstatus) { 
                kst.Status__c = 'Kündigung';
                kst.K_ndigungsbemerkung__c = 'Kunde/In geht ins Pflegeheim';
                kst.Antrag_bewilligt_abgelehnt_am__c = kdMap.get(kst.Contact__c).Antrag_bewilligt_abgelehnt_am__c;
                if(kdMap.containsKey(kst.Contact__c)) {
                    kst.K_ndigungsgrund__c = kdMap.get(kst.Contact__c).K_ndigungsgrund__c;
                    kst.K_ndigungsdatum__c = kdMap.get(kst.Contact__c).K_ndigungsdatum__c;
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