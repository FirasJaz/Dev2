//////////////////////////////////////////////////////////////////////////////////////////////
//
//      erstellt am 31.07.2017 Feld Liefertag füllen (aus genehmigt_ab)
//
///////////////////////////////////////////////////////////////////////////////////////////////
trigger before_insert_Auftrag on Auftrag__c (before insert) {
    for (Auftrag__c a : Trigger.new) {
        if(a.genehmigt_ab__c != null) {
            a.Liefertag__c = decimal.valueOf(a.genehmigt_ab__c.day());
        }
        else {
            a.Liefertag__c = date.today().day();
        }
    }
}