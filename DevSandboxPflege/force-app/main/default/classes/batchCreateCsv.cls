public with sharing class batchCreateCsv  implements Database.Batchable<sObject>, Database.Stateful{
    
    public string rgname = null;

    public batchCreateCsv(String rgName) {
        this.rgname = rgname;
    }

    public Database.querylocator start(Database.BatchableContext BC) {
        string query = 'SELECT id FROM account limit 1';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        createInvoiceLines c = new createInvoiceLines();
        c.createCSVfiles(this.rgName); 
    }

    public void finish(Database.BatchableContext BC){
    }

}