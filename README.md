# force-brf - Batch Retry Framework

Reference lib for [BatchApexErrorEvent](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_batchapexerrorevent.htm) handling. See [blog here](https://developer.salesforce.com/blogs/2019/01/building-a-batch-retry-framework-with-batchapexerrorevent.html) for more details.

In Winter’19 the BatchApexErrorEvent standard platform event was introduced. This event extends the above error reporting facilities with the ability to use Platform Events to listen (subscribe) to all job failures in variety of ways using clicks or code (clicks are not supported in Beta). The fields on the event give rich access to the exception type, stack trace, affected scope (records) and job ID. You can review a full list of the available fields here.

BatchApexErrorEvent. An event record provides more granular error tracking than the Apex Jobs UI. It includes the record IDs being processed, exception type, exception message, and stack trace. You can also incorporate custom handling and retry logic for failures. You can invoke custom Apex logic from any trigger on this type of event, so Apex developers can build functionality like custom logging or automated retry handling.

![image](https://res.cloudinary.com/hzxejch6p/image/upload/c_scale,w_800/v1546556939/image_8_wdhab6.png)

Deploy Setup
------------
Run the following commands to deploy:-

```
sfdx force:source:push
sfdx force:user:permset:assign --permsetname Billing
sfdx force:user:permset:assign --permsetname brf_BatchRetryFramework
```

Data Setup
----------

```
sfdx force:apex:execute
```

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
5. Use the **Orders** tab and **Bad Orders** list view to review bad records and delete one or edit **Order Start Date** to another date
6. Open the **Failed Jobs** utility bar and click **Retry** action on the failed job
7. Click the **Refresh** button to review remaining errors, repeat steps 5-7 until all clear!
