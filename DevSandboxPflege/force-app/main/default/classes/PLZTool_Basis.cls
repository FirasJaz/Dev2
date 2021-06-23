/********************************************************************************************************************************************
// Erstellt 27.12.2016 von MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Beschreibung:
//
//********************************************************************************************************************************************
//  Änderungen:
//    27.02.2017    MZ    #140658915, seprate cc_ticket_email_address and bcc_ticket_email_address from ticket_email_address for sending email to partners
//    28.03.2017    Mz    add new recordType "Hausnotruf"
//    10.04.2017    MZ    add "Hausnotruf" partner products
//    11.04.2017    TK    Korrektur eines Rechtschreibfehlers in Fehlermeldungen
//    25.04.2017    MZ    add new functionalities to support "new family member"
//    04.05.2017    AM    #144429537 send email to partner with XML attachment if in structuredEmail XML-template.
//    14.06.2017    MZ    remove categoryCheckText and noEmailText error messages for Notrufsysteme-Selfmailer
//    15.06.2017    MZ    replace OPP:Opportunity_Nummer__c with PT:Partner_Ticket_name in sending email to partners
//    03.07.2017    MZ    new checkboxes "Partner darf sich telefonisch melden" and "Partner darf Infomaterial per Post zusenden"
//    05.07.2017    MZ    "Hausnotruf" condition added to againInformPartner to save KI
//    05.07.2017    MZ    "telefonisch melden", "Infomaterial senden" und "noOptInError" added
//    13.07.2017    BT    Erweiterung um die Recordtypen "Widerspruch" und "Pflegeimmobilien"
//    19.08.2017    MZ    in sendEmailtoPartners, the condition "if(partnerTicketId != null)" added.
//    31.08.2017    MZ    Kostentraeger_Nummer is saved in partnerTicket
//    20.10.2017    MZ    #150706477 Kostentraeger_Nummer is commented. the ticket is on hold.
//    25.10.2017    MZ   case 00001312 - the plain text of email to customer changed to match the html content
//    16.11.2017    MZ    #152709934 specific template for PI added
//    28.12.2017    MZ    #153698846 (limit exception error) and #153922965 (partner-product price levels)
//    09.01.2018    MZ    #154175485
//    27.02.2018    MZ    #155027699
//    02.03.2018    MZ    #155359250 interface to send Direktvertrieb (DV) data to Libify
//    06.03.2018    MZ    #155030674 check if http request to Libify is already sent for ticket-id, stop sending a second request.
//    10.04.2018    MZ    static string for Badumbau record-type added.
//    02.07.2018    MZ    00001550 adjusting plz-tool for Badumbau
//    04.08.2018    MZ    160168554 Kein Partner im PLZ-Gebiet verfügbar
//    26.09.2018    MZ    160787447 Widerspruch Mailtemplate
//    12.02.2019    MZ    163646169 ZWB - Änderung der Opt In Checkboxen
//    16.12.2019    AM    170277552 Badumbau - Änderung der Opt In Checkboxen (wie oben, auch fü Badumbau)
//    04.02.2020    DZ    Neue Checkbox: ASP_PB_Einwilligungserkl_rung__c
//    06.02.2020    DZ    Ergänzung um Record type "Pflegeschulungen"
//    20.07.2020    BT    Send request to Promedica
//    09.09.2020    DZ    Changed "customerTemplateBad"
//    11.11.2020    DZ    Deleted "badumbauMailSent = true;"
//********************************************************************************************************************************************
*/

