/**
 * Example job demonstrating the batch apex retry framework
 **/
public class InvoiceGenerationJob 
    implements Database.Batchable<SObject>, brf_BatchableErrorHandler
{
    public List<Order> start(Database.BatchableContext ctx) {
        return [select Id from Order 
                where EffectiveDate = THIS_WEEK and Invoiced__c != true
                order by Name];
    }

    public void execute(Database.BatchableContext ctx, List<SObject> scope) {
        // Invoice generation from given orders
        Set<Id> orderIds = new Map<Id, SObject>(scope).keySet();
        List<Invoice__c> invoices = new List<Invoice__c>();
        List<Order> orders = 
            [select Id, TotalAmount, Name from Order 
                where Id in :orderIds and Invoiced__c != true];
        for(Order order : orders) {
            produceSomeExceptions(order.Name);
            Invoice__c invoice = new Invoice__c();
            invoice.DueDate__c = System.today().addDays(30);
            invoice.Paid__c = false;
            invoice.Order__c = order.Id;
            invoice.Amount__c = order.TotalAmount;
            invoices.add(invoice);
            order.Invoiced__c = true;
        }
        insert invoices;
        update orders;
    }
    
    public void finish(Database.BatchableContext ctx) { }

    public void handleErrors(brf_BatchableError error) {
        // Update the effected orders with the error for further review
        List<String> orderIds = error.JobScope.split(',');
        List<Order> orders = [select Id from Order where Id in :orderIds];
        for(Order order : orders) {
            order.InvoiceGenerationError__c = error.Id;
        }
        update orders; 
    }

    // Produce some exceptions, some catchable, some not...
    private void produceSomeExceptions(String orderName) {
        switch on orderName {
           when 'Ref:100' {
               // Standard exception
               throw new InvoiceGenerationException('Order Ref:100 is invalid.');
           }
           when 'Ref:300' {
               // Divide by zero!
               Integer newAmount = 20 / 0;
           }
           when 'Ref:500' {
                // Limits exception
                for(Integer idx=0; idx<201; idx++) {
                    Order order = [select Id from Order limit 1];
                }
           }
        }
    }

    /**
     * InvoiceGenerationJob.run();
     **/
    public static Id run() {
        // Chunk size of 200 forces 5 batches given the sample data used in this example
        return Database.executeBatch(new InvoiceGenerationJob(), 200);
    }

    public class InvoiceGenerationException extends Exception {} 
}
