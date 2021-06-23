//****************************************************************************************************************************
// Erstellt 02.06.2019 von AM
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
// Sorgt für das updatecontact_status 'Kunde'
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
trigger curabox_genehmigung_trigger on Curabox_Genehmigung__c (before insert, after update) {
    Set<Id> ContIdset54 = new Set<Id>();
    Set<Id> ContIdset51 = new Set<Id>();
    Set<Id> GenIdset = new Set<Id>();
    List<Curabox_Genehmigung__c> gnList = new List<Curabox_Genehmigung__c>();
    if(trigger.isBefore) {
        if(trigger.isInsert) {
            for(Curabox_Genehmigung__c gn : trigger.new) {
                if(gn.Antrag_eingegangen_am__c == null) {
                    gn.Antrag_eingegangen_am__c = date.today();
                }
            }            
        }
    }
    if(trigger.isAfter) {
        if(trigger.isUpdate) {
            if(trigger.isAfter) {
                for(Curabox_Genehmigung__c gn : trigger.new) {
                    if((gn.Status__c == 'Bewilligung') && (trigger.oldMap.get(gn.id).Status__c == 'Antragsversand')) {
                        if(gn.Nach_Paragraph__c == '51') {
                            ContIdset51.add(gn.Contact__c);
                        }
                        else if(gn.Nach_Paragraph__c == '54') {
                            ContIdset54.add(gn.Contact__c);
                        }
                        GenIdset.add(gn.id);
                        gnList.add(gn);
                    }
                }
                if(!ContIdset51.isEmpty()) {
                    contactStatusHelper.setAntragGenehmigtList(ContIdset51, 'PG51');
                } 
                if(!ContIdset54.isEmpty()) {
                    contactStatusHelper.setAntragGenehmigtList(ContIdset54, 'PG54');
                } 
                if(!GenIdset.isEmpty()) {
                    genehmigungStatusHelper.updateLines(GenIdset);
                }
                if(!gnList.isEmpty()) {
                    genehmigungStatusHelper.updateKrankenkassenabrechnung(gnList);
                }
            }
        }
    }
}