global class PP_Kontingent_Auslastung_Pro_Monat_start implements Schedulable{
    global void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new PP_Kontingent_Auslastung_Pro_Monat_batch());
    }
}