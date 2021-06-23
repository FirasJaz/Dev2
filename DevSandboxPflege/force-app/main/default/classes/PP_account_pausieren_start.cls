global class PP_account_pausieren_start implements Schedulable{
    global void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new PP_account_pausieren_batch());
    }
}