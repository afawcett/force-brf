/**
 * Controller queries for failed jobs and allows component to start retry jobs
 **/
public with sharing class brf_BatchableErrorsComponentController {

    @AuraEnabled
    public static List<brf_BatchApexErrorLog__c> failedJobs(){
        return [select JobApexClass__c, JobCreatedDate__c, JobErrors__c, JobId__c from brf_BatchApexErrorLog__c order by JobCreatedDate__c desc];
    }

    @AuraEnabled
    public static List<brf_BatchApexErrorLog__c> retryJob(Id retryJobId){
        brf_BatchableRetryJob.run(retryJobId);      
        return failedJobs();
    }
}
