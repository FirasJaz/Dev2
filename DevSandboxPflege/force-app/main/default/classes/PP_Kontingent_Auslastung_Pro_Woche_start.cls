global class PP_Kontingent_Auslastung_Pro_Woche_start implements Schedulable{
    global void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new PP_Kontingent_Auslastung_Pro_Woche_batch());
    }
}