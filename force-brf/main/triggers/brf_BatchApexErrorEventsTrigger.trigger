/**
 * Subscribes to BatchApexErrorEvent events
 **/
trigger brf_BatchApexErrorEventsTrigger on BatchApexErrorEvent (after insert) {
    new brf_BatchApexErrorEvents(Trigger.new).handle();    
}