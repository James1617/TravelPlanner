public with sharing class PdfEmailerController {
    
    public void PdfEmailerController (Id contractSelected, String emailToSend){
        
                Contract contract = [SELECT Name, AccountId, CompanySignedId, CompanySignedDate,CurrencyIsoCode, StartDate, ContractTerm, CustomerSignedId, CustomerSignedDate,CustomerSignedTitle
                           FROM Contract 
                           WHERE Id = :contractSelected];
        
        		Account account = [SELECT Name
                           FROM Account 
                           WHERE Id = :contract.AccountId];

         // Crear correo
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(new String[]{ emailToSend });
        message.setSubject('Contract of services for ' + account.Name);
        message.setHtmlBody('Here\'s the contract for your signage for the ' + account.Name + ' account.');
        
        // Crear PDF
        String partialURL = '/apex/ReportAccountSimple?id='+ contractSelected;
        PageReference reportPage = new PageReference(partialURL);
        Blob reportPdf;
        try {
            reportPdf = reportPage.getContentAsPDF();
        }
        catch (Exception e) {
            reportPdf = Blob.valueOf(e.getMessage());
        }
        
        // Adjuntar PDF y mandar
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setContentType('application/pdf');
        attachment.setFileName('Contract-' + account.Name + '.pdf');
        attachment.setInline(false);
        attachment.setBody(reportPdf);
        message.setFileAttachments(new Messaging.EmailFileAttachment[]{ attachment });
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ message });
    }
}