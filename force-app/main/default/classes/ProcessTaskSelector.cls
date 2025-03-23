/**
 * @description Selector class for the object ProcessTask__c
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */
public with sharing class ProcessTaskSelector {
    public static ProcessTask__c[] getProcessTasksByProcessIds(Id[] processIds) {
        return [
            SELECT Id, Process__r.ProcessName__c, SequentialOrder__c
            FROM ProcessTask__c
            WHERE Process__c IN :processIds
            WITH SECURITY_ENFORCED
            ORDER BY SequentialOrder__c ASC
        ];
    }
}
