public with sharing class PDFFooterController {
    public CompanyInfo__c FirmenInfo {get; set;}
    
    public PDFFooterController(){
        FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
            
        
        if(FirmenInfo.GF__c.contains(', ')){
            String[] GF = FirmenInfo.GF__c.split(', ',2);
            FirmenInfo.GF__c = GF[0] + '<br />'+GF[1];
        }
        
        }
    }
    
    public CompanyInfo__c getFirmenInfo(){
        return FirmenInfo;
    }
}