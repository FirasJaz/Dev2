public class ls_xml_create implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    public Database.querylocator start(Database.BatchableContext BC) {
        string query = '';
        set<id> pSet = new set<id>(); 
        list<attachment> atlist = [select parentid from attachment where name like '%.XML' 
                                           and createddate = LAST_N_DAYS:5 limit 50000];
        if((atlist != null) && (atlist.size() >0 )) {
            
            for(attachment a : atlist) {
                pSet.add(a.parentid);
            }
        }
        set<id> lbSet = new set<id>(); 
        list<Lieferbest_tigung__c> lbList = [SELECT Lieferschein__c FROM Lieferbest_tigung__c WHERE createddate = LAST_N_DAYS:5 LIMIT 50000];   
        if((lbList != null) && (lbList.size() >0 )) {           
            for(Lieferbest_tigung__c lb : lbList) {
                lbSet.add(lb.Lieferschein__c);
            }
        }

        query = 'SELECT id from Lieferschein__c where lieferdatum__c = LAST_N_DAYS:5 and lieferdatum__c <= TODAY and id not in :pSet and id in :lbSet';       
        if (Test.IsRunningTest()) {
            query += ' LIMIT 1';
        }
     
        return Database.getQueryLocator(query);   
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Lieferschein__c> lsList = (List<Lieferschein__c>)scope;
        LS_XML_nachbearbeiten_batch nbXML = new LS_XML_nachbearbeiten_batch();
        set<id> lsIdOhneXmlSet = new set<id>();
        for(Lieferschein__c ls : lsList) {
            lsIdOhneXmlSet.add(ls.id);
        }
        nbXML.setlsIdOhneXmlSet(lsIdOhneXmlSet);
        try {
            nbXML.create_xml();
        }
        catch(System.exception e) {}
    }

    public void finish(Database.BatchableContext BC) {}
    
    public void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new ls_xml_create());
    }

}