public class brf_BatchableErrorTestJob 
    implements Database.Batchable<SObject>, brf_BatchableErrorHandler {

    private List<Account> accounts; 
    private Boolean retryMode = false;

    public brf_BatchableErrorTestJob() { 
        retryMode = true;
    }

    public brf_BatchableErrorTestJob(List<Account> accounts) { 
        this.accounts = accounts;
    }

    public List<Account> start(Database.BatchableContext ctx) {
        return accounts;
    }

    public void execute(Database.BatchableContext ctx, List<Account> scope) {
        try {
            // Query accounts
            Set<Id> accountIds = new Map<Id, Account>(scope).keySet();
            List<Account> accounts = [select Id, Name from Account where id in :accountIds];
            // Throw a test exception?
            if(accounts[0].Name == 'Bad') {
                System.debug('Throwing exception');
                throw new TestJobException('Test exception');
            }
            // Update account if all good
            for(Account account : accounts) {
                account.Name = 'All good';
            }
            update accounts;
        } catch (Exception e) {
            // Retry mode? Then allow the brf_BatchableRetryJob (caller) to catch this error
            if(retryMode) {
                throw e;
            }
            // We emulate BatchApexErrorEvent firing if running in test mode (subject to change once the feature GA's)
            BatchApexErrorEvent event = new BatchApexErrorEvent();
            event.AsyncApexJobId = ctx.getJobId();
            event.DoesExceedJobScopeMaxLength = false;
            event.ExceptionType = brf_BatchableErrorTestJob.TestJobException.class.getName();
            event.JobScope = String.join((Iterable<Id>) new Map<Id, SObject>(scope).keySet(), ',');
            event.Message = e.getMessage();
            event.RequestId = null; // Not currently acccessibe via Apex
            event.StackTrace = e.getStackTraceString();
            EventBus.publish(event);
        }
    }
    
    public void finish(Database.BatchableContext ctx) { }

    public void handleErrors(brf_BatchableError error) { 
        // Provide the test code a means to confirm the errors have been handled
        List<String> accountIds = error.JobScope.split(',');
        List<Account> accounts = [select Id, Name from Account where id in :accountIds];
        for(Account account : accounts) {
            account.Name = 'Handled';
        }
        update accounts;
    }

    public class TestJobException extends Exception { }
}
