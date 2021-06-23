// Erstellt 18.08.2017 von BT
//  Klose und Srocke Gesellschaft für kreative Konfliktlösungen GmbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:
//         
//
//****************************************************************************************************************************
// Änderungen:
//
//****************************************************************************************************************************
trigger after_update_Partner_Produkte on Partner_Produkte__c (after update) {
    Set<id> ppIdSet = new Set<id>();
    List<Partner_PLZ_Gebiet__c> zuUpdatePLZGebList = new List<Partner_PLZ_Gebiet__c>();
    date heute = date.today();
    
    for(Partner_Produkte__c pp: trigger.new) {
        if(Trigger.oldMap.get(pp.Id) != null &&
           ! Trigger.oldMap.get(pp.Id).Deutschlandweit_verf_gbar__c){
            if(pp.Deutschlandweit_verf_gbar__c) {
                ppIdSet.add(pp.Id);
            
                Partner_PLZ_Gebiet__c plzGebiet = new Partner_PLZ_Gebiet__c();
                plzGebiet.Partner_Produkte__c = pp.Id;
                plzGebiet.von__c = 00000;
                plzGebiet.bis__c = 99999;
                plzGebiet.include_exclude__c = 'inbegriffen';
                plzGebiet.G_ltig_von__c = heute;
            
                zuUpdatePLZGebList.add(plzGebiet);
            }
        }
    }
    
    List<Partner_PLZ_Gebiet__c> plzGebListe = [select id, G_ltig_von__c, G_ltig_bis__c, Partner_Produkte__c
                                                    from Partner_PLZ_Gebiet__c
                                                    where G_ltig_von__c <= :heute
                                                    and (G_ltig_bis__c >= :heute or G_ltig_bis__c = null)
                                                    and Partner_Produkte__c in: ppIdSet];
    
    for(Partner_PLZ_Gebiet__c plzGeb: plzGebListe) {
        plzGeb.G_ltig_bis__c = heute - 1;
    }
    
    if(! plzGebListe.isEmpty()) {
        update plzGebListe;
    }
    
    if(! zuUpdatePLZGebList.isEmpty()) {
        insert zuUpdatePLZGebList;
    }
}