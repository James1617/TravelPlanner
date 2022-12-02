public with sharing class PdfEmailerController {
    
    // Campos desde el formulario, que se pasarán como parametros
    public Id selectedAccount    { get; set; }  // Account selected on Visualforce page
    public String selectedReport { get; set; }  // Report selected
    public String recipientEmail { get; set; }  // Send to this email
    
    
    public void PdfEmailerController (Id contractSelected){
        
                Contract contract = [SELECT Name, AccountId, CompanySignedId, CompanySignedDate, CurrencyIsoCode,
                                     StartDate, ContractTerm, CustomerSignedId, CustomerSignedDate, CustomerSignedTitle
                           FROM Contract 
                           WHERE Id = :contractSelected];
        
    }
    
    // Método para el botón
    public PageReference sendReport() {
        if(String.isBlank(this.selectedAccount) || String.isBlank(this.recipientEmail)) {
            ApexPages.addMessage(new 
                ApexPages.Message(ApexPages.Severity.ERROR, 
               'Hay errores. Corregir y reeviar'));
            return null;
        }
        
        // Obtener el nombre de la cuenta para los mensajes
        Account account = [SELECT Name 
                           FROM Account 
                           WHERE Id = :this.selectedAccount 
                           LIMIT 1];
        if(null == account) {
            ApexPages.addMessage(new 
                ApexPages.Message(ApexPages.Severity.ERROR, 
               'Cuenta inválida. Corregir y reenviar.'));
            return null; // early out
        }
        
        // Crear correo
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(new String[]{ this.recipientEmail });
        message.setSubject('Account summary for ' + account.Name);
        message.setHtmlBody('Here\'s a summary for the ' + account.Name + ' account.');
        
        // Crear PDF
        PageReference reportPage = 
            (PageReference)this.reportPagesIndex.get(this.selectedReport);
        reportPage.getParameters().put('id', this.selectedAccount);
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
        attachment.setFileName('AccountSummary-' + account.Name + '.pdf');
        attachment.setInline(false);
        attachment.setBody(reportPdf);
        message.setFileAttachments(new Messaging.EmailFileAttachment[]{ attachment });
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ message });
        
        ApexPages.addMessage(new 
            ApexPages.Message(ApexPages.Severity.INFO,
           'Correo enviado con el adjunto a: ' + this.recipientEmail));

        return null;
    }
    
    
    /***** Helpers para los formularios *****/
    
    // 10 cuentas más recientes
    public List<SelectOption> recentAccounts {
        get {
            if(null == recentAccounts){
                recentAccounts = new List<SelectOption>();
                for(Account acct : [SELECT Id,Name,LastModifiedDate 
                                    FROM Account 
                                    ORDER BY LastModifiedDate DESC 
                                    LIMIT 10]) {
                    recentAccounts.add(new SelectOption(acct.Id, acct.Name));
                }
            }
            return recentAccounts;
        }
        set;
    }
    
    // Lista de reportes disponibles
    public List<SelectOption> reportFormats {
        get {
            if(null == reportFormats) {
                reportFormats = new List<SelectOption>();
                for(Map <String,Object> report : reports) {
                    reportFormats.add(new SelectOption(
                        (String)report.get('name'), (String)report.get('label')));
                }
            }
            return reportFormats;
        }
        set;
    }

    
    /***** Helpers Privados *****/
    
    private Map<String,PageReference> reportPagesIndex;
    private List<Map<String,Object>> reports {
        get {
            if(null == reports) {
                reports = new List<Map<String,Object>>();
                // Se agrega un reporte por defecto, para que siempre haya uno mínimo
                Map<String,Object> simpleReport = new Map<String,Object>();
                simpleReport.put('name',  'simple');
                simpleReport.put('label', 'Simple');
                simpleReport.put('page',   Page.ReportAccountSimple);
                reports.add(simpleReport);
                
                // Se pueden agregar más

                // Index the page names for the reports
                this.reportPagesIndex = new Map<String,PageReference>();
                for(Map<String,Object> report : reports) {
                    this.reportPagesIndex.put(
                        (String)report.get('name'), (PageReference)report.get('page'));
                }
            }
            return reports;
        }
        set;
    }
}