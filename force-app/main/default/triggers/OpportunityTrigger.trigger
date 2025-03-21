/**
 * @description Trigger for Opportunity Object
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */
trigger OpportunityTrigger on Opportunity(after insert, after update) {
    OpportunityTriggerHandler.run(Trigger.operationType);
}
