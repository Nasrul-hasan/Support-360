public class SendEmailWithAttachment {
    @InvocableMethod
    public static void sendEmail(List<EmailRequest> emailRequests) {
        for (EmailRequest req : emailRequests) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{req.recipientEmail});
            mail.setSubject(req.emailSubject);
            mail.setPlainTextBody(req.emailBody);

            // Retrieve the file from Salesforce Files (ContentDocument)
            if (req.fileId != null) {
                ContentVersion file = [SELECT VersionData, Title FROM ContentVersion WHERE ContentDocumentId = :req.fileId LIMIT 1];
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(file.Title + '.csv');
                attachment.setBody(file.VersionData);
                mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});
            }

            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }
    }

    public class EmailRequest {
        @InvocableVariable(required=true)
        public String recipientEmail;
        
        @InvocableVariable(required=true)
        public String emailSubject;
        
        @InvocableVariable(required=true)
        public String emailBody;
        
        @InvocableVariable
        public String fileId;
    }
}