public virtual class PLZTool_Basis{
    
    plzEmailTagsGenerator tagGenerator = new plzEmailTagsGenerator();
    public Id opportunityId{set; get;}
    public Opportunity formOpp{set; get;}
    private String opportunityRecordType;
    
    public boolean TreppenliftOpp{set; get;}
    public boolean BetreuungsleistungenOpp{set; get;}
    public boolean HausnotrufOpp{set; get;}
    public boolean WiderspruchOpp {get; set;}
    public boolean PflegeimmobilienOpp {get; set;}
    public boolean BadumbauOpp {get; set;}
    public boolean PflegeschulungenOpp {get; set;}
    
    public PLZTool_Hausnotruf hnrController{set;get;}
    public NewFamilyMember newMemberController{set;get;}
    public EditFamilyMember editMemberController{set;get;}
    
    public PLZTool_Badumbau badController{set;get;}    
    
    public Map<Id, PLZTool_PartnerProduct> productMap = new Map<Id, PLZTool_PartnerProduct>();
    protected integer totalSize;
    
    private Map<Id, PLZTool_PartnerProduct> selectedProductMap = new Map<Id, PLZTool_PartnerProduct>();
    protected integer selectedTotalSize;
    
    protected Map<Id, Partner_Ticket__c> partnerTicketsMap = new Map<Id, Partner_Ticket__c>(); // the Id is the Id of Partner_Produkte__c
    protected map<id, Partner_Ticket__c> exPartnerTicketsMap = new map<id, Partner_Ticket__c>(); // like above but for againInformPartner 
    //protected List<Partner_Ticket__c> toUpdateTickets = new List<Partner_Ticket__c>(); 
    
    protected User currentUser;
    protected contact primaryContact;
    protected Contact insuredPerson;
    protected Contact contactPerson;
    public String customerComment{set; get;}
    
    public String selectedPartnerString {set; get;}
    public Integer scrollPosition {set; get;}
    public String exPartnerString {set; get;}
    public String exPartnerIsExclusive {set; get;}
    
    protected boolean firstPage = true;
    protected boolean secondPage = false;
    protected boolean thirdPage = false;
    
    protected boolean enableNextButton = true;
    protected boolean enableSendEmail = true;
    
    public boolean sameComment{set; get;}
    public boolean unmatchedCategoryAccepted {set; get;}
    //public boolean noOptInAccepted {set; get;}
    
    public static String rtTreppenlift = 'Treppenlift';
    public static String rtBetreuungsleistungen = 'Betreuungsleistungen';
    public static String rtHausnotruf = 'Notrufsysteme';
    public static string rtWiderspruch = 'Widerspruch';
    public static string rtPflegeimmobilien = 'Pflegeimmobilien';
    public static String rtBadumbau = 'Badumbau';
    public static String rtPflegeschulungen = 'Pflegeschulungen';
    
    
    public static String nachtelefonie_status_potential = 'Potential';
    public static String customerTemplateName = 'PLZToolCustomerTemplate';
    //public static String customerTemplateWS = 'PLZToolCustomerWSTemplate';
    public static String customerTemplatePI = 'PLZToolCustomerPITemplate';
    public static String customerTemplatePIwithAttach = 'PLZToolCustomerPITemplateWithAttachment';
    public static String customerTemplateBad = 'Kunde_Best_tigung_Aufma_koordinierung';
    public static String partnerTemplateName_single = 'PLZToolPartnerTemplateSingle';
    public static String partnerTemplate_PI = 'PLZToolPartnerTemplate_PI';
    public static String partnerTemplateName_multi = 'PLZToolPartnerTemplateSingle'; //'PLZToolPartnerTemplateMulti';
    public static String partnerTemplateBad = 'Partner_Weiterleitung_Aufmasskoordinierung';
    
    public static String contactRolePrimary = 'PRM';
    public static String contactRoleInsured = 'PB';
    public static String contactRoleContact = 'ASP';
    public static String contactRoleSame = 'PB = ASP';
    
    public static String oppStatusErfolg = 'Erfolg';
    public static String oppStatusBadumbauAufmassphase = 'Aufmaßphase';    
    public static String oppStatusWiedervorlageKat2 = 'Wiedervorlage Kat. 2';
    public static String oppCatgeoryExclusiv = 'Exklusiv';
    
    public static String ppStatusKeineAbrechnung = 'keine Abrechnung';
    public static String ptStatusKeineAbrechnung = 'keine Abrechnung';
    public static String ptStatusAbrechenbar = 'Abrechenbar';
    public static String ptStatusUbermittelt = 'Übermittelt';
    
    public static String ownerError = 'Zur Weiterverarbeitung musst du Inhaber des Datensatzes sein';
    public static String noFilterError = 'Bitte wähle eine Produkt- bzw.  Unterstützungsart aus';
    public static String noProductError = 'Kein Partner im PLZ-Gebiet verfügbar';
    public static String noPlzError = 'Keine Postleitzahl zur Suche angegeben. Bitte wähle "Bezugspunkt der PLZ-Suche" und die "Kontakt-Rolle" innerhalb der Opportunity aus.';
    public static String noEmailText = 'Der ausgewählte Partner hat keine Email-Addresse hinterlegt. Bitte kontaktiere deinen Teamlead! ';
    public static String warningText = 'Der ausgewählte Partner ist CPL/CPO exklusiv! Möchtest du die Auswahl anderer Partner abbrechen? <span class="btn" onclick="keepExclusiveInJavascript()"> Ja </span> <span class="btn" onclick="removeExclusiveInJavascript()"> Nein </span>';
    public static String errorText = 'Der ausgewählte Partner ist CPL/CPO exklusiv! Es können keine weiteren Partner ausgewählt werden';
    public static String samePartnerErrorText = 'Du hast diesen Partner bereits ausgewählt.';
    public static String selectOneText = 'Bitte wähle mindestens einen Partner aus! ';
    public static String noInsuredPerson = 'Keine Versicherte Person in der Opportunity gefunden, bitte wähle diese in den Kontakt-Rollen innerhalb der Opp. aus! ';
    public static String noPrimaryContact = 'Die Opportunity hat keine primäre Kontakt-Person. Bitte wähle diese in den Kontakt-Rollen innerhalb der Opp. aus!';
    public static String warningAlreadyErfolg = 'Für diese Opportunity sind bereits Vorschläge an Partner und Interessenten verschickt worden. Noch einmal senden ? <span class="btn" onclick="sendEmailInJavascript()"> Ok </span> <span class="btn" onclick="cancelEmailInJavascript()"> Abbruch</span>';
    public static String emailNichtGesendet = 'Dieser Ansprechpartner hat keine Email-Adresse. Daher wurde keine Mail gesendet.';
    public static String PartnerEmailfehlerhaft = 'Einer der Partner hat keine oder eine fehlerhafte Email-Adresse. Daher wurde keine Mail gesendet. <span class="btn" onclick="GoBackToContact()"> Ok </span>';
    public static String emailNotValid = 'Dieser Ansprechpartner hat eine fehlerhafte Email-Adresse. <span class="btn" onclick="GoBackToContact()"> Ok </span>';
    public static String againInformText = 'Sollen die bestehenden Partner nochmals informiert werden? <span class="btn" onclick="againInformPartner()"> Ja </span> <span class="btn" onclick="notInformPartner()"> Nein </span>';
    public static String categoryCheckText = 'Für diesen Partner ist kein Preis für die angegebene "Preis-Kategorie" hinterlegt. Möchtest du dennoch fortsetzen? <span class="btn" onclick="acceptUnmachedCat()"> Ja </span> <span class="btn" onclick="denyUnmachedCat()"> Nein </span>';
    public static String noOptInError = 'Die Weiterleitung an den Partner/ telefonische Kontaktaufnahme oder Kontaktaufnahme per E-Mail wurde nicht akzeptiert. Bitte alle drei ankreuzen, bevor du fortfährst.';
    public static String primaryEmailError = 'Dieser primäre Kontakt-Person hat keine Email-Adresse. Daher wird keine E-Mail an Kontakt schicken!';
    public static String selectOnePartnerOnly = 'Bitte wählen Sie nur einen Partner aus!';
    
    
    public String potentialValue{set;get;}
    
    public void showPage(Integer i){
        firstPage = false;
        secondPage = false;
        thirdPage = false;
        if(i == 3){
            thirdPage = true;
            checkPrimaryEmail();
        }else if(i == 2){
            secondPage = true;
        }else{
            firstPage = true;
        }    
    }
    
    public void checkPrimaryEmail(){
        if(primaryContact != null && String.isEmpty(primaryContact.Email)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, primaryEmailError ));
        }
    }
    
    public boolean getFirstPage(){
        return firstPage;
    }
    public boolean getSecondPage(){
        return secondPage;
    }
    public boolean getThirdPage(){
        return thirdPage;
    }
    
    public PageReference backToOpportunity() { 
        PageReference returnPage = new PageReference('/' + opportunityId);
        returnPage.setRedirect(true);
        return returnPage;
    }
    
    private void setRecordType(String rt){
        opportunityRecordType = rt;
        TreppenliftOpp = false;
        BetreuungsleistungenOpp = false;
        HausnotrufOpp = false;
        WiderspruchOpp = false;
        PflegeimmobilienOpp = false;
        BadumbauOpp = false;
        PflegeschulungenOpp = false;
        
        
        if(opportunityRecordType == rtTreppenlift ){
            TreppenliftOpp = True;
        }
        else if(opportunityRecordType == rtBetreuungsleistungen ){
            BetreuungsleistungenOpp = True;
        }
        else if(opportunityRecordType == rtHausnotruf){
            HausnotrufOpp = True;
        }
        else if(opportunityRecordType == rtWiderspruch){
            WiderspruchOpp = True;
        }
        else if(opportunityRecordType == rtPflegeimmobilien) {
            PflegeimmobilienOpp = True;
        }
        else if(opportunityRecordType == rtBadumbau) {
            BadumbauOpp = True;
        }
        else if(opportunityRecordType == rtPflegeschulungen) {
            PflegeschulungenOpp = True;
        }
    }
    
    public PLZTool_Basis() {
        initiatePLZTool();
    }
    
    public void initiatePLZTool(){
        scrollPosition = -1;
        
        opportunityId = ApexPages.currentPage().getParameters().get('id');
        queryOpportunity(opportunityId);
        
        if( isOwner(opportunityId ) ){
            
            PostleitzahlenTool plzTool = new PostleitzahlenTool(opportunityId);
            
            setRecordType(plzTool.getRecordType());
            
            if( plzTool.hasProduct() ) {
                if( plzTool.hasPlz() ) {
                    String defaulComment = plzTool.getAnmerkungenDenPartner();
                    string exPartner = plzTool.existingPartners(id.valueOf(opportunityId));
                    selectedPartnerString = '';
                    exPartnerIsExclusive = '';
                    List<Partner_Produkte__c> prdctList = plzTool.getBestPartners();
                    if( prdctList == null || prdctList.size() == 0){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noProductError ));
                    }else{
                        for(Partner_Produkte__c prdct : prdctList ) {
                            PLZTool_PartnerProduct pp = new PLZTool_PartnerProduct(prdct, false);
                            
                            pp.comment = defaulComment;
                            productMap.put(prdct.Id, pp);
                            string exPa = prdct.Partner__c;
                            if(exPartner != '') {
                                if(exPartner.contains(exPa)) {
                                    if(selectedPartnerString == '') {
                                        selectedPartnerString = string.valueOf(prdct.Id);
                                    } else selectedPartnerString += ',' + string.valueOf(prdct.Id); 
                                    if(isExlusive(pp)) exPartnerIsExclusive = 'excl';
                                }                   
                            }
                        }
                        exPartnerString = selectedPartnerString;
                        productMap = PLZTool_PartnerProduct.setPrice(productMap);
                    }
                } else {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noPlzError ));
                }      
            } else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noFilterError ));
            } 
        }
        showPage(1);
    }
    
    // to exeute the functionalities which are dependant on the opportunity recprd type
    public PageReference recordTypeSpecificAction(){
        newMemberController = new NewFamilyMember(opportunityId, true);
        editMemberController = new EditFamilyMember(opportunityId);
        if(BetreuungsleistungenOpp != null && BetreuungsleistungenOpp){
            PLZTool_Betreuungsleistungen bel = new PLZTool_Betreuungsleistungen(opportunityId);
            return bel.mainAction();
        }
        if(HausnotrufOpp != null && HausnotrufOpp ){
            hnrController = new PLZTool_Hausnotruf(opportunityId, productMap.values());
        }
        
        if(BadumbauOpp != null && BadumbauOpp ){
            badController = new PLZTool_Badumbau(formOpp, productMap.values());
        }
        
        return null;
    }
    
    public List<PLZTool_PartnerProduct> getProductList(){
        return productMap.values();
    }
    
    public List<PLZTool_PartnerProduct> getselectedProductList (){
        return selectedProductMap.values();
    }
    /*
public Integer getTotalPartnerSizeBadumbau() {
if(badController != null){
return badController.getTotalPartnerSize();
}
return 0;
}*/
    
    public Integer getTotalSize() {
        return productMap!= null ? productMap.size() :0 ;
    }
    
    public Integer getSelectedTotalSize() {
        return selectedProductMap!= null ? selectedProductMap.size() :0 ;
    }
    
    public PageReference updateCommentFields(){
        if(sameComment){
            boolean firstEnabled = false;
            for( PLZTool_PartnerProduct p : selectedProductMap.values() ){
                if(!firstEnabled){
                    firstEnabled = true;
                    p.disabled = false;
                }else{
                    p.disabled = true;
                    p.comment = '';
                }
            }
        }else{
            for( PLZTool_PartnerProduct p : selectedProductMap.values() ){
                p.disabled = false;
            }        
        }
        return null;
    }
    
    public void updateSelectedProduct() {
        
        Id selectedProductId = System.currentPagereference().getParameters().get('selectedProductId');    
        PLZTool_PartnerProduct product = productMap.get(selectedProductId);
        if(product.selected) { 
            if(hasEmail(product)) {
                
                if( selectedProductMap.size() > 0 ){
                    if(containsExclusive()){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, errorText ));
                        productMap.get(selectedProductId).selected = false; 
                        if( selectedProductMap.size() > 1){                           
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, warningText ));
                        }
                        if(isDuplicate(product)){
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, samePartnerErrorText ));
                            productMap.get(selectedProductId).selected = false;
                        }
                        return;              
                    }
                    if(isDuplicate(product)){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, samePartnerErrorText ));
                        productMap.get(selectedProductId).selected = false;
                        return;
                    }
                    if(isExlusive(product)){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, warningText ));
                    }          
                }
                
                selectedProductMap.put(selectedProductId, product);  
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noEmailText));
                productMap.get(selectedProductId).selected = false;
                return;
            }   
        } else{
            selectedProductMap.remove(selectedProductId);
            if( selectedProductMap.size() > 1 && containsExclusive() ){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, warningText ));
            }
        } 
    }
    
    public boolean hasEmail(PLZTool_PartnerProduct p) {
        if(p.pp.partner__r.ticket_email_address__c != null && p.pp.partner__r.ticket_email_address__c.trim()!= '' ){
            return true;
        }
        if(HausnotrufOpp){ // partner email address is not needed for Notrufsysteme-selfmailer 
            if(p.pp.PLZ_Tool_Liste__c == PLZTool_Hausnotruf.selfmailerKey ){
                return true;
            }
        }
        return false;
    }
    
    public boolean isDuplicate(PLZTool_PartnerProduct p){
        for(PLZTool_PartnerProduct prdct : selectedProductMap.values()){
            if( prdct.pp.Partner__c == p.pp.Partner__c ){
                return true;
            }
        }
        return false;
    }
    
    public boolean isExlusive(PLZTool_PartnerProduct p){
        if((p.prc.CPL_Exklusiv__c != null && p.prc.CPL_Exklusiv__c != 0) || (p.prc.CPO_Exklusiv_Festpreis__c != null && p.prc.CPO_Exklusiv_Festpreis__c != 0) || (p.prc.CPO_Exklusiv_Prozentual__c != null && p.prc.CPO_Exklusiv_Prozentual__c != 0) ){
            return true;
        }
        return false;
    }
    
    public boolean containsExclusive(){
        for(PLZTool_PartnerProduct prdct : selectedProductMap.values()){
            if( isExlusive(prdct) ){
                return true;
            }
        }
        return false;
    }
    
    public void keepExclusive(){
        PLZTool_PartnerProduct exclusiveProduct;
        // System.debug('###################################alex011 selectedPartnerString=' + selectedPartnerString);   
        if(selectedPartnerString != null) {
            String[] soList = selectedPartnerString.split(',');
            for(string pa : soList) {
                PLZTool_PartnerProduct product = productMap.get(Id.valueOf(pa));
                if( isExlusive(product) ) {
                    selectedPartnerString = string.valueOf(product.pp.id);
                    break;
                }
            }   
        }
        // for(PLZTool_PartnerProduct prdct : selectedProductMap.values()){
        // if( isExlusive(prdct) ){
        // exclusiveProduct = prdct;
        // selectedProductMap.clear();
        // selectedProductMap.put(prdct.pp.Id, prdct);         
        // }
        // }
        // if(exclusiveProduct != null){
        // for(PLZTool_PartnerProduct prdct : productMap.values()){
        // productMap.get(prdct.pp.Id).selected = false;        
        // }
        // productMap.get(exclusiveProduct.pp.Id).selected = true;
        // }   
        //return null;
        enableNextButton = true;
        showPage(1);
    }
    
    public void removeExclusive(){
        PLZTool_PartnerProduct exclusiveProduct;
        // System.debug('###################################alex012 selectedPartnerString=' + selectedPartnerString);   
        // for(PLZTool_PartnerProduct prdct : selectedProductMap.values()){
        // if( isExlusive(prdct) ){
        // exclusiveProduct = prdct;
        // selectedProductMap.remove(prdct.pp.Id);         
        // }
        // }
        // if(exclusiveProduct != null){
        // productMap.get(exclusiveProduct .pp.Id).selected = false;
        // }
        // return null;
        if(selectedPartnerString != null) {
            String[] soList = selectedPartnerString.split(',');
            selectedPartnerString = '';
            for(string pa : soList) {
                PLZTool_PartnerProduct product = productMap.get(Id.valueOf(pa));
                if( !isExlusive(product) ) {
                    if( selectedPartnerString == '') {
                        selectedPartnerString = string.valueOf(product.pp.id);
                    }
                    else selectedPartnerString += ',' + string.valueOf(product.pp.id);
                }       
            }
        }
        enableNextButton = true;
        
        showPage(1);
    }
    
    public void back(){
        unmatchedCategoryAccepted = false; 
        //if(!enableSendEmail) syncSameComments();
        showPage(1);
    }
    
    public void backTo2(){
        showPage(2);
    }
    
    public void syncSameComments(){
        if(sameComment){
            sameComment = false;
            String comment;
            for( PLZTool_PartnerProduct p : selectedProductMap.values() ){
                if(!p.disabled){
                    comment = p.comment;
                }
            }
            for( PLZTool_PartnerProduct p : selectedProductMap.values() ){
                p.comment = comment;
                p.disabled = false;
            }        
        }
    }
    
    public void notInformPartner() {
        enableSendEmail = false;
        setIntendedContacts();
        showPage(3);    
    }
    
    public void againInformPartner() {
        enableSendEmail = true;
        selectedProductMap.clear();
        String[] soList = exPartnerString.split(',');
        for(string pa : soList) {
            PLZTool_PartnerProduct product = productMap.get(Id.valueOf(pa));
            if(hasEmail(product)) {
                selectedProductMap.put(Id.valueOf(pa), product);  
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noEmailText));
                return;
            }               
        }
        
        if(HausnotrufOpp){
            hnrController.saveKI();
        }
        
        exPartnerTicketsMap.clear();
        list<Partner_Ticket__c> pptList = [SELECT Partner_Produkt__c, id, Name FROM Partner_Ticket__c WHERE  Opportunity__c = :opportunityId];
        if((pptList != null) && (pptList.size() > 0)) {
            for(Partner_Ticket__c ppt : pptList) exPartnerTicketsMap.put(ppt.Partner_Produkt__c, ppt);
        }
        setIntendedContacts();
        showPage(2);    
    }
    
    public Pagereference confirm() {
        // AM 16.12.2019
        // if( !BadumbauOpp ){
        if( !formOpp.Partner_darf_sich_telefonisch_melden__c || !formOpp.Partner_darf_Infomaterial_senden__c || !formOpp.Partner_kann_per_E_Mail_kontaktieren__c ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noOptInError ));
            return null;
        }else{
            saveOpportunity();
        }
        // }
        
        System.debug('###################################alex001 selectedPartnerString=' + selectedPartnerString);
        if((selectedPartnerString != null) || (exPartnerString != null)) {
            
            String[] soList = selectedPartnerString.split(',');
            if( (soList.size() == 1 ) &&  (soList[0] == '')) {
                if(exPartnerString == '') {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, selectOneText ));
                    return null;
                }
                else {
                    setIntendedContacts();
                    showPage(3);    
                    return null;             
                }
            }
            
            selectedProductMap.clear();
            for(string pa : soList) {
                boolean paExist = false;
                if(exPartnerString != null) {
                    paExist = exPartnerString.contains(pa);
                }
                PLZTool_PartnerProduct product = productMap.get(Id.valueOf(pa));
                if(hasEmail(product)) {
                    if(!paExist) selectedProductMap.put(Id.valueOf(pa), product);  
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noEmailText));
                    return null;
                }               
            }
        }
        if( selectedProductMap.size() == 0 ){
            if(exPartnerString == '') {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, selectOneText ));
                return null;
            }
            else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, againInformText ));
                return null;
            }
        }
        if( containsExclusive() && selectedProductMap.size() > 1 ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, warningText ));
            return null;
        }
        
        // Notrufsysteme-selfmailer does not need price category
        if(HausnotrufOpp){
            // only one selfmailer product is allowed to be selected
            for( PLZTool_PartnerProduct p : selectedProductMap.values() ) {
                if( p.pp.PLZ_Tool_Liste__c == PLZTool_Hausnotruf.selfmailerKey ){
                    unmatchedCategoryAccepted = true;
                }
            }
        } 
        
        // Badumbau does not need price category
        if(BadumbauOpp){
            // only one Badumbau product is allowed to be selected
            /*
* Id firstPartnerId;
for( PLZTool_PartnerProduct p : selectedProductMap.values() ) {
if(String.isEmpty(firstPartnerId)){
firstPartnerId = p.pp.partner__c;
}
if(firstPartnerId != p.pp.partner__c){
ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, selectOnePartnerOnly ));
return null;
}
*/
            unmatchedCategoryAccepted = true;
            //}
        }
        
        if( (unmatchedCategoryAccepted == null || !unmatchedCategoryAccepted) && !matchCategory() ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, categoryCheckText ));
            return null;
        }
        if(HausnotrufOpp){
            String result = hnrController.continueHnr(selectedProductMap.values());
            if(result == PLZTool_Hausnotruf.extraPage){
                return null;
            }
        }
        
        createPartnerTickets();
        
        System.debug('###################################alex002 selectedProductMap.size()=' + selectedProductMap.size());
        showPage(2);
        return null;
    }
    
    public boolean matchCategory(){
        if(formOpp == null || formOpp.Id != opportunityId){
            queryOpportunity(opportunityId);
        }
        
        for( PLZTool_PartnerProduct p : selectedProductMap.values() ) {
            if( !isExlusive(p) ){
                if(formOpp.Kategorie__c == '1'){
                    if( (p.prc.CPL_Kat_1__c == null || p.prc.CPL_Kat_1__c == 0) &&
                       (p.prc.CPO_Kat_1_Festpreis__c == null || p.prc.CPO_Kat_1_Festpreis__c == 0) &&
                       (p.prc.CPO_Kat_1_Prozentual__c == null || p.prc.CPO_Kat_1_Prozentual__c == 0) ){
                           unmatchedCategoryAccepted = False;
                           return False;
                       } 
                } 
                if(formOpp.Kategorie__c == '2'){
                    if( (p.prc.CPL_Kat_2__c == null || p.prc.CPL_Kat_2__c == 0) &&
                       (p.prc.CPO_Kat_2_Festpreis__c == null || p.prc.CPO_Kat_2_Festpreis__c == 0) && 
                       (p.prc.CPO_Kat_2_Prozentual__c == null || p.prc.CPO_Kat_2_Prozentual__c == 0) ){
                           unmatchedCategoryAccepted = False;
                           return False;
                       } 
                }
            }
        }
        return True;
    }
    
    public void denyUnmachedCat(){
        unmatchedCategoryAccepted = False;
    }
    
    public Pagereference acceptUnmachedCat(){
        unmatchedCategoryAccepted = True;
        return confirm();
    }
    
    /*
public void denyNoOptIn(){
noOptInAccepted = False;
}

public Pagereference acceptNoOptIn(){
noOptInAccepted = True;
return confirm();
}
*/
    
    public void confirmTickets(){
        syncSameComments();
        setIntendedContacts();
        showPage(3);
    }
    
    public void saveNewMemberAndRefreshThirdPage(){
        system.debug('mansi: saveNewMemberAndRefreshThirdPage');
        newMemberController.updateContactRoles();
        //setIntendedContacts();
        productMap = new Map<Id, PLZTool_PartnerProduct>();
        initiatePLZTool();
    }
    
    public void saveEditMemberAndRefreshThirdPage(){
        system.debug('mansi: saveEditMemberAndRefreshThirdPage');
        editMemberController.updateContactRoles();
        //setIntendedContacts();
        productMap = new Map<Id, PLZTool_PartnerProduct>();
        initiatePLZTool();
    }
    
    private void setIntendedContacts(){
        primaryContact = null;
        insuredPerson = null;
        contactPerson = null;
        List<OpportunityContactRole> contactRoles = [select ContactId, Role, IsPrimary  from OpportunityContactRole where OpportunityId = :opportunityId and IsDeleted = false];
        boolean EmailBounced = false;
        string BouncedReason = null;
        if(contactRoles != null && contactRoles.size()>0){
            for( OpportunityContactRole cr : contactRoles  ){
                String contactQuery = 'select Id, salutation,firstName, lastname, Name, Phone, Email, mailingStreet, MailingCity, MailingPostalCode, EmailBouncedDate, EmailBouncedReason from Contact where Id = \''+cr.ContactId+'\' limit 1';
                List<Contact> contactList =  Database.query(contactQuery);
                if(contactList != null && contactList.size() > 0){
                    if(cr.IsPrimary){
                        primaryContact = contactList[0];
                    }
                    if(cr.Role == contactRoleInsured){
                        insuredPerson = contactList[0];                    
                    }               
                    if(cr.Role == contactRoleContact){
                        contactPerson = contactList[0];
                    } 
                    if(cr.Role == contactRoleSame){
                        insuredPerson = contactList[0];
                        contactPerson = contactList[0];
                    }
                    if(contactList[0].EmailBouncedDate != null) {
                        EmailBounced = true;
                        BouncedReason = contactList[0].EmailBouncedReason;
                    }
                } 
            }
            if(insuredPerson == null) {
                insuredPerson = contactPerson;
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noInsuredPerson)); 
            }
            if(primaryContact == null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noPrimaryContact));
            }
            // AM 2016.09.05
            if(EmailBounced) {
                if(BouncedReason != null ) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Dieser Ansprechpartner hat eine fehlerhafte Email-Adresse. ' + BouncedReason + ' <span class="btn" onclick="GoBackToContact()"> Ok </span>'));
                }
                else {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, emailNotValid));
                }
            }
            
            
        }else{
            System.debug('error in setIntendedContacts:::: Mansi::: no contact role found !!!');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No contact role is defined for the opportunity! '));
        }
    }
    
    public Contact getInsuredPerson(){
        return insuredPerson;
    }
    
    public Contact getContactPerson(){
        return contactPerson;
    }
    
    public void createPartnerTickets(){
        PartnerTicketsMap.clear();
        if(formOpp == null || formOpp.Id != opportunityId){
            queryOpportunity(opportunityId);
        }
        
        // for "Badumabu", only one ticket is needed. it will be created for the first product
        //Boolean badumabuHasTicket = false;
        
        for( PLZTool_PartnerProduct p : selectedProductMap.values() ) {
            
            
            
            String Kostenstelle_Nummer;
            List<Kostenstelle__c> Kostenstelle_list = [select Id, Kostenstelle_Nummer__c from Kostenstelle__c where Id = :p.pp.Kostenstelle__c limit 1];
            if(Kostenstelle_list != null && Kostenstelle_list.size()>0){
                Kostenstelle_Nummer = Kostenstelle_list [0].Kostenstelle_Nummer__c;
            }
            
            /* MZ 20.10.2017 #150706477
String Kostentraeger_Nummer;
List<Kostentr_ger__c> Kostentraeger_list = [select Id, Kostentr_ger_Nummer__c from Kostentr_ger__c where Id = :p.pp.Kostentr_ger__c limit 1];
if(Kostentraeger_list != null && Kostentraeger_list.size()>0){
Kostentraeger_Nummer = Kostentraeger_list [0]. Kostentr_ger_Nummer__c;
}
*/
            string exPa = string.valueOf(p.pp.Partner__c);
            boolean isExPa = false;
            if(exPartnerString != null) {
                isExPa = exPartnerString.contains(exPa);
            }
            if(!isExPa) {
                Partner_Ticket__c pt = new Partner_Ticket__c();
                pt.Opportunity__c = opportunityId;
                pt.Partner__c = p.pp.Partner__c;
                pt.Partner_Produkt__c = p.pp.Id;
                pt.Preis_Kategorie_der_Opportunity__c = formOpp.Kategorie__c;
                pt.Kostenstelle__c = Kostenstelle_Nummer;
                
                /* MZ 20.10.2017 #150706477
pt.Kostentr_ger__c = Kostentraeger_Nummer;
*/
                
                // AM 06.09.2016
                if(isExlusive(p)) {         
                    pt.Preis_Kategorie_der_Opportunity__c = 'Exklusiv';
                }       
                
                if( (p.prc.CPL_Kat_1__c != null && p.prc.CPL_Kat_1__c != 0) || 
                   (p.prc.CPL_Kat_2__c != null && p.prc.CPL_Kat_2__c != 0) || 
                   (p.prc.CPL_Exklusiv__c != null && p.prc.CPL_Exklusiv__c != 0)){
                       
                       if(p.pp.Abrechnungsmethode__c == ppStatusKeineAbrechnung){
                           pt.Status_CPL__c = ptStatusKeineAbrechnung;
                       }else{
                           pt.Status_CPL__c = ptStatusAbrechenbar;
                       }
                       
                       if(pt.Preis_Kategorie_der_Opportunity__c == '1'){
                           pt.Wert_des_Partner_Tickets_CPL__c = p.prc.CPL_Kat_1__c ;
                       } else if(pt.Preis_Kategorie_der_Opportunity__c == '2'){
                           pt.Wert_des_Partner_Tickets_CPL__c = p.prc.CPL_Kat_2__c ;
                       }
                       
                       if(pt.Preis_Kategorie_der_Opportunity__c == 'Exklusiv'){
                           pt.Wert_des_Partner_Tickets_CPL__c = p.prc.CPL_Exklusiv__c;
                       } 
                   }
                if( (p.prc.CPO_Kat_1_Festpreis__c != null && p.prc.CPO_Kat_1_Festpreis__c != 0) || 
                   (p.prc.CPO_Kat_1_Prozentual__c != null && p.prc.CPO_Kat_1_Prozentual__c != 0) ||
                   (p.prc.CPO_Exklusiv_Festpreis__c != null && p.prc.CPO_Exklusiv_Festpreis__c != 0) ||
                   (p.prc.CPO_Exklusiv_Prozentual__c != null && p.prc.CPO_Exklusiv_Prozentual__c != 0) ||
                   (p.prc.CPO_Kat_2_Festpreis__c != null && p.prc.CPO_Kat_2_Festpreis__c != 0) || 
                   (p.prc.CPO_Kat_2_Prozentual__c != null && p.prc.CPO_Kat_2_Prozentual__c != 0)){
                       
                       if(p.pp.Abrechnungsmethode__c == ppStatusKeineAbrechnung){
                           pt.Status_CPO__c = ptStatusKeineAbrechnung;
                       }else{
                           pt.Status_CPO__c = ptStatusUbermittelt;
                       }
                   }
                
                /** condition added for Badumabu, we generate only one ticket **/
                //if(!badumbauOpp || (!badumabuHasTicket && p.pp.ProduktType__c == 'Produkt' ) ){
                partnerTicketsMap.put(p.pp.Id, pt);
                //    badumabuHasTicket = true;
                //}
                
            }       
        }
    }
    
    /** MZ 20.10.2017 #153698846
Update previous partner product tickets
**/
    @future(callout=true)
    public static void futureUpdateAllTickets(Id ppId, Decimal CPL_Kat_1, Decimal CPL_Kat_2, Decimal CPL_Exklusiv){
        
        //List<Partner_Ticket__c> preTicketList = [select Id, Status_CPL__c, Wert_des_Partner_Tickets_CPL__c, Preis_Kategorie_der_Opportunity__c, opportunity__r.Kategorie__c from Partner_Ticket__c 
        //    where Partner_Produkt__c = : ppId and Status_CPL__c = :ptStatusAbrechenbar ];
        
        List<Partner_Ticket__c> preTicketList = [select Id, Status_CPL__c, Wert_des_Partner_Tickets_CPL__c, Preis_Kategorie_der_Opportunity__c, opportunity__r.Kategorie__c from Partner_Ticket__c 
                                                 where Partner_Produkt__c = : ppId and 
                                                 Status_CPL__c = :ptStatusAbrechenbar and
                                                 ( (Preis_Kategorie_der_Opportunity__c = '1' and Wert_des_Partner_Tickets_CPL__c != :CPL_Kat_1) or
                                                  (Preis_Kategorie_der_Opportunity__c = '2' and Wert_des_Partner_Tickets_CPL__c != :CPL_Kat_2) or
                                                  (Preis_Kategorie_der_Opportunity__c = 'Exklusiv' and Wert_des_Partner_Tickets_CPL__c != :CPL_Exklusiv)
                                                 )
                                                ];
        
        if(preTicketList != null && preTicketList.size() > 0){
            for(Partner_Ticket__c t : preTicketList ) {
                if(t.Preis_Kategorie_der_Opportunity__c == '1'){
                    t.Wert_des_Partner_Tickets_CPL__c = CPL_Kat_1;
                }else if(t.Preis_Kategorie_der_Opportunity__c == '2'){
                    t.Wert_des_Partner_Tickets_CPL__c = CPL_Kat_2;
                }if(t.Preis_Kategorie_der_Opportunity__c == 'Exklusiv') {
                    t.Wert_des_Partner_Tickets_CPL__c = CPL_Exklusiv;
                }
            }
        }
        update preTicketList;               
    }
    
    
    
    public PageReference checkOpportunityStatus() {
        return sendEmail();
    }
    
    public PageReference showExclusive(){
        enableNextButton = false;
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, warningText ));
        return null;
    }
    
    public PageReference cancelSendEmail(){
        return null;
    }
    
    public PageReference sendEmail() {
        setCurrentUser();
        Savepoint sp = Database.setSavepoint();
        
        try {
            
            System.debug('###################################alex101 insertTickets');
            insertTickets();
            
            System.debug('###################################alex102 createNachtelefonie');
            createNachtelefonie();
            
            System.debug('###################################alex103 updateOpportunity');
            if(BadumbauOpp){
                updatePartnerInOpportunity();
                updateOpportunity(oppStatusBadumbauAufmassphase);
            }else{
                updateOpportunity(oppStatusErfolg);
            }
            
            System.debug('###################################alex104 enableSendEmail=' + enableSendEmail);    
            if(enableSendEmail) sendEmailToPartners(); 
            
            
        } catch (Exception e) {
            // Roll the database back to before we saved ANYTHING
            Database.rollback(sp);
            for(Partner_Ticket__c pt : partnerTicketsMap.values()){
                pt.Id = null;
            }
            System.debug(e);
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, e.getMessage())); 
            return Apexpages.currentPage();     
        }
        try{
            System.debug('###################################alex103 sendHttpRequest');
            sendHttpRequest();
        }catch(exception e){
            System.debug('mansi:: error in sendHttpRequest to Partner:::' + e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, e.getMessage()));
        }
        
        try{
            sendEmailToCustomer();
            
        }
        catch(exception e){
            System.debug('mansi:: error in sendEmail to customer:::' + e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, e.getMessage()));
        }
        
        
        return backToOpportunity();  
        
    }
    
    public void sendHttpRequest(){
        map<Id, String> afilliateCodeMap = new map<Id, String>();
        Id libifyL_Id, libifyU_Id, libifyD_Id;
        List<Account> libify_list = [select Id, name from Account where name = : libifyRequest.libifyL or name = : libifyRequest.libifyU or name = : libifyRequest.libifyD];
        if(libify_list != null && libify_list.size()>0){
            for(Account l_acc : libify_list){
                if(l_acc.name == libifyRequest.libifyL){
                    afilliateCodeMap.put(l_acc.Id, libifyRequest.libifyL_NUL);
                }
                if(l_acc.name == libifyRequest.libifyU){
                    afilliateCodeMap.put(l_acc.Id, libifyRequest.libifyU_UL);
                }
                if(l_acc.name == libifyRequest.libifyD){
                    afilliateCodeMap.put(l_acc.Id, libifyRequest.libifyD_DA);
                }
            }
            for(PLZTool_PartnerProduct p : selectedProductMap.values()) {
                Set<Id> requestSent = new Set<Id>();
                if(afilliateCodeMap.containsKey(p.pp.Partner__c)){
                    Id partnerTicketId = null;
                    if(!partnerTicketsMap.isEmpty()) {
                        partnerTicketId = partnerTicketsMap.get(p.pp.Id).Id;
                    }else if (!exPartnerTicketsMap.isEmpty()) {
                        if(exPartnerTicketsMap.get(p.pp.Id)!= null){
                            partnerTicketId = exPartnerTicketsMap.get(p.pp.Id).Id;
                        }
                    }
                    if(partnerTicketId != null){
                        if(requestSent.isEmpty() || !requestSent.contains(partnerTicketId)){
                            requestSent.add(partnerTicketId);
                            futureSendHttpRequest(partnerTicketId, afilliateCodeMap.get(p.pp.Partner__c));
                        }
                    }
                }
            }
        } 
    }
    
    @future(callout=true)
    public static void futureSendHttpRequest(Id ticketId, String afilliateCode){
        if(afilliateCode == libifyRequest.libifyD_DA){
            libifyRequest.send_libifyRequest_DV(ticketId, afilliateCode);
        }else{
            libifyRequest.send_libifyRequest(ticketId, afilliateCode);
        }
    }
    
    public Boolean createNachtelefonie(){
        if( potentialValue != null && potentialValue != '0' && potentialValue != 'None'){
            // the potential Nachtelefonie doesn't need an opportunity
            if(formOpp == null || formOpp.Id != opportunityId){
                queryOpportunity(opportunityId);
            }
            Nachtelefonie__c nc = new Nachtelefonie__c ();
            nc.name = 'NT - Potential - ' + formOpp.Account.Familien_Name__c ;
            nc.Familie__c = formOpp.Account.id;
            nc.status__c = nachtelefonie_status_potential;
            Datetime today = Datetime.now();           
            nc.F_lligkeitsdatum__c = today.addMonths(Integer.valueof(potentialValue ));
            nc.Pflegebed_rftiger__c = insuredPerson.id;
            nc.Ansprechpartner__c = contactPerson.id;
            List<user> userList = [select Id, name from User where name = 'IT Support' limit 1];
            if(userList != null && userList.size()>0){
                nc.ownerId = userList[0].Id;
            }
            insert nc;
            return true;  
        }else{
            return false;
        }
    }
    
    public PageReference pi_sendFlyerToCustomer(){
        try{
            setIntendedContacts();
            setCurrentUser();
            String emailTemplateToUse = customerTemplatePIwithAttach;
            String staticResource_attName = 'PlzTool_PI_customerEmailAttachment';
            
            EmailTemplate et = new EmailTEmplate();
            List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = : emailTemplateToUse limit 1];
            
            if(etList != null && etList.size() > 0){
                et = etList[0];
                
            }else{
                System.debug('error in pi_sendFlyerToCustomer:: Mansi:::: template not found');
                throw new applicationException ('Email template not found! Please check the availability of the email template where DeveloperName = ' + emailTemplateToUse);
            }
            if(! et.isActive){
                System.debug('error in pi_sendFlyerToCustomer:: Mansi:::: template is not active');
                throw new applicationException ('Required email template is not active! Please check the availability of the email template where DeveloperName = ' + emailTemplateToUse);
            }
            String htmlValue = et.HtmlValue;
            String plainTextValue = et.Body;
            String subject = et.Subject;
            
            htmlValue = setRecipientFields(htmlValue, primaryContact.salutation, primaryContact.lastname);
            htmlValue = setUserfields(htmlValue);
            
            plainTextValue = setRecipientFields(plainTextValue, primaryContact.salutation, primaryContact.lastname);
            plainTextValue = setUserfields(plainTextValue);
            
            if(primaryContact == null || String.isEmpty(primaryContact.Email)){
                throw new applicationException(emailNichtGesendet);
            }else{
                futureSendEmailToCustomer(htmlValue, plainTextValue, subject, opportunityId, primaryContact.id, staticResource_attName);
            }
        }
        catch(exception e){
            System.debug('mansi:: error in pi_sendFlyerToCustomer:::' + e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
            return Apexpages.currentPage();
        }
        
        return backToOpportunity();
        
    }
    
    public void sendEmailToCustomer(){
        String emailTemplateToUse = customerTemplateName;
        
        EmailTemplate et = new EmailTEmplate();
        List<Partner_Produkte__c> ppList = new List<Partner_Produkte__c>();
        
        
        // wenn sendAgain - dann alle tickets aus DB
        if(selectedProductMap.isEmpty()) {
            ppList = [SELECT id, 
                      Name,
                      Kontingent_offen_Produkt__c, 
                      partner__r.ticket_email_address__c,
                      partner__r.ticket_bcc_email_address__c,
                      partner__r.ticket_cc_email_address__c,
                      Partner__r.Kontingent_offen_Partner__c, 
                      Partner__c, 
                      Partner__r.Name, 
                      Produktgruppe__c,
                      partner__r.BillingStreet, 
                      partner__r.BillingCity, 
                      partner__r.BillingPostalCode, 
                      partner__r.Phone, 
                      partner__r.Website, 
                      partner__r.Logo_Url__c, 
                      Anmerkung__c, 
                      Individuelle_Partner_Email__c, 
                      Strukturierte_Partner_Email__c,
                      Email_an_kunden__c,
                      PLZ_Tool_Liste__c
                      from Partner_Produkte__c
                      WHERE id IN (
                          SELECT Partner_Produkt__c from Partner_Ticket__c 
                          WHERE  Opportunity__c = :opportunityId)];
            
        }
        else {
            for(PLZTool_PartnerProduct p : selectedProductMap.values()){
                ppList.add(p.pp);
            }
        }
        
        
        if(HausnotrufOpp){
            String result = hnrController.emailToCustomer(ppList);
            if(result == PLZTool_Hausnotruf.noEmailToCustomer){
                return;
            }
            else{
                emailTemplateToUse = result;
            }
        }
        
        /* removed as 160787447
if(WiderspruchOpp){
emailTemplateToUse = customerTemplateWS;
}*/
        
        if(PflegeimmobilienOpp){
            emailTemplateToUse = customerTemplatePI;
        }
        if(BadumbauOpp){
            emailTemplateToUse = customerTemplateBad;
        }
        
        List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = : emailTemplateToUse limit 1];
        
        if(etList != null && etList.size() > 0){
            et = etList[0];
            
        }else{
            System.debug('error in sendEmailToCustomer:: Mansi:::: template not found');
            throw new applicationException ('Email template not found! Please check the availability of the email template where DeveloperName = ' + emailTemplateToUse);
        }
        if(! et.isActive){
            System.debug('error in sendEmailToCustomer:: Mansi:::: template is not active');
            throw new applicationException ('Required email template is not active! Please check the availability of the email template where DeveloperName = ' + emailTemplateToUse);
        }
        String htmlValue = et.HtmlValue;
        String plainTextValue = et.body;
        String subject = et.Subject;
        
        if(emailTemplateToUse == customerTemplateName || emailTemplateToUse == customerTemplatePI){
            htmlValue = htmlValue.replace('<table id="tblPartners"/>', tagGenerator.generatePartnerListTag(ppList));
            plainTextValue = plainTextValue.replace('<table id="tblPartners"/>', tagGenerator.generatePartnerPlainText(ppList)).replaceAll('<br/>', '\n');
        }
        if(emailTemplateToUse == PLZTool_Hausnotruf.customerTemplateHnrDVName){
            htmlValue = tagGenerator.prepareHnrDVBody(htmlValue, ppList[0], opportunityId);
            plainTextValue = tagGenerator.prepareHnrDVBody(plainTextValue, ppList[0], opportunityId).replaceAll('<br/>', '\n');
            subject = subject.replace('{!PartnerName}', ppList[0].Partner__r.Name);
        }
        if(emailTemplateToUse == customerTemplateBad){
            //htmlValue = EmailMessageTagGenerator_Badumbau.resolveMergeFields(opportunityId, htmlValue, UserInfo.getUserId());
            //plainTextValue = EmailMessageTagGenerator_Badumbau.resolveMergeFields(opportunityId, plainTextValue, UserInfo.getUserId());
            htmlValue = htmlValue.replace('<table id="tblPartners"/>', tagGenerator.generatePartnerListTag(ppList));
            plainTextValue = plainTextValue.replace('<table id="tblPartners"/>', tagGenerator.generatePartnerPlainText(ppList)).replaceAll('<br/>', '\n');
            subject = EmailMessageTagGenerator_Badumbau.resolveMergeFields(opportunityId, subject, UserInfo.getUserId());
        }
        
        
        htmlValue = htmlValue.replace('<p id="comment"/>', getFormattedString(customerComment ));
        plainTextValue = plainTextValue.replace('<p id="comment"/>', getFormattedString(customerComment ));
        
        htmlValue = setRecipientFields(htmlValue, primaryContact.salutation, primaryContact.lastname);
        plainTextValue = setRecipientFields(plainTextValue, primaryContact.salutation, primaryContact.lastname);
        
        htmlValue = setUserfields(htmlValue);
        plainTextValue = setUserfields(plainTextValue);
        
        htmlValue = htmlValue.replace('{!Opportunity.RecordType}', opportunityRecordType);
        plainTextValue = plainTextValue.replace('{!Opportunity.RecordType}', opportunityRecordType);
        
        subject = subject.replace('{!Opportunity.RecordType}', opportunityRecordType); 
        
        if(primaryContact == null || String.isEmpty(primaryContact.Email)){
            throw new applicationException(emailNichtGesendet);
            return ;
        }
        
        
        futureSendEmailToCustomer(htmlValue, plainTextValue, subject, opportunityId, primaryContact.id, null);
        
    }
    
    @future(callout=true)
    public static void futureSendEmailToCustomer(String htmlValuePerPartner, String plainTextBody, string subject, id WhatId, id TargetObjectId, String attName)
    {   
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(htmlValuePerPartner);
        mail.setPlainTextBody(plainTextBody);
        mail.setSubject(subject);
        mail.setWhatId(WhatId);
        mail.setTargetObjectId(TargetObjectId);
        if(!string.isEmpty(attName)) {            
            List<staticResource> sr = [select id, name, body from staticResource where name = :attName LIMIT 1]; 
            if(sr != null && sr.size() > 0) {
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName('Informationsbroschüre.pdf');
                efa.setBody(sr[0].body);       
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
            } 
        } 
        try{
            List<Opportunity> oppList = [select Id, recordType.Name from Opportunity where Id = :WhatId limit 1];
            if(oppList != null && oppList.size()>0 && oppList[0].recordType.Name == PLZTool_Basis.rtBadumbau){
                List<OrgWideEmailAddress> orgWideAddresses = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Badumbau'];
                if(orgWideAddresses != null && orgWideAddresses.size()>0){
                    mail.setOrgWideEmailAddressId(orgWideAddresses[0].Id);
                    mail.setReplyTo(orgWideAddresses[0].Address);
                }
            }
        }catch(Exception e){
            System.debug('###mansi::: error insetting org wide address::'+ e.getMessage());
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );    
    }   
    
    // ********** by any change in the following method please apply the changes in NotificationEmailToPartner.sendEmailToPartners as well
    public void sendEmailToPartners() {
        System.debug('Mansi::: sendEmailToPartners');
        String templateName = partnerTemplateName_single;
        if(PflegeimmobilienOpp){
            templateName = partnerTemplate_PI;
        }
        if(BadumbauOpp){
            templateName = partnerTemplateBad;
        }
        if(formOpp == null || formOpp.Id != opportunityId){
            queryOpportunity(opportunityId);
        }
        
        EmailTemplate et = new EmailTemplate();
        List<EmailTemplate> etList = new List<EmailTemplate>();  
        
        etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = : templateName limit 1];
        
        if(etList != null && etList.size() > 0){
            et = etList[0];
        } else {
            System.debug('error in sendEmailToPartners:: Mansi:::: template not found');
            throw new applicationException ('Email template not found! Please check the availability of the email template where DeveloperName = ' + partnerTemplateName_single);
            return;
        }
        if(!et.isActive){
            System.debug('error in sendEmailToPartners:: Mansi:::: template is not active');
            throw new applicationException ('Required email template is not active! Please check the availability of the email template where DeveloperName = ' + partnerTemplateName_single);
            return;
        }
        
        //one email should be sent for Badumbau.
        Boolean badumbauMailSent = false;  
        
        for(PLZTool_PartnerProduct p : selectedProductMap.values()) {
            if(p.pp.Partner__r.Name.startsWith('Promedica Plus')) {               
                PromedicaRequest.sendRequest(opportunityId, primaryContact.Id, UserInfo.getFirstName(), UserInfo.getLastName());
            }
            else {
                String subject = et.Subject;
                String htmlValue = et.HtmlValue;

                // AM 04.05.2017
                String ptName;
                Id partnerTicketId = null;
                if(!partnerTicketsMap.isEmpty()) {
                    partnerTicketId = partnerTicketsMap.get(p.pp.Id).Id;
                    ptName = partnerTicketsMap.get(p.pp.Id).name;
                }
                else if (!exPartnerTicketsMap.isEmpty()) {
                    if(exPartnerTicketsMap.get(p.pp.Id)!= null){
                        partnerTicketId = exPartnerTicketsMap.get(p.pp.Id).Id;
                        ptName = exPartnerTicketsMap.get(p.pp.Id).Name;
                    }
                }
                string ptIdBackup;
                String ptNameBad;
                if(BadumbauOpp || partnerTicketId != null){
                    
                    if(BadumbauOpp){
                        if(badumbauMailSent){
                            return;
                        }
                        //badumbauMailSent = true;
                      ptIdBackup = partnerTicketId;
                        List<Partner_Ticket__c> ptList = [SELECT id, name from partner_ticket__c where id = :ptIdBackup limit 1];
                        if(ptList.isEmpty()) {
                            ptNameBad = formOpp.Opportunity_Nummer__c;
                        }
                        else {
                            ptNameBad = ptList.get(0).Name;
                        }
                        partnerTicketId = opportunityId;
                        ptName = '';
                    }else{
                        List<partner_ticket__c> pt_list_temp = [SELECT id, name from partner_ticket__c where id = :partnerTicketId limit 1];
                        if(pt_list_temp != null && pt_list_temp.size()>0){
                            ptName = pt_list_temp[0]. name;
                        }
                    }
                    
                    
                    //set product type and opportunityId
                    subject = subject.replace('<OPP:Opportunity_Nummer__c>', opportunityId );
                    // Badumbau Betreff = ptNummer
                    subject = subject.replace('{!Opportunity.Opportunity_Nummer__c}', BadumbauOpp ? ptNameBad : formOpp.Opportunity_Nummer__c);
                    subject = subject.replace('<PT:Partner_Ticket_name>', ptName );
                    
                    if(HausnotrufOpp){
                        if(p.pp.PLZ_Tool_Liste__c == PLZTool_Hausnotruf.direktVertriebKey ){
                            subject = subject.replace('<title_text>', 'Direktversand '+ p.pp.produktgruppe__c);
                        }
                        if(p.pp.PLZ_Tool_Liste__c == PLZTool_Hausnotruf.exklusivKey ){
                            subject = subject.replace('<title_text>', 'erfolgreich durchgestellt');
                        }
                    }
                    if(WiderspruchOpp){
                        subject = subject.replace('<title_text>', 'Anfrage zum ');
                        subject = subject.replace('<OPP:Product>', 'Widerspruch gegen einen negativen Pflegebescheid');
                        htmlValue = htmlValue .replace('<Comment:main>', 'zum Thema Widerspruch gegen einen negativen Pflegebescheid. <Comment:extra>');
                    }
                    
                    subject = subject.replace('<title_text>', 'Anfrage für die Produktgruppe');
                    subject = subject.replace('<OPP:Product>', opportunityRecordType);
                    
                    htmlValue = htmlValue .replace('<header_text>', 'Vermittlung von Interessenten');
                    htmlValue = htmlValue .replace('<Comment:main>', 'für die Produktgruppe "<OPP:Product>". <Comment:extra>');
                    htmlValue = htmlValue .replace('<OPP:Product>', opportunityRecordType);
                    
                    // the standard template is not needed for structuredEmail
                    if(p.pp.Strukturierte_Partner_Email__c != null){
                        // AM 04.05.2017
                        boolean isXML = false;


                        Strukturierte_Partner_Emails__c st = [select id, name, Email_Subject__c, Inhalt_der_Email__c from Strukturierte_Partner_Emails__c where Id = :p.pp.Strukturierte_Partner_Email__c limit 1] ;
                        if(st.Inhalt_der_Email__c.containsIgnoreCase('<?xml version="1.0"')) isXML = true;
                        String plainTextBody;

                        if(st.Name == 'Sunacare Strukturiert_new') {

                            SunacareMail sm = new SunacareMail( opportunityId, st.Inhalt_der_Email__c, partnerTicketId);
                            sm.createBody();
                            plainTextBody = sm.createBody();
                            subject = st.Email_Subject__c;

                            futureSendStructuredEmailToPartners(plainTextBody,
                                    subject,
                                    opportunityId,
                                    p.pp.partner__r.ticket_email_address__c,
                                    p.pp.partner__r.ticket_cc_email_address__c,
                                    p.pp.partner__r.ticket_bcc_email_address__c);

                        }
                        else {
                            System.debug('##########PK ERR ->' + partnerTicketId);
                            System.debug('##########PK opp ID  ->' + opportunityId);
                            plainTextBody = tagGenerator.generateStructuredEmailText(partnerTicketId, opportunityId,
                                    st.Inhalt_der_Email__c, UserInfo.getUserId(), p.comment);
                            subject = tagGenerator.generateStructuredEmailText(partnerTicketId, opportunityId,
                                    st.Email_Subject__c, UserInfo.getUserId(), p.comment);
                            // AM 04.05.2017
                            if (isXML) {
                                futureSendXmlEmailToPartners(plainTextBody,
                                        subject,
                                        opportunityId,
                                        ptName,
                                        p.pp.partner__r.ticket_email_address__c,
                                        p.pp.partner__r.ticket_cc_email_address__c,
                                        p.pp.partner__r.ticket_bcc_email_address__c);
                            } else {
                                futureSendStructuredEmailToPartners(plainTextBody,
                                        subject,
                                        opportunityId,
                                        p.pp.partner__r.ticket_email_address__c,
                                        p.pp.partner__r.ticket_cc_email_address__c,
                                        p.pp.partner__r.ticket_bcc_email_address__c);
                            }
                        }
                    }
                    else{

                        plzPartnerEmailBodyGenerator bodyGenerator = new plzPartnerEmailBodyGenerator(opportunityRecordType);
                        bodyGenerator.setPlzToolListe(p.pp.PLZ_Tool_Liste__c);
                        String htmlValuePerPartner = bodyGenerator.prepareEmailbody(opportunityId, htmlValue, contactPerson, insuredPerson, p.pp.Individuelle_Partner_Email__c);

                        htmlValuePerPartner = setUserfields(htmlValuePerPartner );
                        htmlValuePerPartner = htmlValuePerPartner.replace('<pp:produktgruppe>', p.pp.produktgruppe__c );
                        htmlValuePerPartner = htmlValuePerPartner.replace('<p id="partnerTicket"/>', partnerTicketId );
                        htmlValuePerPartner = htmlValuePerPartner.replace('<p id="comment"/>', getFormattedString(p.comment));
                        futureSendEmailToPartners(htmlValuePerPartner,
                                                  et.body,
                                                  subject,
                                                  opportunityId,
                                                  et.Id,
                                                  p.pp.partner__r.ticket_email_address__c,
                                                  p.pp.partner__r.ticket_cc_email_address__c,
                                                  p.pp.partner__r.ticket_bcc_email_address__c);

                    }
                }
                
                
            }            
        }

    }
    
    public String getFormattedString(String s){
        // replaces < and > with ( and ) because of security issues (e.g. injection)
        if(s !=null && s != ''){
            return '<br/>Kommentar:<br>' + s.replaceAll('<','(').replaceAll('>',')').replaceAll('\n','<br/>')+ '<br/>';
        }else{
            return ' ';
        }
    }
    
    // AM 04.05.2017
    @future(callout=true)
    public static void futureSendXmlEmailToPartners(string plainTextBody, 
                                                    string subject, 
                                                    id WhatId, 
                                                    String attName,
                                                    String emailAddrresses, 
                                                    String ccEmailAddresses, 
                                                    String bccEmailAddresses)
    {   
        System.debug('######################alex002 plainTextBody='+ plainTextBody);
        blob xmlAttach = blob.valueOf(plainTextBody);
        Messaging.EmailFileAttachment xmlAttc = new Messaging.EmailFileAttachment();
        List<Messaging.Emailfileattachment> attList = new List<Messaging.Emailfileattachment>(); 
        String xmlName;
        if(attName != null) {xmlName = attName + '.XML';} else {xmlName = string.valueOf(WhatId) + '.XML';}
        xmlAttc.setFileName(xmlName);
        xmlAttc.setBody(xmlAttach);
        attList.add(xmlAttc);       
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setPlainTextBody('s.Attachment');
        mail.setSubject(subject);
        mail.setWhatId(WhatId);
        mail.setFileAttachments(attList);
        mail.setToAddresses(emailAddrresses.split(','));
        if(!String.isBlank(ccEmailAddresses)){
            mail.setCcAddresses(ccEmailAddresses.split(','));
        }
        if(!String.isBlank(bccEmailAddresses)){
            mail.setBccAddresses(bccEmailAddresses.split(','));
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );    
    }
    
    @future(callout=true)
    public static void futureSendStructuredEmailToPartners(string plainTextBody, 
                                                           string subject, 
                                                           id WhatId, 
                                                           String emailAddrresses, 
                                                           String ccEmailAddresses, 
                                                           String bccEmailAddresses)
    {   
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setPlainTextBody(plainTextBody);
        mail.setSubject(subject);
        mail.setWhatId(WhatId);
        mail.setToAddresses(emailAddrresses.split(','));
        if(!String.isBlank(ccEmailAddresses)){
            mail.setCcAddresses(ccEmailAddresses.split(','));
        }
        if(!String.isBlank(bccEmailAddresses)){
            mail.setBccAddresses(bccEmailAddresses.split(','));
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );  
        System.debug('mansi:: futureSendStructuredEmailToPartners');  
    }
    
    
    @future(callout=true)
    public static void futureSendEmailToPartners(String htmlValuePerPartner, 
                                                 String plainTextBody, 
                                                 String subject, 
                                                 id WhatId, 
                                                 id TemplateId, 
                                                 String emailAddrresses,
                                                 String ccEmailAddrresses,
                                                 String bccEmailAddrresses)
    {   
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(htmlValuePerPartner);
        mail.setPlainTextBody(plainTextBody);
        mail.setSubject(subject);
        mail.setWhatId(WhatId);
        mail.setToAddresses(emailAddrresses.split(','));
        if(!String.isBlank(ccEmailAddrresses)){
            mail.setCcAddresses (ccEmailAddrresses.split(','));
        }
        if(!String.isBlank(bccEmailAddrresses)){
            mail.setBccAddresses (bccEmailAddrresses.split(','));
        }
        mail.setTemplateId(TemplateId);  
        try{
            List<Opportunity> oppList = [select Id, recordType.Name from Opportunity where Id = :WhatId limit 1];
            if(oppList != null && oppList.size()>0 && oppList[0].recordType.Name == PLZTool_Basis.rtBadumbau){
                List<OrgWideEmailAddress> orgWideAddresses = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Badumbau'];
                if(orgWideAddresses != null && orgWideAddresses.size()>0){
                    mail.setOrgWideEmailAddressId(orgWideAddresses[0].Id);
                    mail.setReplyTo(orgWideAddresses[0].Address);
                }
            }
        }catch(Exception e){
            System.debug('########error in setting org wide address - partner email ::'+ e.getMessage());
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );    
    }   
    
    private void insertTickets(){
        System.debug('method started: insertTickets ::::: mansi');
        
        insert partnerTicketsMap.values();
        
        for(Id ppId :partnerTicketsMap.keySet()){
            PLZTool_PartnerProduct pp = selectedProductMap.get(ppId);
            if( (pp == null || pp.prc == null) && productMap != null){
                pp = ProductMap.get(ppId);
            }
            futureUpdateAllTickets(ppId, pp.prc.CPL_Kat_1__c, pp.prc.CPL_Kat_2__c, pp.prc.CPL_Exklusiv__c);
        }
        System.debug('method finished: insertTickets ::::: mansi');
    }
    
    private void updatePartnerInOpportunity(){
        if(formOpp == null || formOpp.Id != opportunityId){
            queryOpportunity(opportunityId);
        }
        
        for(Id ppId :partnerTicketsMap.keySet()){
            PLZTool_PartnerProduct pp = selectedProductMap.get(ppId);
            if( (pp == null || pp.prc == null) && productMap != null){
                pp = ProductMap.get(ppId);
            }
            formOpp.Partner_Badumbau__c = pp.pp.Partner__c;
            //formOpp.Partner_Produkt_Badumbau__c = ppId;
        }
    }
    
    
    
    public void updateOpportunity(String stage){
        if(formOpp == null || formOpp.Id != opportunityId){
            queryOpportunity(opportunityId);
        }
        formOpp.StageName = stage;
        
        /*
if(containsExclusive()){
formOpp.Kategorie__c = oppCatgeoryExclusiv;
}
*/
        
        saveOpportunity();            
        
    }
    
    public class applicationException extends Exception{}
    
    
    public List<SelectOption> getPotentialItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('0','--None--'));
        options.add(new SelectOption('3','3 Monaten'));
        options.add(new SelectOption('6','6 Monaten'));
        options.add(new SelectOption('12','12 Monaten'));       
        return options;
    }
    
    public void setCurrentUser(){
        List<User> uList = [select Id, Name, Title, phone, email from User where Id = :UserInfo.getUserId() limit 1];
        if(uList != null && uList .size()>0){
            currentUser = uList [0];
        }   
    }
    
    public String setUserfields(String str){
        
        if(currentUser  != null){
            if(UserInfo.getName()!= null) { str = str.replace('{!User.Name}', UserInfo.getName() ); }else{str = str.replace('{!User.Name}', ' ');}
            if(currentUser.Title!= null) { str = str.replace('{!User.Title}', currentUser.Title );}else{str = str.replace('{!User.Title}', ' ' );}
            if(currentUser.phone!= null) { str = str.replace('{!User.Phone}', currentUser.phone );}else{str = str.replace('{!User.Phone}', ' ');}
            if(UserInfo.getUserEmail()!= null) { str = str.replace('{!User.Email}', UserInfo.getUserEmail() );}else{str = str.replace('{!User.Email}', ' ' );}
        }
        return str;
    }
    
    public String setRecipientFields(String str, String salutation, String name){
        String result = 'Liebe Frau /Lieber Herr ';
        if( salutation != null && salutation.contains ('Herr') ){
            result = 'Lieber ' + salutation + ' ';
        }
        if( salutation != null && salutation.contains ('Frau') ){
            result = 'Liebe ' + salutation + ' ';
        }
        result += name;
        str = str.replace('<p id="recipient"/>', result);
        return str;
    }
    
    public PageReference backToContact(){
        if(primaryContact.id != null) {
            PageReference pageRef = new PageReference('/'+ primaryContact.id);
            pageRef.setRedirect(true);
            return pageRef;
        }
        else{
            return null;
        }
    }
    
    public boolean getenableNextButton() {
        return enableNextButton;
    }
    
    public boolean getenableSendEmail() {
        return enableSendEmail;
    }
    
    public boolean isOwner(Id opportunityId){
        if(formOpp == null || formOpp.Id != opportunityId){
            queryOpportunity(opportunityId);
        }
        if(formOpp.Owner.Id != UserInfo.getUserId()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ownerError ));
            enableNextButton = false;
            return False;
        }
        return True;
    }
    
    public void queryOpportunity(Id opportunityId){
        List<opportunity> oppList = [select Id, 
                                     Owner.Id, 
                                     Partner_darf_Infomaterial_senden__c, 
                                     Partner_darf_sich_telefonisch_melden__c,
                                     Partner_kann_per_E_Mail_kontaktieren__c,
                                     ASP_PB_Einwilligungserkl_rung__c, 
                                     Kategorie__c,
                                     StageName,
                                     Account.id, 
                                     Account.Familien_Name__c, 
                                     Produkt_Kategorie__c,
                                     DesiredAdditionalServices__c,
                                     Opportunity_Nummer__c
                                     from opportunity where id = :opportunityId limit 1];
        if(oppList != null && oppList.size()>0){
            formOpp = oppList[0];
        }
    }
    
    public void saveOpportunity(){
        try{
            update formOpp;
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage() ));
        }
    }     
}