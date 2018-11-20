({
    handleRowAction : function(cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'view_details':
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({"recordId": row.Id});
                navEvt.fire();
                break;
            case 'retry':
                var action = cmp.get("c.retryJob");
                action.setParams({ retryJobId : row.JobId__c });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        cmp.set('v.failedJobs', response.getReturnValue());
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({ "type":"success", "message": "Job retry for " + row.JobApexClass__c + " has been submitted."});
                        resultsToast.fire();
                    }
                    else if (state === "INCOMPLETE") {
                    }
                    else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " + errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                    }
                });
                $A.enqueueAction(action);    
                break;
        }        
    },
    doInit : function(cmp, event, helper) {
        var actions = [
            { label: 'Retry', name: 'retry' }
        ];
        // Configure data table component columns
        cmp.set('v.columns', [
            { label: 'Job Apex Class', fieldName: 'JobApexClass__c', type: 'text'},
            { label: 'Job Creation Date', fieldName: 'JobCreatedDate__c', type: 'date'},
            { label: 'Job Errors', fieldName: 'JobErrors__c', type: 'number'},
            { label: 'View', type: 'button', initialWidth: 135, typeAttributes: { label: 'View Details', name: 'view_details', title: 'Click to View Details'}},
            { type: 'action', typeAttributes: { rowActions: actions } }
        ]);        

        // Retrieve failed jobs from server
        var action = cmp.get("c.failedJobs");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.failedJobs', response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})
