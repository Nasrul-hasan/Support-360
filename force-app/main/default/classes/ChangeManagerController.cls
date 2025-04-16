/**
 * @description       : 
 * @author            : mailto:changemein@usersettingsunder.sfdoc
 * @group             : 
 * @last modified on  : 02-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ChangeManagerController {
    public List<Project__c> selectedProjects { get; set; }
    public List<SelectOption> managerOptions { get; set; }
    public Id selectedManagerId { get; set; }

    public ChangeManagerController(ApexPages.StandardSetController controller) {
        List<Project__c> selectedRecords = (List<Project__c>) controller.getSelected();
        List<Id> selectedIds = new List<Id>();
        
        for (Project__c proj : selectedRecords) {
            selectedIds.add(proj.Id);
        }
        
        
        // If no records are selected, show message on the list view page and prevent modal from opening
        if (selectedIds.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No projects selected. Please select at least one project.'));
            return;
        }

        selectedProjects = [SELECT Id, Name, Manager__c  FROM Project__c WHERE Id IN :selectedIds];
        managerOptions = new List<SelectOption>();
        loadManagers();
    }

    public void loadManagers() {
        Id loggedInUserId = UserInfo.getUserId();
        List<User> managers = [
            SELECT Id, Name 
            FROM User 
            WHERE UserRole.Name = 'Manager' 
            AND Id != :loggedInUserId
        ];

        if (managers.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No managers found.'));
            return;
        }

        for (User manager : managers) {
            managerOptions.add(new SelectOption(manager.Id, manager.Name));
        }
    }

    public PageReference updateManager() {
        if (selectedProjects == null || selectedProjects.isEmpty() || selectedManagerId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select projects and a manager.'));
            return null;
        }

        // Check if the selected manager is already assigned
        for (Project__c project : selectedProjects) {
            if (project.Manager__c == selectedManagerId) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected manager is already assigned to one or more projects.'));
                return null;
            }
        }

        // Update project manager
        for (Project__c project : selectedProjects) {
            project.Manager__c = selectedManagerId;
            project.OwnerId = selectedManagerId; // also update OwnerId

        }
        update selectedProjects;

        // Send notification email
        List<User> newManagerList = [SELECT Email FROM User WHERE Id = :selectedManagerId LIMIT 1];

        if (!newManagerList.isEmpty() && newManagerList[0].Email != null) {
            List<String> projectLinks = new List<String>();
            for (Project__c project : selectedProjects) {
                projectLinks.add('<a href="/' + project.Id + '">' + project.Name + '</a>');
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ newManagerList[0].Email });
            mail.setSubject('Project Manager Assignment');
            mail.setHtmlBody('<p>You have been assigned as a manager for the following projects:</p>'
                + '<ul>' + String.join(projectLinks, '') + '</ul>'
                + '<p>Please review them in Salesforce.</p>');
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        }

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Project managers updated successfully.'));
        return null;
    }
}