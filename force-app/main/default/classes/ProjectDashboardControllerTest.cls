/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class ProjectDashboardControllerTest {
    
    @isTest
static void testGetCaseStatusCounts() {
    // Create test data
    Project__c project = new Project__c(Name = 'Test Project');
    insert project;

    Case case1 = new Case(Status = 'Open', Project__c = project.Id);
    Case case2 = new Case(Status = 'Closed', Project__c = project.Id);
    Case case3 = new Case(Status = 'Open', Project__c = project.Id);
    insert new List<Case>{ case1, case2, case3 };

    // Start the test context to reset governor limits
    Test.startTest();
    
    // Test method call
    List<AggregateResult> result = ProjectDashboardController.getCaseStatusCounts('Test Project');
    
    // End the test context here
    Test.stopTest();

    // Assert results
    System.assertNotEquals(0, result.size(), 'Result should not be empty');
    
    // Ensure the "Open" status is present and has the correct count
    Boolean openStatusFound = false;
    Integer openCount = 0;
    for (AggregateResult res : result) {
        String status = (String) res.get('Status');
        Integer count = (Integer) res.get('totalCases');
        
        if (status == 'Open') {
            openStatusFound = true;
            openCount = count;
        }
    }
    
    System.assert(openStatusFound, 'Status Open should be found');
    System.assertEquals(2, openCount, 'Total cases for Open status should be 2');
}

    

    @isTest
    static void testGetResourceUtilization() {
        // Create test data
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;
        
        Resource__c resource1 = new Resource__c(Name = 'Resource 1', Allocation_Percentage__c = 75, Project__c = project.Id);
        Resource__c resource2 = new Resource__c(Name = 'Resource 2', Allocation_Percentage__c = 50, Project__c = project.Id);
        insert new List<Resource__c>{ resource1, resource2 };

        // Test method
        Test.startTest();
        List<Resource__c> result = ProjectDashboardController.getResourceUtilization('Test Project');
        Test.stopTest();

        // Assert results
        System.assertNotEquals(0, result.size(), 'Result should not be empty');
        System.assertEquals('Resource 1', result[0].Name, 'First resource should be Resource 1');
        System.assertEquals(75, result[0].Allocation_Percentage__c, 'Resource 1 should have 75% allocation');
    }

    @isTest
    static void testGetProjects() {
        // Create test data
        Project__c project1 = new Project__c(Name = 'Project A');
        Project__c project2 = new Project__c(Name = 'Project B');
        insert new List<Project__c>{ project1, project2 };

        // Test method
        Test.startTest();
        List<Project__c> result = ProjectDashboardController.getProjects();
        Test.stopTest();

        // Assert results
        System.assertNotEquals(0, result.size(), 'Result should not be empty');
        System.assertEquals('Project A', result[0].Name, 'First project should be Project A');
    }

    @isTest
    static void testGetProjectProgress() {
        // Create test data
        Project__c project = new Project__c(Name = 'Test Project', Progress__c = 85.5);
        insert project;

        // Test method
        Test.startTest();
        Decimal progress = ProjectDashboardController.getProjectProgress('Test Project');
        Test.stopTest();

        // Assert results
        System.assertEquals(85.5, progress, 'Project progress should be 85.5');
    }
}