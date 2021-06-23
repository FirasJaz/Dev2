public class PLZTool_PartnerProduct{
    public boolean selected{get; set;}
    public Partner_Produkte__c pp;
    public Partner_Preise__c prc;
    public String comment{get; set;}
    public boolean disabled{get; set;}
    
    
    public PLZTool_PartnerProduct(Partner_Produkte__c pp, boolean selected){
        this.pp = pp;
        this.selected = selected;
        this.disabled = false;
        //this.setPrice();
    }
    
    public static Map<Id, PLZTool_PartnerProduct> setPrice_queryEachProduct(Map<Id, PLZTool_PartnerProduct> pMap){
        Map<Id, Integer> ticketsCountMap = new Map<Id, Integer>();
        list<AggregateResult> ptList = [SELECT Partner_Produkt__c, COUNT(id) cnt 
                    FROM Partner_Ticket__c 
                    WHERE Partner_Produkt__c IN : pMap.keySet()
                    and Status_CPL__c = :PLZTool_Basis.ptStatusAbrechenbar
                    GROUP BY Partner_Produkt__c];
        if(ptList != null && ptList.size()>0) {
            for(AggregateResult ar : ptList) {
                integer ticketsCount = (integer)ar.get('cnt');
                id ppId = (id)ar.get('Partner_Produkt__c');
                ticketsCountMap.put(ppId, ticketsCount);
            }
        }
        for(Id ppId : pMap.keySet()){
            integer amountForPriceLevel = 1;
            if(ticketsCountMap.containsKey(ppId)){
                amountForPriceLevel = ticketsCountMap.get(ppId) + 1;
            }
            List<Partner_Preise__c> prclist = [select Id, CPL_Exklusiv__c, CPL_Kat_1__c, CPL_Kat_2__c, CPO_Exklusiv_Festpreis__c, CPO_Exklusiv_Prozentual__c, 
                    CPO_Kat_1_Festpreis__c, CPO_Kat_1_Prozentual__c, CPO_Kat_2_Festpreis__c, CPO_Kat_2_Prozentual__c, preis_gueltig_ab_Menge__c 
                    from Partner_Preise__c where preis_gueltig_ab_Menge__c  <= : amountForPriceLevel and Partner_Produkt__c  = : ppId order by preis_gueltig_ab_Menge__c desc Nulls last limit 1];
            if( prclist != null && prclist.size()> 0){
                pMap.get(ppId).prc = prclist[0];
            }else{
                pMap.get(ppId).prc = new Partner_Preise__c();
            }
        }
        return pMap;
    }
    
    public static Map<Id, PLZTool_PartnerProduct> setPrice(Map<Id, PLZTool_PartnerProduct> pMap){
        Set<Id> productsWithPricingLevel = new Set<Id>();
        list<AggregateResult> priceList = [SELECT Partner_Produkt__c, COUNT(id) cnt 
                    FROM Partner_Preise__c 
                    WHERE Partner_Produkt__c IN : pMap.keySet()
                    GROUP BY Partner_Produkt__c];
        if(priceList != null && priceList.size()>0){
            for(AggregateResult ar : priceList) {
                integer priceCount = (integer)ar.get('cnt');
                if(priceCount > 1){
                    id ppId = (id)ar.get('Partner_Produkt__c');
                    productsWithPricingLevel.add(ppId);
                }
            }
        }
        
        Set<Id> productsWithoutPricingLevel = new Set<Id>();
        for(Id ppId : pMap.keySet()){
            if(! productsWithPricingLevel.contains(ppId)){
                productsWithoutPricingLevel.add(ppId);
                pMap.get(ppId).prc = new Partner_Preise__c();
            }
        }
        
        if(productsWithPricingLevel != null && productsWithPricingLevel.size()>0){
            Map<Id, Integer> ticketsCountMap = new Map<Id, Integer>();
            list<AggregateResult> ptList = [SELECT Partner_Produkt__c, COUNT(id) cnt 
                        FROM Partner_Ticket__c 
                        WHERE Partner_Produkt__c IN : productsWithPricingLevel
                        and Status_CPL__c = :PLZTool_Basis.ptStatusAbrechenbar
                        GROUP BY Partner_Produkt__c];
            if(ptList != null && ptList.size()>0) {
                for(AggregateResult ar : ptList) {
                    integer ticketsCount = (integer)ar.get('cnt');
                    id ppId = (id)ar.get('Partner_Produkt__c');
                    ticketsCountMap.put(ppId, ticketsCount);
                }
            }
            for(Id ppId : productsWithPricingLevel){
                integer amountForPriceLevel = 1;
                if(ticketsCountMap.containsKey(ppId)){
                    amountForPriceLevel = ticketsCountMap.get(ppId) + 1;
                }
                List<Partner_Preise__c> prclist = [select Id, CPL_Exklusiv__c, CPL_Kat_1__c, CPL_Kat_2__c, CPO_Exklusiv_Festpreis__c, CPO_Exklusiv_Prozentual__c, 
                        CPO_Kat_1_Festpreis__c, CPO_Kat_1_Prozentual__c, CPO_Kat_2_Festpreis__c, CPO_Kat_2_Prozentual__c, preis_gueltig_ab_Menge__c, Partner_Produkt__c  
                        from Partner_Preise__c where preis_gueltig_ab_Menge__c  <= : amountForPriceLevel and Partner_Produkt__c  = : ppId order by preis_gueltig_ab_Menge__c desc Nulls last limit 1];
                if( prclist != null && prclist.size()> 0){
                    pMap.get(ppId).prc = prclist[0];
                }else{
                    pMap.get(ppId).prc = new Partner_Preise__c();
                }
            }
        }
        
        List<Partner_Preise__c> prclist = [select Id, CPL_Exklusiv__c, CPL_Kat_1__c, CPL_Kat_2__c, CPO_Exklusiv_Festpreis__c, CPO_Exklusiv_Prozentual__c, 
                    CPO_Kat_1_Festpreis__c, CPO_Kat_1_Prozentual__c, CPO_Kat_2_Festpreis__c, CPO_Kat_2_Prozentual__c, preis_gueltig_ab_Menge__c, Partner_Produkt__c  
                    from Partner_Preise__c where Partner_Produkt__c  IN : productsWithoutPricingLevel];
        
        for( Partner_Preise__c price : prclist){
            pMap.get(price.Partner_Produkt__c).prc = price;
        }
        
        return pMap;
    }
    
    public void setPrice(){
        Integer ticketsCount = [select count() from Partner_Ticket__c where Partner_Produkt__c = :pp.Id and Status_CPL__c = :PLZTool_Basis.ptStatusAbrechenbar ];
        ticketsCount ++;
        List<Partner_Preise__c> prclist = [select Id, CPL_Exklusiv__c, CPL_Kat_1__c, CPL_Kat_2__c, CPO_Exklusiv_Festpreis__c, CPO_Exklusiv_Prozentual__c, 
                            CPO_Kat_1_Festpreis__c, CPO_Kat_1_Prozentual__c, CPO_Kat_2_Festpreis__c, CPO_Kat_2_Prozentual__c, preis_gueltig_ab_Menge__c 
                            from Partner_Preise__c where preis_gueltig_ab_Menge__c  <= :ticketsCount and Partner_Produkt__c  = :pp.Id order by preis_gueltig_ab_Menge__c desc Nulls last limit 1];
        if( prclist != null && prclist.size()> 0){
            this.prc = prclist[0];
        }else{
            this.prc = new Partner_Preise__c();
        }
    }
    
    public Partner_Produkte__c getPp() {                        
        return pp;
    } 
    
    public Partner_Preise__c getPrc() {                        
        return prc;
    }
    
     
    public String getXCPL_Kategorie_1(){
        if(prc != null && prc.CPL_Kat_1__c != null){
         return 'CPL 1';
        }
        return '';
    }   
      
    public String XCPL_Exklusiv {
        get {
        if(prc != null && prc.CPL_Exklusiv__c != null){
         return 'CPL Ex';
        }
        return '';
        }
        set;
    }
    public boolean CPL_Exklusiv {
        get {
        if(prc != null && prc.CPL_Exklusiv__c != null){
         return true;
        }
        return false;
        }
        set;
    }
    
    public boolean CPO_Exclusiv {
        get {
        if(prc != null && ( prc.CPO_Exklusiv_Festpreis__c != null || prc.CPO_Exklusiv_Prozentual__c != null)){
         return true;
        }
        return false;
        }
        set;
    }
    
    public String getXCPL_Kategorie_2(){
        if(prc != null && prc.CPL_Kat_2__c != null){
         return 'CPL 2';
        }
        return '';
    }
    public String getXCPO_Exclusiv(){
        if(prc != null && (prc.CPO_Exklusiv_Festpreis__c != null || prc.CPO_Exklusiv_Prozentual__c != null)){
         return 'CPO Ex';
        }
        return '';
    }
    
    public String getXCPO_Kategorie_1(){
        if(prc != null && (prc.CPO_Kat_1_Festpreis__c != null || prc.CPO_Kat_1_Prozentual__c != null)){
         return 'CPO 1';
        }
        return '';
    }
    
    public String getXCPO_Kategorie_2(){
        if(prc != null && (prc.CPO_Kat_2_Festpreis__c != null || prc.CPO_Kat_2_Prozentual__c != null)){
         return 'CPO 2';
        }
        return '';
    }
    
    public String getCplCpo(){
        String result = '';
        if(getXCPL_Kategorie_1()!= ''){
            result += getXCPL_Kategorie_1()+';';
        }
        if(XCPL_Exklusiv!= ''){
            result += XCPL_Exklusiv+';';
        }
        if(getXCPL_Kategorie_2()!= ''){
            result += getXCPL_Kategorie_2()+';';
        }
        if(getXCPO_Kategorie_1()!= ''){
            result += getXCPO_Kategorie_1()+';';
        }
        if(getXCPO_Exclusiv()!= ''){
            result += getXCPO_Exclusiv()+';';
        }
        if(getXCPO_Kategorie_2()!= ''){
            result += getXCPO_Kategorie_2()+';';
        }
        if(result.length()>2){
            result = result.substring(0, result.length()-1);
        }
        return  result;
    }
    
}