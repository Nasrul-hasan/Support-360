/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ProjectDashboardController {
    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getCaseStatusCounts(String projectName) {
        return [
            SELECT Status, COUNT(Id) totalCases
            FROM Case
            WHERE Project__r.Name = :projectName
            GROUP BY Status
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Resource__c> getResourceUtilization(String projectName) {
        return [
            SELECT Name, Allocation_Percentage__c
            FROM Resource__c
            WHERE Project__r.Name = :projectName
            ORDER BY Name ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects() {
        return [SELECT Name FROM Project__c ORDER BY Name ASC];
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getProjectProgress(String projectName) {
        List<Project__c> projectList = [SELECT Progress__c FROM Project__c WHERE Name = :projectName LIMIT 1];
        return (projectList.isEmpty()) ? 0 : projectList[0].Progress__c;
    }
}