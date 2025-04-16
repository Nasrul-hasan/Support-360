/**
 * @description       : Generates a CSV file for the selected Case records and stores it in Salesforce Files
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CaseCSVGenerator {
    @InvocableMethod(label='Generate Case CSV' description='Creates a CSV file and stores it in Salesforce Files')
    public static List<Id> generateCSVFile(List<Id> caseIds) {
        if (caseIds.isEmpty()) return null;
        
        List<Case> caseList = [SELECT CaseNumber, Subject, Status, Due_Date__c, Owner.Name 
                               FROM Case WHERE Id IN :caseIds];
        
        String csvData = 'CaseNumber,Subject,Status,DueDate,OwnerName\n';
        for (Case c : caseList) {
            csvData += '"' + c.CaseNumber + '","' + c.Subject + '","' + c.Status + '","' +
                       c.Due_Date__c + '","' + c.Owner.Name + '"\n';
        }

        // Convert to Blob format
        Blob csvBlob = Blob.valueOf(csvData);

        // Create ContentVersion record (Salesforce Files)
        ContentVersion file = new ContentVersion();
        file.Title = 'Missed_Due_Date_Cases.csv';
        file.PathOnClient = 'Missed_Due_Date_Cases.csv';
        file.VersionData = csvBlob;
        insert file;

        // Retrieve File ID to return to Flow
        ContentVersion insertedFile = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
        return new List<Id>{insertedFile.ContentDocumentId};
    }
}