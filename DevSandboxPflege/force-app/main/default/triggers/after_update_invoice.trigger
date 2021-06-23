trigger after_update_invoice on Invoice__c (after update) {
    List<String> createCsvList = new List<String>(); 
    for (Invoice__c iv : Trigger.new) {
        if(iv.asb_pdf_created__c == true && trigger.OldMap.get(iv.id).asb_pdf_created__c == false) {
            createCsvList.add(iv.name);
        }
    }

    if(!createCsvList.isEmpty()) {

        for(string rgName : createCsvList) {
            id batchid = Database.executeBatch(new batchCreateCsvAsb(rgName));
        }
    }
}