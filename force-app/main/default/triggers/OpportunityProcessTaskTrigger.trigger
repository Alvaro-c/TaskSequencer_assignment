trigger OpportunityProcessTaskTrigger on OpportunityProcessTask__c(after update, before delete) {
    OpportunityProcessTaskTriggerHandler.run(Trigger.operationType);
}
