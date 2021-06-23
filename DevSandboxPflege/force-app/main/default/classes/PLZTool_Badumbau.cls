/*********************************************************************************************************************************************
// Created 15.03.2018 by MZ
//                      Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                      Nordkanalstraße 58
//                      20097  Hamburg 
//                      Tel.:  0423882986
//                      Fax.:  0423882986
//                      Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Description:    
//    #155510105 - Bad goes Salesforce.com
//    to separate the "Badumbau" special functionalities of PLZ_Tool
//
//********************************************************************************************************************************************
//  test method:
//  PLZTool_Basis_test.badumbau_Test
//********************************************************************************************************************************************
//  Changes:
//********************************************************************************************************************************************
*/

public class PLZTool_Badumbau{
    public Id opportunityId {get;set;}
    public Map <Id, PLZTool_PartnerProduct_Badumbau> BadumbauPartnerMap{get;set;}
    public Set<Id> BadumbauPartnerMapKeys;
    
	public PLZTool_Badumbau(Opportunity opp, List<PLZTool_PartnerProduct> partnerProductList) {
        opportunityId = opp.Id;
        fillInBadumbauPartnerMap(opp, partnerProductList);
    }
    
    // different product list should be created based on opportunity fields "Produkt" and "Gewünschte Zusatzleistungen"
    public void fillInBadumbauPartnerMap(Opportunity opp, List<PLZTool_PartnerProduct> partnerProductList){
        Set<String> oppProductSet = new Set<String>();
        if(!String.isEmpty(opp.Produkt_Kategorie__c) ){
            oppProductSet = new Set<String> (opp.Produkt_Kategorie__c.split(';'));
        }
        Set<String> oppAdditionalServiceSet = new Set<String>();
        if(!String.isEmpty(opp.DesiredAdditionalServices__c)){
            oppAdditionalServiceSet = new Set<String>(opp.DesiredAdditionalServices__c.split(';'));
        }
        
        BadumbauPartnerMap = new Map<Id, PLZTool_PartnerProduct_Badumbau>();
        for(PLZTool_PartnerProduct prod : partnerProductList){
            PLZTool_PartnerProduct_Badumbau item = new PLZTool_PartnerProduct_Badumbau();
            if(BadumbauPartnerMap.containsKey(prod.pp.partner__c)){
                item = BadumbauPartnerMap.get(prod.pp.partner__c);
            }else{
                item.setPartnerInfo(prod.pp.partner__c);
            }
            
            // check product type to fill-in different products list 
            if(prod.pp.ProduktType__c == 'Produkt'){
                if(oppProductSet.contains(prod.pp.Produktgruppe__c)){
                    item.matchedMainProducts.add(prod);
                }//else{
                    //item.optionalMainProducts.add(prod);
                //}
            }else{
                if(oppAdditionalServiceSet.contains(prod.pp.Produktgruppe__c)){
                    item.matchedAdditionalServices.add(prod);
                }else{
                    item.optionalAdditionalServices.add(prod);
                }
            }
            BadumbauPartnerMap.put(prod.pp.partner__c, item);
            
        }
        
        for(PLZTool_PartnerProduct_Badumbau ppb : BadumbauPartnerMap.values()){
            ppb.setTicketProduct();
        }
    }
    
    public void keepSelected(){
    }
    
        
    public Set<Id> getBadumbauPartnerMapKeys() {
        return BadumbauPartnerMap!= null ? BadumbauPartnerMap.keySet() :new Set<Id>() ;
    }
    
    public class PLZTool_PartnerProduct_Badumbau{
        public boolean selected{get; set;}
        
        public Account partner{get; set;}
        
        // if partner has no open "kontingent", it should appear in the list but user can not select it.
        public boolean disabled{get; set;}
        
        // the product which is used to create ticket based on that. to be consistent in creating tickets in plz-tool
        public PLZTool_PartnerProduct ticketProduct{get; set;} 
        
        // all main products in the PB area which are not in "matchedMainProducts" list
        //public List<PLZTool_PartnerProduct> optionalMainProducts{get; set;}
        
        // products in PB area which match opportunity product
        public List<PLZTool_PartnerProduct> matchedMainProducts{get; set;}
        
        // all additional services(products) in PB area which are not in "matchedAdditionalServices" list
        public List<PLZTool_PartnerProduct> optionalAdditionalServices{get; set;}
        
        // services in PB area which match opportunity additional services 
        public List<PLZTool_PartnerProduct> matchedAdditionalServices{get; set;}
        
        public PLZTool_PartnerProduct_Badumbau(){
            selected = false;
            disabled = false;
            //optionalMainProducts = new List<PLZTool_PartnerProduct>();
            matchedMainProducts = new List<PLZTool_PartnerProduct>();
            optionalAdditionalServices = new List<PLZTool_PartnerProduct>();
            matchedAdditionalServices = new List<PLZTool_PartnerProduct>();
            
        }
        
        public void setPartnerInfo(Id partnerId){
            List<account> partnerList = [select id, 
                                         name, 
                                         Kontingent_offen_Partner_pro_Tag__c, 
                                         Kontingent_offen_Partner__c, 
                                         Kontingent_offen_Partner_pro_Monat__c
                                         from Account 
                                         where Id = :partnerId
                                         limit 1
                                        ];
            if(partnerList != null && partnerList.size()>0){
                this.partner = partnerList[0];
//                disablePartner();
            }
            
        }
        
        // if partner has no open "kontingent", it should appear in the list but user can not select it.
        private void disablePartner(){
            disabled = false;
            if((partner.Kontingent_offen_Partner_pro_Tag__c != null && partner.Kontingent_offen_Partner_pro_Tag__c <= 0) ||
               (partner.Kontingent_offen_Partner__c != null && partner.Kontingent_offen_Partner__c <= 0) ||
               (partner.Kontingent_offen_Partner_pro_Monat__c != null && partner.Kontingent_offen_Partner_pro_Monat__c <= 0)){
                disabled = true;
            }
        }
        
        // plz-tool works with partner product to create partner ticket. and always at least one product should be selected. 
        // to avoid changing plz-tool, one product is stored in "ticketProduct" variable.
        private void setTicketProduct(){
            if(matchedMainProducts != null && matchedMainProducts.size()>0){
                ticketProduct = matchedMainProducts[0];
            }//else if(optionalMainProducts != null && optionalMainProducts.size()>0){
                //ticketProduct = optionalMainProducts[0];
            //}
        else if(matchedAdditionalServices != null && matchedAdditionalServices.size()>0){
                ticketProduct = matchedAdditionalServices[0];
            }else if(optionalAdditionalServices != null && optionalAdditionalServices.size()>0){
                ticketProduct = optionalAdditionalServices[0];
            }
            
        }
    }
	
}