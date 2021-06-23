global class shippingcode_pruefen_start implements Schedulable{
    global void execute(SchedulableContext sc){
        ID batchprocessid = Database.executeBatch(new shippingcode_pruefen());
    }
}