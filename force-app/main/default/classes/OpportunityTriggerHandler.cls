/**
 * @description Handler for the Trigger for Opportunity Object
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */
public with sharing class OpportunityTriggerHandler {
    /**
     * @description Method to call the relevant method after trigger is fired
     *
     * @param  triggerOp  Trigger operation
     * @return void
     */
    public static void run(System.TriggerOperation triggerOp) {
        switch on triggerOp {
            when AFTER_INSERT {
                afterInsert(Trigger.newMap);
            }
            when AFTER_UPDATE {
                afterUpdate(Trigger.newMap, Trigger.oldMap);
            }
        }
    }

    /**
     * @description Method called after insert trigger
     *
     * @param  newItems  Trigger variable
     * @return void
     */
    public static void afterInsert(Map<Id, SObject> newItems) {
        Map<Id, Opportunity> newOppies = (Map<Id, Opportunity>) newItems;
        applyProcess(newOppies);
    }

    /**
     * @description Method called after update trigger
     *
     * @param  newItems  Trigger variable
     * @param  oldItems  Trigger variable
     * @return void
     */
    public static void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, Opportunity> newOppies = (Map<Id, Opportunity>) newItems;
        applyProcess(newOppies);
    }

    /**
     * @description Apply a new process to a set of Opportunities creating the first step of every Opportunity's process
     *
     * @param  oppies  Map with Opportunities passed by the Variables trigger
     * @return void
     */
    public static void applyProcess(Map<Id, Opportunity> oppies) {
        // First, get all the processes involved
        Set<String> procSet = new Set<String>();
        for (Opportunity opp : oppies.values()) {
            if (opp.Process__c != null) {
                procSet.add(opp.Process__c); // Get processes by name, as they aren't a Lookup
            }
        }

        if (procSet.isEmpty()) {
            return; // Early return if no process present
        }

        // When an Opportunity is created or updated, only the first step of each process is relevant
        ProcessTask__c[] proTasL = [
            SELECT Id, Process__c, Process__r.ProcessName__c
            FROM ProcessTask__c
            WHERE Process__r.ProcessName__c IN :procSet AND SequentialOrder__c = 1
            WITH SECURITY_ENFORCED
        ];

        if (proTasL.isEmpty()) {
            return; // Early return if no ProcessTask__c exist
        }

        // Create Map with ProcessName => ProcessTask__c.Id (Each process with its first step)
        Map<String, Id> processNameToTaskIdMap = createProcessNameToTaskMap(proTasL);

        // Create collection of OpportunityProcessTask__c for later bulk insertion
        OpportunityProcessTask__c[] oppProTaskL = new List<OpportunityProcessTask__c>{};
        for (Opportunity opp : oppies.values()) {
            if (opp.Process__c == null) {
                continue; // Early return if an Opportunity doesn't have a Process
            }
            // Create junction objects
            OpportunityProcessTask__c opPrTask = new OpportunityProcessTask__c();
            opPrTask.Opportunity__c = opp.Id;
            opPrTask.ProcessTask__c = processNameToTaskIdMap.get(opp.Process__c);
            opPrTask.Status__c = 'Not Started';
            oppProTaskL.add(opPrTask);
        }

        // Bulk insertion of the new steps
        insert oppProTaskL;
    }

    /**
     * @description Creates a Map of Processes with assoviated with the Id of the first task related to that process
     *
     * @param  proTasL  Collection of Process Tasks
     * @return void
     */
    public static Map<String, Id> createProcessNameToTaskMap(ProcessTask__c[] proTasL) {
        Map<String, Id> processNameToTaskIdMap = new Map<String, Id>();
        for (ProcessTask__c proTak : proTasL) {
            if (!processNameToTaskIdMap.containsKey(proTak.Process__r.ProcessName__c)) {
                processNameToTaskIdMap.put(proTak.Process__r.ProcessName__c, proTak.Id);
            } else {
                // This means the process name is duplicated or there are more than one process task with order 1
                // For the first case, it is a opportunity for improvement that would be solved if Process is a lookup reference instead a picklist
                // Then, the match would be done by unique Id instead of possible dublicated name
                // For the second case, there should be a validation for not having more than one step in the same process with same order number
            }
        }
        return processNameToTaskIdMap;
    }
}
