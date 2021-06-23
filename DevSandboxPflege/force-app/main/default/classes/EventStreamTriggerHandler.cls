public class EventStreamTriggerHandler {

    /**
    * Function, which includes all the code,
    * we execute on the after insert event
    *
   * @param newMap Map with the new values of the event -> Trigger.newMap context variable
    *
   */
  public static void handleAfterInsert(Map<Id, EventStream__c> newMap)
  {
      sendEventToMC(newMap.values());
  }

  /**
    * Fires the entry event in MC that initiates the journey
    * @param events new events list
  */
  private static void sendEventToMC (List<EventStream__c> events){
   List< EventStream__c> eventStreams = new List<EventStream__c>();
   List <String> eventStreamsAsString = new List<String>();
   for( EventStream__c eventStream : events){

    if(eventStream.EventType__c=='Instant'){
        eventStreamsAsString.add(JSON.serialize(eventStream));
    }
   }

   if(!eventStreamsAsString.isEmpty()){
           EventStreamService.callout(eventStreamsAsString);
       }


  }
    
}