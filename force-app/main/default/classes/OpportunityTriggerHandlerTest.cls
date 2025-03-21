/**
 * @description Test for the Handler Trigger in Opportunity Object
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */
@isTest
public with sharing class OpportunityTriggerHandlerTest {
    public static final String PROCESS_NAME = 'Default Customer'; // Restricted by Global Picklist
    public static final String PROCESS_NAME2 = 'Special Customer'; // Restricted by Global Picklist

    @TestSetup
    static void makeData() {
        Process__c proc = TestDataFactory.createProcess(PROCESS_NAME);
        insert proc;

        ProcessTask__c proTas1 = TestDataFactory.createProcessTask('Step1', 1, proc.Id);
        ProcessTask__c proTas2 = TestDataFactory.createProcessTask('Step2', 2, proc.Id);
        insert new List<ProcessTask__c>{ proTas1, proTas2 };

        Opportunity oppy = TestDataFactory.createOpportunity();
        insert oppy;
    }

    @isTest
    public static void afterInsertTest() {
        // Given an Opportunity with a Process
        Opportunity oppy = TestDataFactory.createOpportunity();
        oppy.Process__c = PROCESS_NAME;

        // When the Opportunity is inserted
        Test.startTest();
        insert oppy;
        Test.stopTest();

        // Then, the opportunity has one OpportunityProcessTask__c and it's the first step of the process
        OpportunityProcessTask__c[] oppProcTask = [
            SELECT Id, StepName__c, Status__c
            FROM OpportunityProcessTask__c
            WHERE Opportunity__c = :oppy.Id
        ];
        System.assertEquals(1, oppProcTask.size(), 'Expected one OpportunityProcessTask__c');
        System.assertEquals('Step1', oppProcTask[0].StepName__c, 'Expected the OpportunityProcessTask__c to be the first step');
    }

    @isTest
    public static void afterInsertBulkTest() {
        // Given multiple Processes, Steps and Opportunities
        Process__c proc2 = TestDataFactory.createProcess(PROCESS_NAME2);
        insert proc2;

        ProcessTask__c proTas1 = TestDataFactory.createProcessTask('Step1 - Process 2', 1, proc2.Id);
        ProcessTask__c proTas2 = TestDataFactory.createProcessTask('Step2 - Process 2', 2, proc2.Id);
        insert new List<ProcessTask__c>{ proTas1, proTas2 };

        Opportunity oppy = TestDataFactory.createOpportunity();
        oppy.Process__c = PROCESS_NAME;

        Opportunity oppy2 = TestDataFactory.createOpportunity();
        oppy2.Process__c = PROCESS_NAME2;

        Opportunity[] oppL = new List<Opportunity>{ oppy, oppy2 };

        // When the Opportunity is inserted
        Test.startTest();
        insert oppL;
        Test.stopTest();

        // Then, each Opportunity has their OpportunityProcessTask__c and it's the first step of the process
        OpportunityProcessTask__c[] oppProcTask = [
            SELECT Id, StepName__c, Status__c
            FROM OpportunityProcessTask__c
            WHERE Opportunity__c = :oppL[0].Id
        ];
        System.assertEquals(1, oppProcTask.size(), 'Expected one OpportunityProcessTask__c');
        System.assertEquals('Step1', oppProcTask[0].StepName__c, 'Expected the OpportunityProcessTask__c to be the first step');

        OpportunityProcessTask__c[] oppProcTask2 = [
            SELECT Id, StepName__c, Status__c
            FROM OpportunityProcessTask__c
            WHERE Opportunity__c = :oppL[1].Id
        ];
        System.assertEquals(1, oppProcTask2.size(), 'Expected one OpportunityProcessTask__c');
        System.assertEquals(
            'Step1 - Process 2',
            oppProcTask2[0].StepName__c,
            'Expected the OpportunityProcessTask__c to be the first step'
        );
    }

    @isTest
    public static void afterUpdateTest() {
        // Given an Opportunity
        Opportunity oppy = [SELECT Id FROM Opportunity LIMIT 1];

        // When the Status of the opportunity is updated
        oppy.Process__c = PROCESS_NAME;
        Test.startTest();
        update oppy;
        Test.stopTest();

        // Then, the opportunity has one OpportunityProcessTask__c and it's the first step of the process
        OpportunityProcessTask__c[] oppProcTask = [
            SELECT Id, StepName__c, Status__c
            FROM OpportunityProcessTask__c
            WHERE Opportunity__c = :oppy.Id
        ];
        System.assertEquals(1, oppProcTask.size(), 'Expected one OpportunityProcessTask__c');
        System.assertEquals('Step1', oppProcTask[0].StepName__c, 'Expected the OpportunityProcessTask__c to be the first step');
    }

    @isTest
    public static void afterUpdateBulkTest() {
        // Given multiple processes and steps
        Process__c proc2 = TestDataFactory.createProcess(PROCESS_NAME2);
        insert proc2;

        ProcessTask__c proTas1 = TestDataFactory.createProcessTask('Step1 - Process 2', 1, proc2.Id);
        ProcessTask__c proTas2 = TestDataFactory.createProcessTask('Step2 - Process 2', 2, proc2.Id);
        insert new List<ProcessTask__c>{ proTas1, proTas2 };

        Opportunity oppy = TestDataFactory.createOpportunity();
        insert oppy;

        Opportunity[] oppyL = [SELECT Id FROM Opportunity];
        System.assertEquals(2, oppyL.size(), 'Expected two Opportunities');

        // When the Status of the opportunities are updated
        oppyL[0].Process__c = PROCESS_NAME;
        oppyL[1].Process__c = PROCESS_NAME2;
        Test.startTest();
        update oppyL;
        Test.stopTest();

        // Then, each Opportunity has their OpportunityProcessTask__c and it's the first step of the process
        OpportunityProcessTask__c[] oppProcTask = [
            SELECT Id, StepName__c, Status__c
            FROM OpportunityProcessTask__c
            WHERE Opportunity__c = :oppyL[0].Id
        ];
        System.assertEquals(1, oppProcTask.size(), 'Expected one OpportunityProcessTask__c');
        System.assertEquals('Step1', oppProcTask[0].StepName__c, 'Expected the OpportunityProcessTask__c to be the first step');

        OpportunityProcessTask__c[] oppProcTask2 = [
            SELECT Id, StepName__c, Status__c
            FROM OpportunityProcessTask__c
            WHERE Opportunity__c = :oppyL[1].Id
        ];
        System.assertEquals(1, oppProcTask2.size(), 'Expected one OpportunityProcessTask__c');
        System.assertEquals(
            'Step1 - Process 2',
            oppProcTask2[0].StepName__c,
            'Expected the OpportunityProcessTask__c to be the first step'
        );
    }
}
