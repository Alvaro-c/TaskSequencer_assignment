trigger OpportunityProcessTaskTrigger on OpportunityProcessTask__c(after update) {
    OpportunityProcessTaskTriggerHandler.run(Trigger.operationType);
}
