/****************************************************************************************************************************
// Created 19.08.2020 von  AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frankenstr. 29
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: CSV-Datei als String (UTF-8), datum von, datum bis
//
//****************************************************************************************************************************
//
// Description:       
//  Upload die Reduzieren-Mengen als CSV
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class uploadCB6Reduzieren_Batch implements Database.Batchable<string>, Database.Stateful {
    public final blob dataDocuments;
    public boolean colHdg = true;
    public map<integer, string> prIdMap = new map<integer, string>();
    public map<string, integer> alt_prIdMap = new map<string, integer>();
    public map<string, integer> neu_prIdMap = new map<string, integer>();
    public integer such_schluessel = null;
    public date von = date.today();
    public date bis = date.newInstance(4000, 12, 31);
    public id CuraboxID = null;
    public String curaboxName = 'CB6 - Flexibel';
    public String returnMessage = null;

    public uploadCB6Reduzieren_Batch() {
        List<attachment> atList = [SELECT id, body
                                    FROM attachment 
                                    WHERE ParentId IN (select id from liefermengeReduzierung__c where CuraboxName__c = 'All Files')
                                    ORDER BY createddate DESC LIMIT 1];
        if((atList != null) && (atList.size() > 0) ) {
            this.dataDocuments=atList[0].body;
        }
        this.CuraboxID = [SELECT id FROM Curabox__c WHERE Name = :curaboxName LIMIT 1].id;

    }

    public iterable<string> start(Database.BatchableContext BC) {
        string nameFile=this.dataDocuments.toString();      
        return new CSVIterator(this.dataDocuments.toString(), '\r\n');
    }

    public void execute(Database.BatchableContext BC, List<String> scope) {
        List<LiefermengeReduzierung__c> lmrList = new List<LiefermengeReduzierung__c>();
        for(string line : scope) {
            line = line.replace(';', ',');
            string[] csvline = line.split(',');
            if(colHdg) {
                String idPrefix = Product__c.sobjecttype.getDescribe().getKeyPrefix();
                integer index = 0;
                for(string fVal : csvline) {
                    if((fVal.startsWith(idPrefix)) || (index == 0)) {
                        if(index == 0) {
                            string ffVal = EncodingUtil.urlEncode(fVal, 'UTF-8');
                            system.debug('##### ffVal=' + ffVal);
                            id tId = id.valueOf(ffVal.replace('%EF%BB%BF', ''));
                            fVal = string.valueOf(tId);
                        }
                        if(fVal.contains('_Alt')) {
                            alt_prIdMap.put(fVal, index);
                        }
                        else if(fVal.contains('_Neu')) {
                            neu_prIdMap.put(fVal, index);
                        }
                        else {
                            prIdMap.put(index, fVal);
                        }           
                    }
                    else {
                        such_schluessel = index;
                    }
                    index++;
                }
                // Anzahl ID, _Alt und _Neu Spalten muss identisch sein
                if((alt_prIdMap.size() != prIdMap.size()) || (neu_prIdMap.size() != prIdMap.size())) {
                    this.returnMessage = 'Anzahl Spalten falsch';
                    // return true;
                    // Anzahl Spalten 
                }
                // Für jeder productId-Spalte eine _Alt und eine _Neu  
                for(String fVal : prIdMap.values()) {
                    if(!alt_prIdMap.containsKey(fVal + '_Alt')) {
                        this.returnMessage = 'Für die Spalte ' + fVal + ' gibt es keine ' + fVal + '_Alt';
                        // return true;
                    }
                    if(!neu_prIdMap.containsKey(fVal + '_Neu')) {
                        this.returnMessage = 'Für die Spalte ' + fVal + ' gibt es keine ' + fVal + '_Neu';
                        // return true;
                    }
                }
            }
            else {
                // Bauen MD5key
                String MD5key = makeMD5Key(this.curaboxName, csvline, prIdMap);
                // Erstellen Satz pro Produkt
                for(integer i : prIdMap.keySet()) {
                    LiefermengeReduzierung__c lmr = new LiefermengeReduzierung__c();
                    lmr.Product__c = id.valueOf(prIdMap.get(i));
                    lmr.CuraboxName__c = 'CB6 - Flexibel';
                    lmr.Menge__c = decimal.valueOf(csvline[i]);
                    lmr.key__c = MD5key;
                    lmr.Liefermenge_alt__c = decimal.valueOf(csvline[alt_prIdMap.get(prIdMap.get(i) + '_Alt')]);
                    lmr.Liefermenge_neu__c = decimal.valueOf(csvline[neu_prIdMap.get(prIdMap.get(i) + '_Neu')]);
                    lmr.valid_from__c = von;
                    lmr.valid_to__c = bis;
                    lmr.curabox__c = CuraboxID;
                    lmr.Suchschluessel__c = csvline[such_schluessel];
                    lmrList.add(lmr);
                    if(lmrList.size() == 1000) {
                        boolean ok = saveRecordes(lmrList, von, bis);
                        lmrList.clear();
                    }
                }               
            }   
            colHdg = false;
        }
        boolean ok = saveRecordes(lmrList, von, bis);
    }

    public void finish(Database.BatchableContext BC) { 

    }

    public static String makeMD5Key(String curaboxName, String[] csvline, map<integer, string> prIdMap) {
        String MD5key = null;
        List<string> idList = new List<String>();
        for(integer i : prIdMap.keySet()) {
            // Die "0" Mengen werden ignoriert
            if(csvline[i] != '0') {
                idList.add(prIdMap.get(i) + csvline[i]);
            }
        }
        idList.sort();
        String sKey = curaboxName + String.join(idList, '');  
        system.debug(LoggingLevel.ERROR, '##### s ' + sKey);
        MD5key = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(sKey)));
        system.debug(LoggingLevel.ERROR, '##### k ' + MD5key );
        return MD5key;
    }


     public static String[] splitToRows(String inpString) {
        String[] outTable; 
        if(inpString.contains('\r\n')){
            outTable = inpString.split('\r\n');               
        }
        else if(inpString.contains('\r') && !inpString.contains('\n')){
            outTable = inpString.split('\r');
        }
        else if(inpString.contains('\n') && !inpString.contains('\r')){
            outTable = inpString.split('\n');
        }  
        return outTable;
    }

    public static boolean saveRecordes(List<LiefermengeReduzierung__c> lmrList, date von, date bis) {
        date oldBis = von.addDays(-1);
        Set<string> md5Set = new set<string>();
        // Alte sätze beenden
        for(LiefermengeReduzierung__c lmr : lmrList) {
            md5Set.add(lmr.key__c);
        }
        if(!md5Set.isEmpty()) {
            List<LiefermengeReduzierung__c> lmr2update = [SELECT id, valid_to__c FROM LiefermengeReduzierung__c WHERE key__c IN : md5Set];
            if((lmr2update != null) && (lmr2update.size() > 0)) {
                for(LiefermengeReduzierung__c lmr : lmr2update) {
                    lmr.valid_to__c = oldBis;
                }
                Database.SaveResult[] updateResult = Database.update(lmr2update, false);
            }
        }
        // Insert neue Sätze
        Database.SaveResult[] insertResult = Database.insert(lmrList, false);
        for (Database.SaveResult r : insertResult) {
            if (!r.isSuccess()) {
                for (Database.Error e : r.getErrors()) {
                    system.debug('#### '+ e.getMessage());
                }
            }
        }
        return true;
    }

    

}