global class inko_zusatzinformation_start implements Schedulable{
    global void execute(SchedulableContext sc){
         ID batchprocessid = Database.executeBatch(new inko_zusatzinformation());
    }
}