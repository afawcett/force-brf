# force-brf - Batch Retry Framework

Work in progress reference lib for [BatchApexErrorEvent](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_batchapexerrorevent.htm) handling

Deploy Setup
------------
Run the following commands to deploy:-

```
sfdc force:source:push
sfdx force:user:permset:assign --permsetname Billing
sfdx force:user:permset:assign --permsetname brf_BatchRetryFramework
```

Data Setup
----------
Run the following Apex code block to configure test data.

```
delete [select Id from Invoice__c];
delete [select Id from Order];
delete [select Id from Account];
delete [select Id from brf_BatchApexErrorLog__c];
Account orderAccount = new Account();
orderAccount.Name = 'Great customer!';
insert orderAccount;
List<Order> orders = new List<Order>();
for(Integer orderIdx = 0; orderIdx < 1000; orderIdx++) {
    Order order = new Order();
    order.Name = 'Ref:'+orderIdx;
    order.Status = 'Draft';
    order.EffectiveDate = System.today();
    order.AccountId = orderAccount.Id;
    orders.add(order);
}
insert orders;
```

Demo Steps
----------

Perform the following steps to try out the framework with the sample app (included):-

1. Open the **Billing** app
2. Click the **Orders** tab and select the **All** list view
3. Click the **Invoice Generation** button to start the job
4. Open the **Failed Jobs** utlity bar and click **Refresh** button to see logged failures
5. Use the **Orders** tab and **Bad Orders** list view to review bad records and delete one or more
6. Open the **Failed Jobs** utility bar and click **Retry** action on the failed job
7. Click the **Refresh** button to review remaining errors, repeat steps 5-7 until all clear!