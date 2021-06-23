//****************************************************************************************************************************
// Created 24.01.2017      by MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04023882986
//                         Fax.:  04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// opportunity record type
//
//****************************************************************************************************************************
//
// Description:
//                      
// The programm generates the email body based on record type
// responsible for making the decisions that are dependant on opportunity record type
//
//
//****************************************************************************************************************************
//Changes:
//  07.03.2017  MZ  add the notification line
//  07.06.2018	MZ	Badumbau added
//  27.09.2018	MZ	#160167197 Badumbau - two other phone fields added
//****************************************************************************************************************************
public class plzPartnerEmailBodyGenerator{
    
    private String ProductTile = 'Anfrage-Details';
    private String recordType;
    plzEmailTagsGenerator tagGenerator = new plzEmailTagsGenerator();
    
    public Boolean notificationEmail = False;
    
    // set to PLZTool_Hausnotruf.direktVertriebKey or PLZTool_Hausnotruf.weiterleitungKey or PLZTool_Hausnotruf.exklusivKey for Hausnotruf recordType
    public String PLZ_Tool_Liste = ''; 

    public plzPartnerEmailBodyGenerator(String rt){
        recordType = rt;
    }
    
    public void setPlzToolListe(String PLZToolListe){
        if( recordType == PLZTool_Basis.rtHausnotruf )
            PLZ_Tool_Liste = PLZToolListe;
    }
    
    public String prepareEmailbody(Id opportunityId, String htmlValue, Contact contactPerson, Contact insuredPerson, Id individualEmailId){
        String notificationLine =  '';
        if(notificationEmail){
            notificationLine = '<p style="color:red;font-weight:bold">Achtung: Es handelt sich um eine Anpassung einer bereits verschickten Email !</p>';
        }
        String customerTag = '<br/> Ansprechpartner <br/>';
        customerTag  += tagGenerator.generateCustomerTag(contactPerson, individualEmailId);
        if( recordType == PLZTool_Basis.rtPflegeimmobilien && individualEmailId == null){
            ProductTile = 'Inhaltliche Angaben';
            customerTag += tagGenerator.addExtraField_PI(contactPerson.Id);
        }
        if( recordType == PLZTool_Basis.rtBadumbau && individualEmailId == null){
            customerTag += tagGenerator.addExtraField_Badumbau(contactPerson.Id);
        }
        customerTag += tagGenerator.closeCustomerTable();
        
        if(insuredPerson.Id != contactPerson.Id){
            customerTag += '<br/> Pflegebedürftiger <br/>';
            customerTag += tagGenerator.generateCustomerTag(insuredPerson, individualEmailId);
            if( recordType == PLZTool_Basis.rtTreppenlift  )
                ProductTile = 'Interessent';
            if( recordType == PLZTool_Basis.rtBetreuungsleistungen && individualEmailId == null)
                customerTag += tagGenerator.addExtraField_BEL(insuredPerson.Id);
            if( recordType == PLZTool_Basis.rtHausnotruf && individualEmailId == null){
                ProductTile = 'Anfrage-Details';                
                customerTag += tagGenerator.addExtraField_HNR(insuredPerson.Id);
            }
            customerTag += tagGenerator.closeCustomerTable();
        }
        if( recordType == PLZTool_Basis.rtWiderspruch && individualEmailId == null){
             ProductTile = ' ';
        }
        
        String htmlValuePerPartner = htmlValue.replace('<table id="tblNotification"/>', notificationLine );
        
        htmlValuePerPartner = htmlValuePerPartner.replace('<Comment:extra>', getExtraComment() ); 
            
        htmlValuePerPartner = htmlValuePerPartner.replace('<table id="tblCustomer"/>', customerTag ); 

        htmlValuePerPartner = htmlValuePerPartner.replace('<p id="product_title"/>', ProductTile);
        
        htmlValuePerPartner = htmlValuePerPartner.replace('<table id="tblOpportunity"/>', generateOpportunityTag(opportunityId, individualEmailId));
                
        return htmlValuePerPartner;
    }
    
    private String getExtraComment(){
        if(recordType == PLZTool_Basis.rtHausnotruf && 
           (PLZ_Tool_Liste == PLZTool_Hausnotruf.direktVertriebKey ||
            PLZ_Tool_Liste == PLZTool_Hausnotruf.exklusivKey )){
                return '';
            }
        return 'Bitte kontaktieren Sie den Interessenten unter folgenden Kontaktdaten:';
        
    }

    private String generateOpportunityTag(Id opportunityId, Id individualEmailId){
        if(individualEmailId != null){
            return tagGenerator.generateOpportunityIndividualTag(opportunityId, individualEmailId);
        }
        if(recordType == PLZTool_Basis.rtTreppenlift ){
            return tagGenerator.generateOpportunity_TL(opportunityId);
        }
        if(recordType == PLZTool_Basis.rtBetreuungsleistungen ){
            return tagGenerator.generateOpportunity_BEL(opportunityId);
        }
        if(recordType == PLZTool_Basis.rtHausnotruf ){
            return tagGenerator.generateOpportunity_HNR(opportunityId, PLZ_Tool_Liste);
        }
        if(recordType == PLZTool_Basis.rtPflegeimmobilien ){
            return tagGenerator.generateOpportunity_PI(opportunityId);
        }  
        if(recordType == PLZTool_Basis.rtBadumbau ){
            return tagGenerator.generateOpportunity_Bad(opportunityId);
        }
        return '';
    }
}