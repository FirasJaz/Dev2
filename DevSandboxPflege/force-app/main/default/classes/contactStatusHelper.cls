//****************************************************************************************************************************
// Erstellt 07.06.2019 von AM
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
// Sorgt für das Anlegen ind Pflege von Kundenstatus (Contact_Status__c)
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
//
//****************************************************************************************************************************
public class contactStatusHelper {

    // Aufruf durch trigger Contact after insert
    public static map<id, string> creteNewStatusOnNewContactFromLead(list<contact> ctList ) {

        Map<id, string> wrongStatusContactSet = new Map<id, string>();
        List<contact_status__c> newList = new List<contact_status__c>();
        Set<id> campaignIdSet = new Set<id>();
        Set<id> contactIdSet = new Set<id>();

        List<campaign> cpList = [SELECT id FROM campaign LIMIT 1000];
        if((cpList != null) && (cpList.size() > 0)) {
            for(campaign cp : cpList) {
                campaignIdSet.add(cp.id);
            }
        }

        for(contact c : ctList) {
            if( (c.Ursprungsanfrage__c != null) && (c.Art_des_Kontakts__c != null) && (c.Art_des_Kontakts__c.containsIgnoreCase('Pflegebedürftige')) 
            ) {
                    // && (campaignIdSet.contains(c.Ursprungsanfrage__c))) {
                        contactIdSet.add(c.id);              
            }
        }

        if(!contactIdSet.isEmpty()) {
            List<contact> ctToCreate = readContacts(contactIdSet, campaignIdSet);
            if(ctToCreate != null) {
                for(contact c : ctToCreate) {
                    contact_status__c cs = createSingleStatus(c, 'PG54');
                    newList.add(cs); 
                    contact_status__c cs2 = createSingleStatus(c, 'PG51');
                    newList.add(cs2); 
                }
            }
        }

        Database.SaveResult[] sriList = Database.insert(newList, false);
        Integer i = 0;
        
        for (Database.SaveResult sr : sriList) {
            if (sr.isSuccess()) {
                // alles ok
                system.debug('#### ok');
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    system.debug('#################alex7705 error=' + err.getMessage()); 
                    wrongStatusContactSet.put(newList[i].Contact__c, err.getMessage());    
                }
            }
            i++;
        }           
      
