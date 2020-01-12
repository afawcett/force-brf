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
