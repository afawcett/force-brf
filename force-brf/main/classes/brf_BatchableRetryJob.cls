/**
 * Generic Apex Job for retrying failed scopes/chunks from other Batch Apex jobs
 **/
public class brf_BatchableRetryJob
    implements Database.Batchable<brf_BatchableError>, brf_BatchableErrorHandler
{
    private List<brf_BatchableError> jobScopes;

    public brf_BatchableRetryJob(List<brf_BatchableError> jobScopes) {
        this.jobScopes = jobScopes;
    }

    public brf_BatchableRetryJob() {
        // Retry framework requires default connstructor
    }

    public List<brf_BatchableError> start(Database.BatchableContext ctx) {
        return jobScopes;
    }

    public void execute(Database.BatchableContext ctx, List<brf_BatchableError> scope) {
        try {
            // One batch scope here represents an entire previously failed batch scope
            brf_BatchableError error = scope[0];

            // Construct an SObject scope to pass to the execute method
            // TODO: Support non-SObject scopes
            List<Id> scopeErrorIds = error.JobScope.split(',');
            SObjectType sObjectType = scopeErrorIds[0].getSobjectType();
            List<SObject> retryScope = new List<SObject>();
            for(Id errorId : scopeErrorIds) {
                retryScope.add(sObjectType.newSObject(errorId));
            }

            // Invoke the execute method on the original batch apex job class
            Type apexJobClassType = Type.forName(error.ApexClassName);
            Database.Batchable<SObject> batchJob = (Database.Batchable<SObject>) apexJobClassType.newInstance();
            batchJob.execute(ctx, retryScope);  
        } catch (Exception e) {
            // For now (this is still a beta feature) we emulate BatchApexErrorEvent firing this event if running in test mode
            if(Test.isRunningTest()) {
                BatchApexErrorEvent event = new BatchApexErrorEvent();
                event.AsyncApexJobId = ctx.getJobId();
                event.DoesExceedJobScopeMaxLength = false;
                event.ExceptionType = String.valueOf(e).split(':')[0];
                event.JobScope = scope[0].toString();
                event.Message = e.getMessage();
                event.RequestId = null; // Not currently acccessibe via Apex
                event.StackTrace = e.getStackTraceString();
                EventBus.publish(event);
            } else {
                throw e;
            }
        }
    }
    
    public void finish(Database.BatchableContext ctx) { }

    public void handleErrors(brf_BatchableError error) { }

    /**
     * brf_BatchableRetryJob.run('707Z00000133Hd9IAE');
     **/
    public static Id run(Id retryJobId) {
        // Query log and errors for the job to retry
        List<brf_BatchApexErrorLog__c> errorLogs = 
            [select 
                (select 
                    AsyncApexJobId__c, 
                    BatchApexErrorLog__c,
                    DoesExceedJobScopeMaxLength__c, 
                    ExceptionType__c, 
                    JobApexClass__c,
                    JobScope__c, 
                    Message__c, 
                    RequestId__c, 
                    StackTrace__c 
                    from BatchApexErrors__r) 
                from brf_BatchApexErrorLog__c
                where JobId__c = : retryJobId ];
        // Each scope represents a failed scope to retry
        List<brf_BatchableError> batchableErrors = new List<brf_BatchableError>();
        for(brf_BatchApexError__c error : errorLogs[0].BatchApexErrors__r) {
            batchableErrors.add(brf_BatchableError.newInstance(error));
        }
        // Delete the logs (new ones will be produced if this retry fails again)
        delete errorLogs;
        return Database.executeBatch(new brf_BatchableRetryJob(batchableErrors), 1);
    }

    public class BatchableRetryJobException extends Exception {}
}
