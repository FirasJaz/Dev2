/*/****************************************************************************************************************************
// Erstellt 27.03.2021 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frohmestr. 49
//                         22457 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Rechnungsname - String
//            
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//  Erstellen CSV.Datei für ASB. Aufruf aus trigger
//  
//
//****************************************************************************************************************************
//Änderungen:   26.05.2021 AM   Es soll ausser "normalen" CSV noch eine nur mit beihilfeberechtigt generiert werden    
//****************************************************************************************************************************
*/
public with sharing class batchCreateCsvAsb implements Database.Batchable<sObject>, Database.Stateful {
    public string rgname = null;
    public String csvString;
    public integer lineNumber;
    public boolean privat = false;
    public String productGroup;
    public boolean beihilfeberechtigt = false;
    public string csvType; 

    // constructor "Gesetzlich"
    public batchCreateCsvAsb(String rgName) {
        this.rgname = rgname.Trim();
        this.lineNumber = 0;
    }

    // constructor "Privat"
    public batchCreateCsvAsb(String rgName, boolean privat) {
        this.rgname = rgname.Trim();
        this.privat = privat;
        this.lineNumber = 0;
    }

    // constructor "beihilfeberechtigt"
    public batchCreateCsvAsb(String rgName, boolean privat, boolean beihilfeberechtigt) {
        this.rgname = rgname.Trim();
        this.privat = privat;
        this.beihilfeberechtigt = beihilfeberechtigt;
        this.lineNumber = 0;
    }

    public Database.querylocator start(Database.BatchableContext BC) {
        String rgSearchName = '%' + this.rgName + '%';
        set<String> unterpunkt = new set<String>();
        if(this.privat) {
            unterpunkt.add('privat');
        }
        else {
            unterpunkt.add('gesetzlich');
            unterpunkt.add('Sozialamt');
        }
        string mandantNummer = null;
        List<invoice__c> ivList = [SELECT id, Name, invoice_text__c, csv_created__c FROM invoice__c WHERE Name = :  this.rgName];
        if((ivList != null) && (ivList.size() >0 )) {
            this.csvType = ivList[0].invoice_text__c.Replace(' ', '_');
            string[] splits = ivList[0].invoice_text__c.split(' ');
            if(splits[1] == 'Standard') {
                mandantNummer = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerWebcare__c;
            }
            else {
                mandantNummer = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerMedifox__c;
            }
            this.productGroup = splits[0];
            this.csvString = 'VERSION\t1.2\r\nMA' + '\t' + mandantNummer + '\r\n';
        }
        string query = 'SELECT id, name, csv_block__c, csv_block_KUWV__c, CSV_Line_summe__c, csv_SU__c, csv_KUWV_SU__c, delivery_text__c, '
                        +  ' (SELECT id, CSV_Line__c, order_line__r.Order__r.Nach_Paragraph__c, order_line__r.Order__r.description__c FROM delivery_lines__r) '
                        +  ' FROM Delivery_Note__c'
                        +  ' WHERE invoice_numbers__c LIKE : rgSearchName';

                        // Mit Beihilfeberechtigt für Privat und Ges. zusammen
                        if(this.beihilfeberechtigt) {
                            query += ' AND Contact__r.Beihilfeberechtigt__c = true ';
                        }
                        else {
                            query += ' AND Contact__r.Kranken_Pflegekasse__r.Kanal_Unterpunkt__c IN : unterpunkt';
                        }
                        query += ' ORDER BY Contact__r.Kranken_Pflegekasse__r.IK_Nummer__c, name';
                                                
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Delivery_Note__c> dnList = (List<Delivery_Note__c>)scope;
        if((dnList != null) && (dnList.size() > 0)) {
            for(Delivery_Note__c dn : dnList) {
                this.lineNumber++;
                String csv_block = '';
                String dnRgName = this.rgName + '\t' + dn.Name;
                if(this.productGroup == 'KUWV') {
                    if(dn.csv_block_KUWV__c != null) {
                        csv_block = dn.csv_block_KUWV__c.replace(dn.Name, dnRgName);
                    }
                    else {
                        break;
                    }
                }
                else {
                    if(dn.csv_block__c != null) {
                        csv_block = dn.csv_block__c.replace(dn.Name, dnRgName);
                    }
                    else {
                        break;
                    }
                }
                this.csvString += 'BA\t' + string.valueOf(this.lineNumber) + '\t' + csv_block + '\r\n'; 

                if((dn.CSV_Line_summe__c != null) && (this.productGroup != 'KUWV')) {
                    this.csvString += dn.CSV_Line_summe__c + '\r\n';
                }
                else {
                    for(Delivery_Line__c dl : dn.Delivery_Lines__r) {
                        if(this.productGroup == 'KUWV') {
                            if(dl.Order_line__r != null) {
                                if(dl.Order_line__r.Order__r.description__c == 'KUWV') {
                                    this.csvString += dl.CSV_Line__c + '\r\n';
                                }
                            }
                            else {
                                if(dn.delivery_text__c.startsWith('KUWV') ) {
                                    this.csvString += dl.CSV_Line__c + '\r\n';
                                }
                            }
                        }
                        else {
                            if(dl.Order_line__r != null) {
                                if(dl.Order_line__r.Order__r.description__c.startsWith('CB')) {
                                    this.csvString += dl.CSV_Line__c + '\r\n';
                                }
                            }
                            else {
                                if(dn.delivery_text__c.startsWith('CB') ) {
                                    this.csvString += dl.CSV_Line__c + '\r\n';
                                }
                            }
                        }
                    }
                }
                // Summe
                if(this.productGroup == 'KUWV') {
                    this.csvString += dn.csv_KUWV_SU__c;
                }
                else {
                    csvString += dn.csv_SU__c;
                }
                this.csvString += '\r\n';
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        asMail__c asMail = asMail__c.getValues('asb');
        String subject, toAddr, toCC, PlainTextBody;
        try {
            subject = asMail.subject__c;
            toAddr = asMail.toAddr__c;
            toCC = asMail.toCC__c;
            PlainTextBody = asMail.body__c;
        }
        catch (System.Exception e) {
            subject = 'Abrechnung';
            toAddr = 'kontakt@klosesrockepartner.de';
            toCC = null;
            PlainTextBody =  ' ';
        }
        
        String betreff = 'Abrechnung_' + this.rgName + '_' + this.csvType + '_';
        if(this.beihilfeberechtigt) {
            betreff+= 'Beihilfeberechtigt_' + date.today().format();
        }
        else {
            if(this.privat) {
                betreff+= 'Privat_' + date.today().format();
            }
            else {
                betreff+= 'Gesetzlich_' + date.today().format();
            }
        }
        String attachmentName = betreff + '.csv';
        
        if(this.lineNumber > 0) {
            List<Messaging.Emailfileattachment> attmList = new List<Messaging.Emailfileattachment>();
            Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            csvAttc.setFileName(attachmentName);
            csvAttc.setBody(blob.valueOf(this.csvString));
            attmList.add(csvAttc);
            String[] toAddress =  toAddr.split(','); 
            if(toCC != null) {                  
                String[] toCcAddress =  toCC.split(',');  
                mail.setCcAddresses(toCcAddress);
            }
            mail.setToAddresses(toAddress);
            mail.setSubject(betreff);            
            mail.setFileAttachments(attmList);
            mail.setPlainTextBody(PlainTextBody); 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
            List<invoice__c> ivList = [SELECT id, csv_created__c FROM invoice__c WHERE Name = :  rgName];
            if((ivList != null) && (ivList.size() >0 )) {
                ivList[0].csv_created__c = true;
                update ivList;
            }
        }
        //  Call Privat
        if((!this.privat) && (!this.beihilfeberechtigt)){
            id bid = Database.executeBatch(new batchCreateCsvAsb(this.rgName, true));
        }
        //  Call Beihilfeberechtigt
        else if((this.privat) && (!this.beihilfeberechtigt)) {
            id abid = Database.executeBatch(new batchCreateCsvAsb(this.rgName, false, true));
        }
        system.debug('########### heap size:' + Limits.getHeapSize());
    }
}