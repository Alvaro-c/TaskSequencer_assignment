/**
 * @description Script to create dummy entries. This scripts relays on the deployment of the full metadata in the project
 *
 * @author  Alvaro Canas
 * @version 0.1
 * @since   21.03.2025
 */

Process__c proc1 = new Process__c();
proc1.ProcessName__c = 'Default Customer'; // Restricted by Global Picklist
Process__c proc2 = new Process__c();
proc2.ProcessName__c = 'Special Customer'; // Restricted by Global Picklist
insert new List<Process__c>{ proc1, proc2 };

ProcessTask__c[] tasks = new List<ProcessTask__c>{};
ProcessTask__c proc1Task1 = new ProcessTask__c();
proc1Task1.Name = 'First Meeting';
proc1Task1.SequentialOrder__c = 1;
proc1Task1.Process__c = proc1.Id;
tasks.add(proc1Task1);

ProcessTask__c proc1Task2 = new ProcessTask__c();
proc1Task2.Name = 'Second Meeting';
proc1Task2.SequentialOrder__c = 2;
proc1Task2.Process__c = proc1.Id;
tasks.add(proc1Task2);

ProcessTask__c proc1Task3 = new ProcessTask__c();
proc1Task3.Name = 'Final Meeting';
proc1Task3.SequentialOrder__c = 3;
proc1Task3.Process__c = proc1.Id;
tasks.add(proc1Task3);

ProcessTask__c proc2Task1 = new ProcessTask__c();
proc2Task1.Name = 'First F2F Meeting';
proc2Task1.SequentialOrder__c = 1;
proc2Task1.Process__c = proc2.Id;
tasks.add(proc2Task1);

ProcessTask__c proc2Task2 = new ProcessTask__c();
proc2Task2.Name = 'Second F2F Meeting';
proc2Task2.SequentialOrder__c = 2;
proc2Task2.Process__c = proc2.Id;
tasks.add(proc2Task2);

ProcessTask__c proc2Task3 = new ProcessTask__c();
proc2Task3.Name = 'Final F2F Meeting';
proc2Task3.SequentialOrder__c = 3;
proc2Task3.Process__c = proc2.Id;
tasks.add(proc2Task3);
insert tasks;

Opportunity oppy = new Opportunity();
oppy.Name = 'Test Opportunity';
oppy.StageName = 'Prospecting';
oppy.CloseDate = Date.today().addDays(30);
insert oppy;
