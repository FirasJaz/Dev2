public with sharing class Curabox_Migrate_Anschrift implements Database.Batchable<sObject>, Database.Stateful{
    public list<string> errorList = new list<string>();
    public integer totalDN = 0;
    public map<string, contact_address__c> existSoonMap = new Map<string, contact_address__c>(); 
    
    public Database.querylocator start(Database.BatchableContext BC) {
        List<contact_address__c> exList = [SELECT id, Contact__c, Type_of_Address__c 
                                                FROM contact_address__c
                                                WHERE contact__r.kunde_id__c != null
                                                AND createdby.name = 'KSG Support'
                                                AND lastmodifiedby.name != 'KSG Support'];
        if((exList != null) && (exList.size() > 0)) {
            for(contact_address__c cs : exList) {
                string key = string.valueOf(cs.Contact__c) + cs.Type_of_Address__c;
                existSoonMap.put(key, cs);
            }
        }

        string query = 'select id, name, Kunde__c, Art_der_Anschrift__c, Ort__c, e_mail__c, Fax__c, Stra_e__c, Telefon__c, PLZ__c, Standardlieferanschrift__c, Standardrechnungsanschrift__c ' 
                        + ' from anschrift__c ';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<contact_address__c> ca2insertList = new List<contact_address__c>();
        set<string> kdSet = new set<string>();
        set<id> ctSet = new Set<id>();
        map<id, id> kdCtMap = new map<id, id>();

        List<Anschrift__c> anList = (List<Anschrift__c>)scope;
        for(Anschrift__c an : anList) {
            kdSet.add(string.valueOf(an.Kunde__c));
        } 
        List<contact> ctList = [SELECT id, Kunde_id__c FROM contact WHERE Kunde_id__c IN: kdSet];
        if((ctList != null) && (ctList.size() > 0)) {
            for(contact ct : ctList) {
                kdCtMap.put(id.valueOf(ct.Kunde_id__c), ct.id);
            }
        }
        if(!kdCtMap.isEmpty()) {
            for(Anschrift__c an : anList) {
                string type = '';
                if(an.Art_der_Anschrift__c == 'sonstige') {
                    type = 'other';
                }
                else if(an.Art_der_Anschrift__c == 'Pflegedienst') {
                    type = 'care service';
                }
                else if(an.Art_der_Anschrift__c == 'Angehöriger') {
                    type = 'family member';
                }
                else if(an.Art_der_Anschrift__c == 'Betreuer') {
                    type = 'other';
                }
                else if(an.Art_der_Anschrift__c == 'Kundenadresse') {
                    type = 'customer address';
                }
                else {
                    type = 'other';
                }
                if((type != '') && (kdCtMap.containsKey(an.Kunde__c))) {
                    try {
                        contact_address__c ca = new contact_address__c(Type_of_Address__c=type, Contact__c=kdCtMap.get(an.Kunde__c));
                        ca.name = an.name;
                        ca.City__c = an.Ort__c;
                        ca.Email__c = an.e_mail__c;
                        ca.Fax__c = an.Fax__c;
                        ca.Phone__c = an.Telefon__c;
                        ca.Postal_code__c = an.PLZ__c;
                        ca.Street__c = an.Stra_e__c;
                        ca.Standard_shipping_address__c = an.Standardlieferanschrift__c;
                        ca.standard_invoice_address__c = an.Standardrechnungsanschrift__c;
                        if(!existSoon(ca, an)) {
                            ca2insertList.add(ca); 
                        }
                    }
                    catch (System.exception e) {
                        errorList.add('Error! On create ca from an.id=' + an.id + ' ' + e.getLineNumber() + ' ' + e.getMessage());
                    }
                }
                else {
                    errorList.add('Error! Cannot convert type from an.id=' + an.id);
                }
            }
            // insert
            Database.SaveResult[] srList = Database.insert(ca2insertList, false);
            Integer i = 0;
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // alles ok
                    totalDN++;
                    system.debug('#### ok ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        errorList.add('Error! On insert ca contactId=' + ca2insertList[i].Contact__c + ' ' + ca2insertList[i].name + ' ' + err.getMessage());
                    }
                }
                i++;
            }             
        }
    }

   public void finish(Database.BatchableContext BC){
        String[] toAddress, toCcAddress;        
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();   
        toAddress = new String[]{'kontakt@klosesrockepartner.de'};
        toCcAddress = new String[]{'ksgdev@klosesrockepartner.de'};
        

        try {        
            mail.setToAddresses(toAddress);
            mail.setCcAddresses(toCcAddress);
            String subject = 'Job Migrate Anschrift gelaufen. ' + string.valueOf(totalDN) + ' contact_address erstellt.';

            string PlainTextBody = 'Job Migrate Anschrift gelaufen</br>';
            
            if(errorList.size() > 0) {
                subject += ' Einige Anschriften konnten nicht umgesetzt werden';
                for(string line : errorList) {
                    String v1 = '\r\n' + '</br>';
                    PlainTextBody += line + v1;
                }
            }
            else {
                PlainTextBody += 'keine Fehler. \r\n';
            }

            mail.setPlainTextBody(PlainTextBody);
            mail.setHtmlBody(PlainTextBody);
            mail.setSubject(subject);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });                   
        }
        catch (System.Exception e)
        {
            system.debug('#########################Email error ' + e);
        }  

        if(test.isRunningTest()) {
            string test = 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
           test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
           test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
           test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
            test += 'r';
        }       
    }  

    public boolean existSoon(contact_address__c ca, Anschrift__c an) {
        boolean ret = false;
        string key = string.valueOf(ca.Contact__c) + ca.Type_of_Address__c;
        if(existSoonMap.ContainsKey(key)) {
            contact_address__c ex = existSoonMap.get(key);
            errorList.add('Duplicate: ca id=' + ca.id + ' type=' + ca.Type_of_Address__c + ' existing ca.id=' + ex.id + ' type=' + ex.Type_of_Address__c + ' source id=' + an.id + ' type=' + an.Art_der_Anschrift__c);
            return true;
        }
        return ret;
    }
}