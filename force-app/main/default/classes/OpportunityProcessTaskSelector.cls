/**
 * @description Selector class for the object OpportunityProcessTask__c
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */
public with sharing class OpportunityProcessTaskSelector {
    public static OpportunityProcessTask__c[] getTasksByOpportunityIds(Id[] ids) {
        return [
            SELECT Id, SequentialOrder__c, Opportunity__c
            FROM OpportunityProcessTask__c
            WHERE Opportunity__c IN :ids
            WITH SECURITY_ENFORCED
            ORDER BY SequentialOrder__c ASC
        ];
    }
}
