global class reset_Kontingent_Auslastung_start implements Schedulable{
    global void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new reset_Kontingent_Auslastung_batch());
    }
}