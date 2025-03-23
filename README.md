# Enpal - Task Sequencer

### Instructions

To log into an Org with the code deployed and working, please use the following credentials:

URL: [https://orgfarm-1312fc3125-dev-ed.develop.my.salesforce.com](https://orgfarm-1312fc3125-dev-ed.develop.my.salesforce.com/)

username: [enpal@enpal.com](mailto:enpal@enpal.com)

password: TaskSequencer2025

To work with a new org, please, deploy all the metadata included in the project and run as Anonymous apex the content of the class :

`CreateDummyData.cls`

### Instructions for the user

Please use the App “Sales”.

This feature uses the following objects and features:

- Picklist Value Sets
- Opportunity (Opportunity)
- Process (Process\_\_c)
- ProcessStep (ProcessStep\_\_c)
- Opportunity Process Step (OpportunityProcessStep\_\_c)

1st. To add a process, the name of the new Process has to be added to the Picklist Value Set “Processes”. To do that, go to Settings and then Picklist Value Sets:

![Picklist Value Set](https://i.postimg.cc/nhFdPCVM/image.png)

2nd. Now, a Process (Process\_\_c) can be added, go to Processes tab and add one entry. The name will be restricted to the names present in the Picklist from first step.

![Processes](https://i.postimg.cc/xdq69hz2/image.png)

3rd. Process Steps can be added inside a Process. The easiest way to do that, is on the Related tab of the Process Record Page

![Process Tasks](https://i.postimg.cc/XvhQqLfy/image.png)

4 Now that a Process and its steps are ready, we can assign it to an Opportunity.

Go to the tab Opportunities and update the value “Process”. Note that the Process is a Picklist restricted to the options of the Picklist of the step 1

Once a Process is assigned, the first related Opportunity Process Step will be added in the Related list (visible in Related tab, or on the right hand side).

Once a Opportunity Process Step is set as completed, the next Step will be created.

![Opportunity](https://i.postimg.cc/6qV0HNDd/image.png)

To change the Process of the Opportunity, the related Opportunity Process Steps should be deleted first.

Overview of the requirements, architecture and overall approach followed for this task:

### Requirements

1. Opportunity has a picklist to select a Process.
2. Processes have different tasks to be performed in sequential order.
3. Workflow:
    1. A process is selected in Opportunity.
    2. The first task of the process is created in the opportunity.
    3. When the task is completed, the next task is created.
4. Admins should be able to modify Processes and Tasks with no code modifications.

### Architecture

1. There are Opportunities (Default object).
2. There are Processes (Custom object).
3. One Opportunity has one Process. One Process has many Opportunities. (but it’s not a foreign key, just a picklist, by requirements).
4. Processes can be assigned to Opportunities with a picklist in Opportunity.
5. There are ProcessTasks (Custom object). One ProcessTask is related to one Process. One Process has many ProcessTask related to it.
6. ProcessTasks are sequencial and one at a time.
7. When a Process gets assigned to an Opportunity, the first ProcessTask is created in the Opportunity (MasterDetail: OpportunityProcessTask).
8. When a OpportunityProcessTask is completed, the next ProcessTask in the sequence is created.
9. Process can only be modified if no OpportunityProcessTask is present, (Assumption: Or it’s status is Not Started).
10. Admins should be able to create, modify, delete Processes and ProcessTask.

### Implementation

This is a list of the actions performed during the development of the tasks in chronological order

- [x] Create a Global Picklist Value Set “Processes” to hold the names of the Processes available
- [x] Create Opportunity.Process\_\_c picklist using the Global Picklist “Processes”
- [x] Create Process\_\_c Object
    - [x] Name: Autonumber
    - [x] ProcessName: (Restricted to values in the same picklist as Opportunity.Process\_\_c picklist )
- [x] Create ProcessTask**c with Master Detail relation to Process**c
    - [x] Name
    - [x] Process\_\_c (Foreign key)
    - [x] SequentialOrder\_\_c (Number)
- [x] Create Junction Object OpportunityProcessTask**c (N:M) Master Detail from TaskProcess**c to Opportunity
    - [x] Master Detail to Opportunity
    - [x] Lookup to ProcessTask
    - [x] Status\_\_c (Restricted picklist with values ‘Not Started', 'In Progress', 'Completed', 'Failed’)
- [x] Create trigger on Opportunity
    - [x] After insert, After update: If field Process\_\_c has been assigned:
        - [x] Create relevant OpportunityProcessTask\_\_c
- [x] Create trigger on OpportunityProcessTask\_\_c
    - [x] After update: Create next step in the process
- [x] Block Opportunity.Process**c once there is an OpportunityProcessTask**c
    - [x] Create Roll Up summary
    - [x] Create Validation rule referencing Roll up summary
    - [x] Consider recursive trigger execution
- [x] Write apex classes
- [x] Script to create Dummy data

### Assumptions

- OpportunityProcessTask\_\_c will not be modified or deleted after completion

### Improvements

- Opportunity.Process**c should be a LookUp to Process**c instead of a picklist
- Block the modification and deletion of OpportunityProcessTask\_\_c in progress
- Add “Active” Checkbox to Process\_\_c, for better management
- Validations should be added to avoid having ProcessTask**c with same SequentialOrder**c within same Process\_\_c
- Better UX could be achieved if the related list of an Opportunity refreshed itself after completion of a Step, instead of manually refreshing

### Test Results

![Tests](https://i.postimg.cc/gc3Ncvnn/image.png)

Note: AgentforceHomepageController.cls is an example class and is not part of the project
