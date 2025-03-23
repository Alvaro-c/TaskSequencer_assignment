/**
 * @description Test for the Handler Trigger in OpportunityProcessTask__c Object
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */
@isTest
public with sharing class OpportunityProcessTaskTriggerHandlerTest {
    public static final String PROCESS_NAME = 'Default Customer'; // Restricted by Global Picklist
    public static final String PROCESS_NAME2 = 'Special Customer'; // Restricted by Global Picklist

    @TestSetup
    static void makeData() {
        Process__c proc = TestDataFactory.createProcess(PROCESS_NAME);
        insert proc;

        ProcessTask__c proTas1 = TestDataFactory.createProcessTask('Step1 - Process 1', 1, proc.Id);
        ProcessTask__c proTas2 = TestDataFactory.createProcessTask('Step2 - Process 1', 2, proc.Id);
        insert new List<ProcessTask__c>{ proTas1, proTas2 };

        Opportunity oppy = TestDataFactory.createOpportunity();
        oppy.Process__c = PROCESS_NAME;
        insert oppy;

        OpportunityProcessTask__c[] opt = [SELECT Id FROM OpportunityProcessTask__c];
        System.assertEquals(1, opt.size(), 'Expected one OpportunityProcessTask__c created');
    }

    @isTest
    public static void stepCompletedTest() {
        // Given a OpportunityProcessTask__c
        OpportunityProcessTask__c[] opt = [SELECT Id, Opportunity__c FROM OpportunityProcessTask__c];

        // When the Status changes to Completed
        opt[0].Status__c = 'Completed';
        Test.startTest();
        update opt;
        Test.stopTest();

        // Then, a new step has been created in the relevant opportunity
        OpportunityProcessTask__c[] tasks = [
            SELECT Id, SequentialOrder__c
            FROM OpportunityProcessTask__c
            WHERE Opportunity__c = :opt[0].Opportunity__c
            ORDER BY SequentialOrder__c ASC
        ];
        System.assertEquals(2, tasks.size(), 'Expected two OpportunityProcessTask__c created');

        for (Integer i = 0; i < tasks.size(); i++) {
            System.assertEquals(
                i,
                Integer.valueOf(tasks[i].SequentialOrder__c) - 1,
                'Expected two OpportunityProcessTask__c created in expected order'
            );
        }
    }

    @isTest
    public static void multipleCompletedStepsTest() {
        // Get Opportunity 1
        Opportunity oppy1 = [SELECT Id FROM Opportunity];

        // Given multiple OpportunityProcessTask__c in different stages
        Process__c proc2 = TestDataFactory.createProcess(PROCESS_NAME2);
        insert proc2;

        ProcessTask__c proTas1 = TestDataFactory.createProcessTask('Step1 - Second Process', 1, proc2.Id);
        ProcessTask__c proTas2 = TestDataFactory.createProcessTask('Step2 - Second Process', 2, proc2.Id);
        ProcessTask__c proTas3 = TestDataFactory.createProcessTask('Step3 - Second Process', 3, proc2.Id);
        insert new List<ProcessTask__c>{ proTas1, proTas2, proTas3 };

        Opportunity oppy2 = TestDataFactory.createOpportunity();
        oppy2.Process__c = PROCESS_NAME2;
        insert oppy2;

        // Move second process one step ahead
        OpportunityProcessTask__c opt = getLastStepFromOppy(oppy2.Id);
        opt.Status__c = 'Completed';
        update opt;

        // When multiple OpportunityProcessTask__c are completed
        OpportunityProcessTask__c opt1 = getLastStepFromOppy(oppy1.Id);
        OpportunityProcessTask__c opt2 = getLastStepFromOppy(oppy2.Id);

        opt1.Status__c = 'Completed';
        opt2.Status__c = 'Completed';

        Test.startTest();
        update new List<OpportunityProcessTask__c>{ opt1, opt2 };
        Test.stopTest();

        // Then, each next OpportunityProcessTask__c has been created
        // First Oppy has OpportunityProcessTask__c in step 2
        OpportunityProcessTask__c stepInOppy1 = getLastStepFromOppy(oppy1.Id);
        System.assertEquals(2, stepInOppy1.SequentialOrder__c, 'Expected first Opportunity to be in Second Step');
        // Second Oppy has OpportunityProcessTask__c in step 3
        OpportunityProcessTask__c stepInOppy2 = getLastStepFromOppy(oppy2.Id);
        System.assertEquals(3, stepInOppy2.SequentialOrder__c, 'Expected first Opportunity to be in Third Step');
    }

    @isTest
    public static void lastStepCompletedTest() {
        // Given a Last step in a process
        OpportunityProcessTask__c opt = [SELECT Id, Opportunity__c FROM OpportunityProcessTask__c];
        opt.Status__c = 'Completed';
        update opt;

        // When the last step is completed
        OpportunityProcessTask__c lastOpt = getLastStepFromOppy(opt.Opportunity__c);
        lastOpt.Status__c = 'Completed';
        Test.startTest();
        update opt;
        Test.stopTest();

        // Then, no new task is created
        OpportunityProcessTask__c[] tasks = [SELECT Id FROM OpportunityProcessTask__c WHERE Opportunity__c = :opt.Opportunity__c];
        System.assertEquals(2, tasks.size(), 'Expected two OpportunityProcessTask__c created');
    }

    @isTest
    public static void irrelevantUpdateTest() {
        // Given a OpportunityProcessTask__c
        OpportunityProcessTask__c[] opt = [SELECT Id, Opportunity__c FROM OpportunityProcessTask__c];

        // When updating it but not as Completed
        opt[0].Status__c = 'Failed';
        Test.startTest();
        update opt;
        Test.stopTest();

        // Then, there is still only one OpportunityProcessTask__c
        opt = [SELECT Id, Opportunity__c FROM OpportunityProcessTask__c];
        System.assertEquals(1, opt.size(), 'Expected one OpportunityProcessTask__c');
    }

    @isTest
    public static void beforeDeleteTest() {
        // Given a OpportunityProcessTask__c
        OpportunityProcessTask__c[] opt = [SELECT Id, Opportunity__c FROM OpportunityProcessTask__c];
        System.assertEquals(1, opt.size(), 'Expected one OpportunityProcessTask__c');

        // When deleting the OpportunityProcessTask__c
        Test.startTest();
        delete opt;
        Test.stopTest();

        // Then, no OpportunityProcessTask__c should remain
        opt = [SELECT Id, Opportunity__c FROM OpportunityProcessTask__c];
        System.assertEquals(0, opt.size(), 'Expected no OpportunityProcessTask__c');
    }

    /**
     * @description Returns a the last step of a given opportunity Id
     *
     * @param  procIds List of Project Ids
     * @return Map<String, List<ProcessTask__c>>
     */
    public static OpportunityProcessTask__c getLastStepFromOppy(Id oppyId) {
        return [
            SELECT Id, SequentialOrder__c
            FROM OpportunityProcessTask__c
            WHERE Opportunity__c = :oppyId
            ORDER BY SequentialOrder__c DESC
            LIMIT 1
        ];
    }
}
