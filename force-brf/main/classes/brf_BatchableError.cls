/**
 * Represents an error that occured processing a given chunk of items from a Batch Apex job
 *   See https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_batchapexerrorevent.htm
 **/
public class brf_BatchableError {
    
    public String ApexClassName;
    public Id Id;
    public Id AsyncApexJobId;
    public boolean DoesExceedJobScopeMaxLength;
    public String ExceptionType;
    public String JobScope;
    public String Message;
    public String RequestId;
    public String StackTrace;

    /**
     * Decomposes a persisted batch error into a BatchableError
     **/
    public static brf_BatchableError newInstance(brf_BatchApexError__c error) {
        brf_BatchableError newError = new brf_BatchableError();
        newError.ApexClassName = error.JobApexClass__c;
        newError.Id = error.Id;
        newError.AsyncApexJobId = error.AsyncApexJobId__c;
        newError.DoesExceedJobScopeMaxLength = error.DoesExceedJobScopeMaxLength__c;
        newError.ExceptionType = error.ExceptionType__c;
        newError.JobScope = error.JobScope__c;
        newError.Message = error.Message__c;
        newError.RequestId = error.RequestId__c;
        newError.StackTrace =error.StackTrace__c;
        return newError;
    }

    /**
     * BatchableErrors are used by the BatchableRetryJob which implements RaisesPlatformEvents.
     *   If errors occur during retry (execute method) this ensures this state is 
     *   passed on (via the JobScope field on BatchApexErrorEvent) so that the another retry can occur.
     **/      
    public override String toString() {
        return JSON.serialize(this, true);
    }
}
