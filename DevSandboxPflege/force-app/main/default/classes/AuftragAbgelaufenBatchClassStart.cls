global class AuftragAbgelaufenBatchClassStart implements Schedulable {
    global void execute(SchedulableContext sc){
            ID batchprocessid = Database.executeBatch(new AuftragAbgelaufenBatchClass());
        }

}