/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OverdueCaseCSVGenerator {
    @InvocableMethod(label='Generate Overdue Cases CSV' description='Generates CSV files per Project for overdue cases and emails the Project Owner')
    public static void generateCSVForOverdueCases(List<String> input) {
        // Step 1: Get all overdue Cases, grouped by Project
        Map<Id, List<Case>> projectCasesMap = new Map<Id, List<Case>>();
        Map<Id, String> projectOwnerEmails = new Map<Id, String>();

        // Query overdue cases
        List<Case> overdueCases = [
            SELECT Id, CaseNumber, Subject, Status, Priority, Due_Date__c, Project__c, 
                   Project__r.Name, Project__r.Owner.Email  // Fetch Project Owner's Email
            FROM Case
            WHERE Due_Date__c < TODAY AND Status != 'Done'  // Overdue cases
            ORDER BY Project__c
        ];

        if (overdueCases.isEmpty()) {
            return; // No overdue cases, nothing to process
        }

        // Step 2: Group Cases by Project
        for (Case c : overdueCases) {
            if (c.Project__c != null) {
                if (!projectCasesMap.containsKey(c.Project__c)) {
                    projectCasesMap.put(c.Project__c, new List<Case>());
                }
                projectCasesMap.get(c.Project__c).add(c);

                if (c.Project__r != null && c.Project__r.Owner != null && c.Project__r.Owner.Email != null) {
                    projectOwnerEmails.put(c.Project__c, c.Project__r.Owner.Email);
                }
            }
        }

        // Step 3: Generate and store CSV files per Project
        for (Id projectId : projectCasesMap.keySet()) {
            List<Case> casesForProject = projectCasesMap.get(projectId);
            String projectName = casesForProject[0].Project__r != null ? casesForProject[0].Project__r.Name : 'Unknown Project';
            String ownerEmail = projectOwnerEmails.get(projectId);

            // Generate CSV content
            String csvHeader = 'Case Number,Subject,Status,Priority,Due Date,Project Name';
            List<String> csvRows = new List<String>();
            csvRows.add(csvHeader);

            for (Case c : casesForProject) {
                String row = '"' + c.CaseNumber + '",' + 
                             '"' + (c.Subject != null ? c.Subject.replace('"', '\"') : '') + '",' + 
                             '"' + (c.Status != null ? c.Status : '') + '",' + 
                             '"' + (c.Priority != null ? c.Priority : '') + '",' + 
                             '"' + (c.Due_Date__c != null ? c.Due_Date__c.format() : '') + '",' + 
                             '"' + projectName + '"';
                csvRows.add(row);
            }

            String csvContent = String.join(csvRows, '\n');
            Blob csvBlob = Blob.valueOf(csvContent);

            // Step 4: Store CSV file in Salesforce Files (ContentVersion)
            ContentVersion csvFile = new ContentVersion(
                Title = 'Overdue_Cases_' + projectName + '_' + Date.today() + '.csv',
                PathOnClient = 'Overdue_Cases_' + projectName + '_' + Date.today() + '.csv',
                VersionData = csvBlob,
                IsMajorVersion = true
            );

            try {
                insert csvFile;  // Insert CSV file into Salesforce Files
            } catch (DmlException e) {
                System.debug('Error inserting CSV file: ' + e.getMessage());
                continue;  // Skip if CSV file insertion fails
            }

            // Retrieve the ContentDocumentId from the inserted ContentVersion
            Id fileId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :csvFile.Id LIMIT 1].ContentDocumentId;

            // Step 5: Associate the file with the Project so the Owner can access it
            ContentDocumentLink link = new ContentDocumentLink(
                LinkedEntityId = projectId,  // Link to the Project record
                ContentDocumentId = fileId,
                ShareType = 'V'  // Viewer access to the file
            );

            try {
                insert link;  // Link file to the Project
            } catch (DmlException e) {
                System.debug('Error linking file to project: ' + e.getMessage());
            }

            // Step 6: Send email to Project Owner with the CSV attachment
            if (ownerEmail != null) {
                sendEmailToProjectOwner(ownerEmail, fileId, projectId, csvBlob);
            }
        }
    }

    private static void sendEmailToProjectOwner(String ownerEmail, Id fileId, Id projectId, Blob csvBlob) {
        if (String.isEmpty(ownerEmail)) return;
    
        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        String fileUrl = baseUrl + '/lightning/r/ContentDocument/' + fileId + '/view';
        String projectUrl = baseUrl + '/lightning/r/Project__c/' + projectId + '/view';
    
        // Prepare the email message
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ownerEmail});  // Send email to the Project Owner
        mail.setSubject('Overdue Case Report for Your Project');
        mail.setHtmlBody('<html><body><p>Dear Project Owner,</p><p>Attached is the CSV file containing overdue cases for your project.</p>' +
                         '<p><a href="' + fileUrl + '">Download the file</a></p>' +
                         '<p><a href="' + projectUrl + '">View your project details</a></p>' +
                         '<p>Thank you.</p></body></html>');
    
        // Add the CSV file as an attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Overdue_Cases_' + projectId + '_' + Date.today() + '.csv');
        attachment.setBody(csvBlob);
        attachment.setContentType('text/csv');  // Set the content type to CSV
    
        // Attach the file to the email
        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});
        
        // Send the email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }
}