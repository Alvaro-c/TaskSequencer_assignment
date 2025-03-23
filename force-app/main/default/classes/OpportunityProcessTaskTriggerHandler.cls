/**
 * @description Handler for the Trigger for OpportunityProcessTask__c Object
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */
public with sharing class OpportunityProcessTaskTriggerHandler {
    /**
     * @description Call the relevant operation after trigger is fired
     *
     * @param  triggerOp  Trigger operation
     * @return void
     */
    public static void run(System.TriggerOperation triggerOp) {
        switch on triggerOp {
            when AFTER_UPDATE {
                afterUpdate(Trigger.newMap, Trigger.oldMap);
            }
            when BEFORE_DELETE {
                beforeDelete(Trigger.oldMap);
            }
        }
    }

    /**
     * @description Called after update trigger
     *
     * @param  newItems  Trigger variable
     * @param  oldItems  Trigger variable
     * @return void
     */
    public static void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, OpportunityProcessTask__c> newSteps = (Map<Id, OpportunityProcessTask__c>) newItems;
        afterStepCompletion(newSteps);
    }

    /**
     * @description Create the next step of a Process for given Opportunities. It uses maps to work with bulk operations
     *
     * @param  newSteps  Trigger variable parsed to the objects Id, OpportunityProcessTask__c
     * @return void
     */
    public static void afterStepCompletion(Map<Id, OpportunityProcessTask__c> newSteps) {
        // Pick only 'Completed' OpportunityProcessTask__c
        Map<Id, OpportunityProcessTask__c> completedTasks = getCompletedOpportunityProcessStep(newSteps);
        if (completedTasks.isEmpty()) {
            return; // Early return if no relevant steps
        }

        // Get Parent Opportunities
        Opportunity[] oppis = getOpportunities(completedTasks);

        // Get Parent Processes
        Id[] procIds = new List<Id>{};
        for (OpportunityProcessTask__c step : completedTasks.values()) {
            procIds.add(step.Process__c);
        }

        // Create a Map Process => List<ProcessTask__c>
        Map<String, List<ProcessTask__c>> processNameToTasksMap = getProcessAndStepsMap(procIds);

        // Create a Map with Opportunity => Last OpportunityProcessTask__c (The one with higher SequentialOrder__c)
        Map<Id, Integer> oppyToStepsMap = createOppyToCurrentStepMap(oppis);

        // Create next step for each oppy
        OpportunityProcessTask__c[] oppProTaskL = createNextSteps(oppis, processNameToTasksMap, oppyToStepsMap);

        if (oppProTaskL.isEmpty()) {
            return;
        }

        insert oppProTaskL;
    }

    /**
     * @description Gets only OpportunityProcessTask__c with status 'Completed'
     *
     * @param  newSteps  Trigger variable parsed to the objects Id, OpportunityProcessTask__c
     * @return void
     */
    public static Map<Id, OpportunityProcessTask__c> getCompletedOpportunityProcessStep(
        Map<Id, OpportunityProcessTask__c> newSteps
    ) {
        Map<Id, OpportunityProcessTask__c> completedTasks = new Map<Id, OpportunityProcessTask__c>();
        for (OpportunityProcessTask__c opTask : newSteps.values()) {
            if (opTask.Status__c == 'Completed') {
                // Assumption: Once a task is Completed, it cannot be edited
                // Therefore, the value 'Completed' will only be in the after update once
                completedTasks.put(opTask.Id, opTask);
            }
        }
        return completedTasks;
    }

    /**
     * @description Gets Parent Opportunities of given OpportunityProcessTask__c
     *
     * @param  completedTasks Map Id, OpportunityProcessTask__c
     * @return Opportunity List
     */
    public static Opportunity[] getOpportunities(Map<Id, OpportunityProcessTask__c> completedTasks) {
        Id[] oppysIds = new List<Id>{};
        for (OpportunityProcessTask__c step : completedTasks.values()) {
            oppysIds.add(step.Opportunity__c);
        }
        oppysIds = new List<Id>(new Set<Id>(oppysIds)); // Remove duplicates

        return OpportunitySelector.getOpportunitiesByIds(oppysIds);
    }

    /**
     * @description Given a lisrt of Opportunities, finds the last OpportunityProcessTask__c associated with them
     * and returns a map of Opportunity => Value of the higher SequentialOrder__c associated
     *
     * @param  oppys Opportunity List
     * @return Map<Id, Integer>
     */
    public static Map<Id, Integer> createOppyToCurrentStepMap(Opportunity[] oppys) {
        Id[] oppysIds = new List<Id>(new Map<Id, Opportunity>(oppys).keySet());
        Map<Id, Integer> oppyToStepsMap = new Map<Id, Integer>();
        OpportunityProcessTask__c[] oppProcTasks = OpportunityProcessTaskSelector.getTasksByOpportunityIds(oppysIds);
        for (OpportunityProcessTask__c optask : oppProcTasks) {
            // The list of step is in incremental order, only the higher value will remain in the map, as it overwrites unique values
            oppyToStepsMap.put(optask.Opportunity__c, Integer.valueOf(optask.SequentialOrder__c));
        }
        return oppyToStepsMap;
    }

    /**
     * @description Returns a Map of Projects names and their associated tasks
     *
     * @param  procIds List of Project Ids
     * @return Map<String, List<ProcessTask__c>>
     */
    public static Map<String, List<ProcessTask__c>> getProcessAndStepsMap(Id[] procIds) {
        ProcessTask__c[] processTasks = ProcessTaskSelector.getProcessTasksByProcessIds(procIds);
        Map<String, List<ProcessTask__c>> processNameToTasksMap = new Map<String, List<ProcessTask__c>>();
        for (ProcessTask__c pt : processTasks) {
            if (processNameToTasksMap.containsKey(pt.Process__r.ProcessName__c)) {
                processNameToTasksMap.get(pt.Process__r.ProcessName__c).add(pt);
            } else {
                processNameToTasksMap.put(pt.Process__r.ProcessName__c, new List<ProcessTask__c>{ pt });
            }
        }
        return processNameToTasksMap;
    }

    /**
     * @description Returns a List of next OpportunityProcessTask__c for Opportunities
     *
     * @param  oppis List of Opportunities
     * @param  processNameToTasksMap Map of Projects by name and their assocaited tasks
     * @param  oppyToStepsMap Map of Opportunities and their last OpportunityProcessTask__c associated
     * @return OpportunityProcessTask__c[]
     */
    public static OpportunityProcessTask__c[] createNextSteps(
        Opportunity[] oppis,
        Map<String, List<ProcessTask__c>> processNameToTasksMap,
        Map<Id, Integer> oppyToStepsMap
    ) {
        OpportunityProcessTask__c[] oppProTaskL = new List<OpportunityProcessTask__c>{}; // Steps to be inserted
        Map<Id, Opportunity> oppyMap = new Map<Id, Opportunity>(oppis);

        // For every Opportunity
        for (Opportunity oppy : oppyMap.values()) {
            // Get the next step for the Opportunity.Process__c
            Id nextStep = getNextStep(processNameToTasksMap.get(oppy.Process__c), oppyToStepsMap, oppy.Id);
            if (nextStep == null) {
                continue;
            }
            // Create the next step and and add it to the collection
            OpportunityProcessTask__c opPrTask = new OpportunityProcessTask__c();
            opPrTask.Opportunity__c = oppy.Id;
            opPrTask.ProcessTask__c = nextStep;
            opPrTask.Status__c = 'Not Started';
            oppProTaskL.add(opPrTask);
        }
        return oppProTaskL;
    }

    /**
     * @description Returns the next step of a Process for an Opportunity
     *
     * @param  processTasks ProcessTask__c from a specific Process
     * @param  oppyToStepsMap Map of Id Opportunities and the higher SequentialOrder__c of tasks related
     * @param  oppyId Current OpportunityId
     * @return Id of the next ProcessTask__c in the sequence, or null if none is found
     */
    public static Id getNextStep(ProcessTask__c[] processTasks, Map<Id, Integer> oppyToStepsMap, Id oppyId) {
        for (ProcessTask__c pt : processTasks) {
            if (pt.SequentialOrder__c == oppyToStepsMap.get(oppyId) + 1) {
                return pt.Id;
            }
        }
        // Return null if no result, for example, missing step, or last step
        return null;
    }

    /**
     * @description Called before delete trigger
     *
     * @param  newItems  Trigger variable
     * @param  oldItems  Trigger variable
     * @return void
     */
    public static void beforeDelete(Map<Id, SObject> oldItems) {
        preventRecreation();
    }

    /**
     * @description When one OpportunityProcessTask__c is deleted, prevents the creation of a new one, due to Roll Up Opportunity update
     *
     * @return void
     */
    public static void preventRecreation() {
        RecursiveCheck.recursiveOpportunityTrigger = true;
    }
}
