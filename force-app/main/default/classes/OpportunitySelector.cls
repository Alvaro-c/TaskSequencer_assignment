/**
 * @description Selector class for the object Opportunity
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */
public with sharing class OpportunitySelector {
    public static Opportunity[] getOpportunitiesByIds(Id[] ids) {
        return [
            SELECT Id, Process__c
            FROM Opportunity
            WHERE Id IN :ids
            WITH SECURITY_ENFORCED
        ];
    }
}
