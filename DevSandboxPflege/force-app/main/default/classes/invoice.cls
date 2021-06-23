/*/****************************************************************************************************************************
// Erstellt 18.06.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: keine - batch
// 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//  Erstellen die Rechnungen + Rechnungspositionen
//  
//
//****************************************************************************************************************************
//Änderungen:       
//****************************************************************************************************************************
*/
public class invoice implements Database.Batchable<sObject>,  Database.Stateful {

    public list<string> errorList = new list<string>();
    public integer totalDN = 0;
    public boolean Medifox = false;
    public string kkName = '';  
    public string kkstr = '';
    public Map<String, id> ivMap = new Map<String, id>();
 
    public invoice(boolean Medifox) {
        this.Medifox = Medifox;
    }

    public invoice(boolean Medifox, string kkName) {
        this.Medifox = Medifox;
        this.kkName = kkName;
    }

    public Database.querylocator start(Database.BatchableContext BC) {
        kkstr = '%' + kkName + '%';
        System.debug('#### alex5010 ' + kkstr);
        string query = 'SELECT id FROM Delivery_Note__c WHERE Status__c IN (\'nicht abgerechnet\', \'teilweise abgerechnet\') AND pod_recieved__c = true AND Contact__r.Medifox_Kunde__c = : Medifox AND Contact__r.Kranken_Pflegekasse__r.name like : kkstr AND id IN (SELECT delivery_note__c FROM delivery_line__c WHERE Abrechnungsstatus_Krankenkasse__c = \'abrechenbar\')' ;
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Delivery_Note__c> dnList = (List<Delivery_Note__c>)scope;
        set<id> dnIdSet = new set<id>();
        for(Delivery_Note__c dn : dnList) {
            dnIdSet.add(dn.id);
        }  

        createInvoiceLines cil = new createInvoiceLines();
        cil.setIvMap(ivMap);
        cil.createLines(dnIdSet, Medifox);     
        ivMap = cil.getIvMap();     
        if(cil.getErrorListSize() > 0) {
            if(errorList.size() <= 800) errorList.addAll(cil.getErrorList());
        }
        totalDN += cil.getTotalDN();
    }

    public void finish(Database.BatchableContext BC){
        String[] toAddress, toCcAddress;
        
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();   

        try{
            toAddress = new String[] {Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse__c};
            toCcAddress = Status_Emails__c.getValues('curabox Lieferungen ausloesen').Empf_nger_Email_Adresse_CC__c.split(', ');
        }
        catch(System.exception e){
            toAddress = new String[]{'kontakt@klosesrockepartner.de'};
            toCcAddress = new String[]{'kontakt@klosesrockepartner.de'};
        }

        try {        
            mail.setToAddresses(toAddress);
            mail.setCcAddresses(toCcAddress);
            mail.setSubject('Job Abrechnung gelaufen. ' + String.valueOf(ivMap.size()) + ' Rechnungen erstellt. ' + String.valueOf(totalDN) + ' Lieferscheinen abgerechnet.');
            string PlainTextBody = 'Job Abrechnung gelaufen</br>';
            
            if(errorList.size() > 0) {
                for(string line : errorList) {
                    PlainTextBody += line + '\r\n</br>';
                }
            }
            else {
                PlainTextBody += 'keine Fehler. \r\n';
            }

            mail.setPlainTextBody(PlainTextBody);
            mail.setHtmlBody(PlainTextBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });                   
        }
        catch (System.Exception e)
        {
            system.debug('#########################Email error ' + e);
        }         
    }        
            
    // public void execute(SchedulableContext sc){
    //     ID batchprocessid = Database.executeBatch(new invoice (), 200);
    // }

}