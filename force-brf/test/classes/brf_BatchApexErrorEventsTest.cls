@IsTest
private class brf_BatchApexErrorEventsTest {

    @IsTest
    private static void whenJobExceptionThenLogGeneratedAndHandlerCalled() {

        // Given
        Account testAccount = new Account(Name = 'Bad');
        insert testAccount;
        List<Account> testRecords = new List<Account> { testAccount };
        brf_BatchableErrorTestJob job = new brf_BatchableErrorTestJob(testRecords);

        // When
        Test.startTest();
        Id jobId = Database.executeBatch(job);
        try { Test.stopTest(); }
        catch(Exception ex) { /* don't fail this test if there were errors in the batch job - we want that */ }
        Test.getEventBus().deliver();

        // Then (failures captured)
        System.assertEquals(1, [select id from brf_BatchApexErrorLog__c].size());
        System.assertEquals('Test exception', [select Message__c from brf_BatchApexError__c][0].Message__c);
        System.assertEquals('Handled', [select Id, Name from Account where Id = :testAccount.Id].Name);
    }

    @IsTest
    private static void whenFailedJobLogThenRetrySuccessful() {

        // Given
        Account testAccount = new Account(Name = 'Good');
        insert testAccount;
        Id testJobId = '707S000000nKE4fIAG';
        brf_BatchApexErrorLog__c testJob = new brf_BatchApexErrorLog__c();
        testJob.JobApexClass__c = brf_BatchableErrorTestJob.class.getName();
        testJob.JobCreatedDate__c = System.today();
        testJob.JobId__c = testJobId;
        insert testJob;
        brf_BatchApexError__c testError = new brf_BatchApexError__c();
        testError.AsyncApexJobId__c = testJobId;
        testError.BatchApexErrorLog__c = testJob.Id;
        testError.DoesExceedJobScopeMaxLength__c = false;
        testError.ExceptionType__c = brf_BatchableErrorTestJob.TestJobException.class.getName();
        testError.JobApexClass__c = brf_BatchableErrorTestJob.class.getName();
        testError.JobScope__c = testAccount.Id;
        testError.Message__c = 'Test exception';
        testError.RequestId__c = null;
        testError.StackTrace__c = '';
        insert testError;

        // When
        Test.startTest();
        brf_BatchableRetryJob.run(testJobId);
        try { Test.stopTest(); }
        catch(Exception ex) { /* don't fail this test if there were errors in the batch job - we want that */ }
        Test.getEventBus().deliver();

        // Then (retry successful)
        System.assertEquals(0, [select id from brf_BatchApexErrorLog__c].size());
        System.assertEquals('All good', [select Id, Name from Account where Id = :testAccount.Id].Name);        
    }

    @IsTest
    private static void whenFailedJobLogThenRetryFailed() {

        // Given
        Id testJobId = '707S000000nKE4fIAG';
        Account testAccount = new Account(Name = 'Bad');
        insert testAccount;
        brf_BatchApexErrorLog__c testJob = new brf_BatchApexErrorLog__c();
        testJob.JobApexClass__c = brf_BatchableErrorTestJob.class.getName();
        testJob.JobCreatedDate__c = System.today();
        testJob.JobId__c = testJobId;
        insert testJob;
        brf_BatchApexError__c testError = new brf_BatchApexError__c();
        testError.AsyncApexJobId__c = testJobId;
        testError.BatchApexErrorLog__c = testJob.Id;
        testError.DoesExceedJobScopeMaxLength__c = false;
        testError.ExceptionType__c = brf_BatchableErrorTestJob.TestJobException.class.getName();
        testError.JobApexClass__c = brf_BatchableErrorTestJob.class.getName();
        testError.JobScope__c = testAccount.Id;
        testError.Message__c = 'Test exception';
        testError.RequestId__c = null;
        testError.StackTrace__c = '';
        insert testError;

        // When
        Test.startTest();
        brf_BatchableRetryJob.run(testJobId);
        try { Test.stopTest(); }
        catch(Exception ex) { /* don't fail this test if there were errors in the batch job - we want that */ }
        Test.getEventBus().deliver();

        // Then (retry failed)
        System.assertEquals(1, [select id from brf_BatchApexErrorLog__c].size());
        System.assertEquals('Test exception', [select Message__c from brf_BatchApexError__c][0].Message__c);
        System.assertEquals('Handled', [select Id, Name from Account where Id = :testAccount.Id].Name);
    }
}
