global class Lieferungen_ausloesen_jetzt_start implements Schedulable{
    global void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new Lieferungen_ausloesen_jetzt());
    }
}