global class email_verschicken_start implements Schedulable{
    global void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new email_verschicken_batch());
    }
}