        return wrongStatusContactSet;
    }

    @TestVisible private static List<contact> readContacts(Set<id> contactIdSet, Set<id> campaignIdSet) {
        List<contact> ctoutList = new List<contact>();
        List<contact> ctList = [SELECT Id, name, 
                                        Ursprungsanfrage__c,
                                        lead__c, 
                                        lead__r.RecordType.name,
                                        lead__r.name, 
                                        lead__r.OM_Wizard_Version__c, 
                                        lead__r.OM_created_at__c, 
                                        lead__r.OM_Tracking_Order_ID__c, 
                                        lead__r.OM_Referrer__c,
                                        lead__r.CB_Box__c, 
                                        lead__r.CB_Lieferung__c, 
                                        lead__r.OM_Wizzard_Name2__c               
                                FROM contact 
                                WHERE id IN : contactIdSet];
        if((ctList != null) && (ctList.size() > 0)) {
            for(contact c : ctList) {
                if(c.lead__r.RecordType.name == 'Curabox') {
                    ctoutList.add(c);
                }
                else if ( (c.Ursprungsanfrage__c != null) && (campaignIdSet.contains(c.Ursprungsanfrage__c))) {
                    ctoutList.add(c);
                }
            }
        }
        return ctoutList;
    }

    @TestVisible private static contact_status__c createSingleStatus(contact c, string pg) {
        boolean ok = false;
        contact_status__c cs = new contact_status__c(Contact__c = c.id);
        cs.Productgroup__c = pg;
        cs.Status__c = 'Interessent';
        cs.Ursprungsanfrage__c = c.Ursprungsanfrage__c;
        cs.Tracking_Order_ID__c = c.lead__r.OM_Tracking_Order_ID__c;
        cs.Created_at_c__c = c.lead__r.OM_created_at__c;
        cs.Referrer__c = c.lead__r.OM_Referrer__c;
        cs.Wizard_Version__c = c.lead__r.OM_Wizard_Version__c;
        cs.delivery_address__c = 'customer address';
        if(c.lead__r.CB_Lieferung__c == 'insured_person') cs.delivery_address__c = 'customer address';
        if(c.lead__r.CB_Lieferung__c == 'care_person') cs.delivery_address__c = 'family member';
        if(c.lead__r.CB_Lieferung__c == 'care_service') cs.delivery_address__c = 'care service';
        return cs;
    }

    public static boolean setAntragEingegangen(string objId) {
        contact_status__c cs = readSingleStatus(objId);
        if(cs != null) {
            cs.Status__c = 'Kandidat';
            cs.Antrag_eingegangen_am__c = date.today();
            try {
                update cs;
            }
            catch(System.exception e) {
                return false;
            }
        }
        else {
            return false;
        }
        return true;
    }

    public static boolean setAntragEingegangen(id contactId, String pg) {
        try {
            if(!pg.contains('PG')) pg = 'PG' + pg;
            set<string> pgset = new Set<String>();
            if(pg == 'PG5X') {
                pgset.add('PG51');
                pgset.add('PG54');
            }
            else {
                pgset.add(pg);
            }

            boolean wasChanged = false;
            List<contact_status__c>  csList = [SELECT id, Status__c, Antrag_eingegangen_am__c, Antrag_bewilligt_abgelehnt_am__c 
                                    FROM contact_status__c
                                    WHERE Contact__c = : contactId
                                    AND Productgroup__c IN :pgset];
            if((csList != null) && (csList.size() > 0 )) {
                for(contact_status__c cs : csList) {
                    if((cs.Status__c == 'Interessent') || (cs.Status__c == 'Vorgang geschlossen') ) {
                        cs.Status__c = 'Kandidat';
                        wasChanged = true;
                    }
                    if( cs.Antrag_eingegangen_am__c == null) {
                        cs.Antrag_eingegangen_am__c = date.today();
                        wasChanged = true;
                    }
                }
            }
            if(wasChanged == true) {
                update csList;  
            }                                   
            return true;
        }
        catch (System.Exception e ) {
            // contact c = [SELECT id FROM contact WHERE id = :contactId];
            // c.addError(e.getMessage());
            return false;
        }       
    }

    public static boolean setAntragGenehmigt(string objId) {
        contact_status__c cs = readSingleStatus(objId);
        if(cs != null) {
            cs.Status__c = 'Kunde';
            if(cs.Antrag_bewilligt_abgelehnt_am__c == null) {
                cs.Antrag_bewilligt_abgelehnt_am__c = date.today();
            }
            try {
                update cs;
            }
            catch(System.exception e) {
                return false;
            }
        }
        else {
            return false;
        }
        return true;
    }

    public static boolean setAntragGenehmigt(id contactId, String pg) {
        try {

            if(!pg.contains('PG')) pg = 'PG' + pg;
            contact_status__c  cs = [SELECT id, Status__c, Antrag_eingegangen_am__c, Antrag_bewilligt_abgelehnt_am__c 
                                    FROM contact_status__c
                                    WHERE Contact__c = : contactId
                                    AND Productgroup__c = :pg];
            cs.Status__c = 'Kunde';
            if (cs.Antrag_bewilligt_abgelehnt_am__c == null) {
                cs.Antrag_bewilligt_abgelehnt_am__c = date.today();
            }
            update cs;
            return true;
        }
        catch (System.Exception e ) {
            return false;
        }   
    }

    public static void setAntragGenehmigtList(set<id> contactIdSet, String pg) {
        try {
            List<contact_status__c>  csList = [SELECT id, Status__c, Antrag_eingegangen_am__c, Antrag_bewilligt_abgelehnt_am__c 
                                    FROM contact_status__c
                                    WHERE Contact__c IN : contactIdSet
                                    AND Productgroup__c = :pg];
            if((csList != null) && (csList.size() > 0)) {
                for(contact_status__c cs: csList) {
                    cs.Status__c = 'Kunde';
                    if(cs.Antrag_bewilligt_abgelehnt_am__c == null) {
                        cs.Antrag_bewilligt_abgelehnt_am__c = date.today();
                    }
                }
            }
            Database.SaveResult[] srList = Database.update(csList, false);                             
            
        }
        catch (System.Exception e ) {
            
        }   
    }

    @TestVisible private static contact_status__c readSingleStatus(id objId) {
        contact_status__c cs = null;
        String pg = null;
        id contactId = null; 
        try {
            String objType = objId.getSObjectType().getDescribe().getName();
            if(objType == 'Curabox_Genehmigung__c') {
                Curabox_Genehmigung__c gn = [SELECT Contact__c, Nach_Paragraph__c FROM Curabox_Genehmigung__c WHERE id = : objId];
                contactId = gn.Contact__c;
                pg = 'PG' + gn.Nach_Paragraph__c;
            } else if(objType == 'Order__c') {
                Order__c od = [SELECT Contact__c, Nach_Paragraph__c FROM Order__c WHERE id = : objId];
                contactId = od.Contact__c;
                pg = 'PG' + od.Nach_Paragraph__c;
            }
            if(contactId != null) {
                cs = [SELECT id, Status__c, Antrag_eingegangen_am__c, Antrag_bewilligt_abgelehnt_am__c 
                        FROM contact_status__c
                        WHERE Contact__c = : contactId
                        AND Productgroup__c = :pg];
            }
        }
        catch (System.Exception e) {
            

        }
        return cs;
    }

}