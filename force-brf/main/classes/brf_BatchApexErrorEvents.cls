/**
 * Handles BatchApexErrorEvent events
 **/
public class brf_BatchApexErrorEvents {

    private List<BatchApexErrorEvent> events;

    public brf_BatchApexErrorEvents(List<BatchApexErrorEvent> events) { 
        this.events = events;
    }

    public void handle() {

        // Query associated AsyncApexJobs
        Set<Id> asyncApexJobIds = new Set<Id>();
        for(BatchApexErrorEvent evt : events){
            asyncApexJobIds.add(evt.AsyncApexJobId);
        }    
        // TODO: Use force-di to inject a test JobInfoResolver
        Map<Id, JobInfo> jobs = new RuntimeJobInfoResolver().resolveById(asyncApexJobIds);

        // Construct log records
        Map<Id, brf_BatchApexErrorLog__c> errorLogsById = new Map<Id, brf_BatchApexErrorLog__c>();
        Map<Id, List<brf_BatchApexError__c>> errorsById = new Map<Id, List<brf_BatchApexError__c>>();
        for(BatchApexErrorEvent evt : events){
            Id jobId = evt.AsyncApexJobId;
            JobInfo asyncApexJob = jobs.get(jobId);
            if(asyncApexJob!=null) {
                String apexClassName = asyncApexJob.ApexClassName;
                String jobScope = evt.JobScope;
                // From retry job?
                if(apexClassName == brf_BatchableRetryJob.class.getName()) {
                    // Adjust apex class and scope to reflect the orginal job not the retry job
                    brf_BatchableError retryBatchableError = (brf_BatchableError) JSON.deserialize(jobScope, brf_BatchableError.class);
                    apexClassName = retryBatchableError.ApexClassName;
                    jobScope = retryBatchableError.JobScope;
                }
                // Create Log?
                if(!errorLogsById.containsKey(jobId)) {
                    brf_BatchApexErrorLog__c errorLog = 
                        new brf_BatchApexErrorLog__c(
                            JobId__c = jobId,
                            JobApexClass__c = apexClassName,
                            JobCreatedDate__c = asyncApexJob.CreatedDate);
                    errorLogsById.put(jobId, errorLog);
                    errorsById.put(jobId, new List<brf_BatchApexError__c>());
                }
                // Add Error to Log
                errorsById.get(jobId).add(
                    new brf_BatchApexError__c(
                        AsyncApexJobId__c = jobId,
                        DoesExceedJobScopeMaxLength__c = evt.DoesExceedJobScopeMaxLength,
                        ExceptionType__c = evt.ExceptionType,
                        JobApexClass__c = apexClassName,
                        JobScope__c = jobScope,
                        Message__c = evt.Message,
                        RequestId__c = evt.RequestId,
                        StackTrace__c = evt.StackTrace));
            }
        }

        // Insert log records
        upsert errorLogsById.values() JobId__c;
        List<brf_BatchApexError__c> errors = new List<brf_BatchApexError__c>();
        for(Id jobId : errorLogsById.keySet()) {
            brf_BatchApexErrorLog__c log = errorLogsById.get(jobId);
            for(brf_BatchApexError__c error : errorsById.get(jobId)) {
                error.BatchApexErrorLog__c = log.Id;
                errors.add(error);
            }        
        }
        insert errors;

        // Allow the Batch Apex class a chance to handle the error
        for(brf_BatchApexError__c error : errors) {    
            Type apexJobClassType = Type.forName(error.JobApexClass__c);
            Object apexJob = apexJobClassType.newInstance();
            if(apexJob instanceof brf_BatchableErrorHandler) {
                brf_BatchableErrorHandler handler = (brf_BatchableErrorHandler) apexJob;
                handler.handleErrors(brf_BatchableError.newInstance(error));
            }
        }        
    }

    // Abstract queries made against AsyncApexJob to aid testability
    public abstract class JobInfoResolver {
        public abstract Map<Id, JobInfo> resolveById(Set<Id> jobIds);
    }
    public class RuntimeJobInfoResolver extends JobInfoResolver {
        public override Map<Id, JobInfo> resolveById(Set<Id> jobIds) {            
            Map<Id, JobInfo> jobsById = new Map<Id, JobInfo>();
            for(AsyncApexJob job : [select id, CreatedDate, ApexClass.Name from AsyncApexJob where Id IN :jobIds]) {
                JobInfo jobInfo = new JobInfo();
                jobInfo.Id = job.Id;
                jobInfo.ApexClassName = job.ApexClass.Name;
                jobInfo.CreatedDate = job.CreatedDate;
                jobsById.put(jobInfo.Id, jobInfo);
            }
            // TODO: Inject test impl of resolver via force-di, see handle method
            if(Test.isRunningTest()) {                
                JobInfo jobInfo = new JobInfo();
                jobInfo.Id = '707S000000nKE4fIAG';
                jobInfo.ApexClassName = brf_BatchableErrorTestJob.class.getName();
                jobInfo.CreatedDate = System.today();
                jobsById.put(jobInfo.Id, jobInfo);
            }
            return jobsById;
        }
    }
    public class JobInfo {
        public Id Id;
        public String ApexClassName;
        public DateTime CreatedDate;
    }
}
