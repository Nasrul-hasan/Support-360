/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class OverdueCaseCSVGeneratorTest {
    @testSetup
    static void setupTestData() {
        // Create Test User (Project Owner)
        User projectOwner = new User(
            FirstName = 'Test',
            LastName = 'Owner',
            Email = 'owner@example.com',
            Username = 'owner@example.com.salesforce',
            Alias = 'towner',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert projectOwner;

        // Create a Test Project
        Project__c testProject = new Project__c(Name = 'Test Project', OwnerId = projectOwner.Id);
        insert testProject;

        // Create Overdue Cases
        List<Case> testCases = new List<Case>{
            new Case(
                Subject = 'Test Overdue Case',
                Status = 'To Do',
                Priority = 'High',
                Due_Date__c = Date.today().addDays(-5), // Overdue
                Project__c = testProject.Id
            ),
            new Case(
                Subject = 'Another Overdue Case',
                Status = 'In Progress',
                Priority = 'Medium',
                Due_Date__c = Date.today().addDays(-3), // Overdue
                Project__c = testProject.Id
            )
        };
        insert testCases;
    }

    @isTest
    static void testGenerateCSVForOverdueCases() {
        Test.startTest();
        OverdueCaseCSVGenerator.generateCSVForOverdueCases(new List<String>{});
        Test.stopTest();

        // Verify that a ContentVersion was created
        List<ContentVersion> files = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];
        System.assertEquals(1, files.size(), 'A CSV file should have been created.');
        System.assert(files[0].Title.contains('Overdue_Cases'), 'CSV file should have correct title.');

        // Verify that TWO ContentDocumentLink records exist (one for user, one for project)
        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :files[0].ContentDocumentId
        ];
        System.assertEquals(2, links.size(), 'File should be linked to both the project and the owner.');
    }

    @isTest
    static void testNoOverdueCases() {
        Test.startTest();
        // Delete existing cases to simulate no overdue cases
        delete [SELECT Id FROM Case];
        OverdueCaseCSVGenerator.generateCSVForOverdueCases(new List<String>{});
        Test.stopTest();

        // Verify no ContentVersion was created
        List<ContentVersion> files = [SELECT Id FROM ContentVersion];
        System.assertEquals(0, files.size(), 'No CSV file should be created if there are no overdue cases.');
    }

    @isTest
    static void testHandleContentVersionInsertFailure() {
        Boolean exceptionThrown = false;

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {  
            try {
                // Try inserting an invalid ContentVersion to force failure
                ContentVersion invalidFile = new ContentVersion(
                    Title = '', // Title is required
                    PathOnClient = '', // Path is required
                    VersionData = Blob.valueOf(''), // Blob cannot be empty
                    IsMajorVersion = true
                );
                insert invalidFile; // This should throw a DMLException
            } catch (DmlException e) {
                exceptionThrown = true;
                System.debug('Caught expected DML Exception: ' + e.getMessage());
            }
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'DML exception should have been caught and handled.');
    }
    
}