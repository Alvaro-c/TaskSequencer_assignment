/**
 * @description Class to create objects for the tests classes
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */
@isTest
public with sharing class TestDataFactory {
    public static Process__c createProcess(String name) {
        Process__c proc = new Process__c();
        proc.ProcessName__c = name; // Restricted by Global Picklist
        return proc;
    }

    public static ProcessTask__c createProcessTask(String name, Integer order, Id proId) {
        ProcessTask__c proTas = new ProcessTask__c();
        proTas.Name = name;
        proTas.SequentialOrder__c = order;
        proTas.Process__c = proId;
        return proTas;
    }

    public static Opportunity createOpportunity() {
        Opportunity oppy = new Opportunity();
        oppy.Name = 'Test Opportunity';
        oppy.StageName = 'Prospecting';
        oppy.CloseDate = Date.today().addDays(30);
        return oppy;
    }
}
