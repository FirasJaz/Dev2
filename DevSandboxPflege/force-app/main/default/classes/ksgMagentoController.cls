@RestResource(urlMapping='/magentoshop/*')
global class ksgMagentoController {
 // http://s15-pflegede.cs81.force.com/magentoshop
 
    global List<Lines> lines {get;set;} 
    
    @HttpPost 
    global static string createNewLead( String order_id, 
                                        String increment_id,
                                        String status, 
                                        Customer customer, 
                                        Shipping_address shipping_address, 
                                        Billing_address billing_address, 
                                        Order order,
                                        Payment payment,
                                        Lines[] lines) {
        string ret = 'OK';                                  
        id rtid = null;                                
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name = 'Shop'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        lead l = new lead(company = 'Magento Shop', Status='Open');
        l.RecordTypeId = rtid;
        l.magento_increment_id__c = increment_id;
        l.magento_order_id__c = order_id;
        
        if(customer != null) {
            l.Salutation = customer.customer_prefix;
            l.lastname = customer.customer_lastname;
            l.firstname = customer.customer_firstname;
            l.email = customer.customer_email; 
            l.magento_kundennummer__c = customer.customer_id;
            l.Fax = customer.customer_fax;
            l.Phone = customer.customer_telephone;
        }
        if(shipping_address != null) {
            l.shipping_firstname__c = shipping_address.shipping_firstname;
            l.shipping_lastname__c = shipping_address.shipping_lastname;
            l.shipping_street__c = shipping_address.shipping_street;
            l.shipping_postal_code__c = shipping_address.shipping_postcode;
            l.shipping_city__c = shipping_address.shipping_city;
            l.shipping_country__c = shipping_address.shipping_country_id;                   
        }
        
        if(billing_address != null) {
            l.billing_firstname__c = billing_address.billing_firstname;
            l.billing_lastname__c = billing_address.billing_lastname;
            l.billing_street__c = billing_address.billing_street;
            l.billing_postal_code__c = billing_address.billing_postcode;
            l.billing_city__c = billing_address.billing_city;
            l.billing_country__c = billing_address.billing_country_id;          
        }
        
        if(order != null) {
            l.magento_total_amount__c = order.total_amount;
            l.magento_discount_amount__c = order.discount_amount;
            l.magento_shipping_amount__c = order.shipping_amount;
            l.magento_grand_total__c = order.grand_total;
            l.magento_tax_amount_01__c = order.tax_amount_01;
            l.magento_tax_amount_02__c = order.tax_amount_02;           
        } 
        
        if(payment != null) {
            l.Magento_payment_method__c = payment.payment_method;
            l.magento_payment_status__c = payment.payment_status;
            l.magent_payment_id__c = payment.payment_id;
        }       

        try {
            insert l;
            }
        catch (System.Exception e) {}
        
        if(l.id != null ) {        
            list<Lead_Position__c> lpList = new list<Lead_Position__c>(); 
            if(lines != null) {
                for(integer i = 0; i < lines.size(); i++) {
                    Lead_Position__c lp = new Lead_Position__c(Lead__c = l.id);
                    lp.Order_Id__c = order_id;
                    lp.name__c = lines[i].name;
                    lp.item_Id__c = lines[i].item_id;
                    lp.Price__c = lines[i].price;
                    lp.Qty_Ordered__c = lines[i].qty_ordered;
                    lp.amount__c = lines[i].amount;
                    lp.EAN__c = lines[i].ean;
                    lp.Tax_Percent__c = lines[i].tax_percent;
                    lp.line_no__c = lines[i].line_no;
                    lp.discount_amount__c = lines[i].discount_amount;
                    lp.discount_percent__c = lines[i].discount_percent;
                    lp.grand_amount__c = lines[i].grand_amount;
                    lp.tax_amount__c = lines[i].tax_amount;
                    lpList.add(lp);
                }
                try {
                    insert lpList;
                }
                catch(System.Exception e) {}
            }
        }
        return ret;
    }
    
    global class Customer {
        global String customer_prefix {get;set;} 
        global String customer_firstname {get;set;} 
        global String customer_lastname {get;set;} 
        global String customer_email {get;set;} 
        global String customer_telephone {get;set;} 
        global String customer_fax {get;set;}
        global String customer_id {get; set;}
    }
    
    global class Billing_address {
        global String billing_firstname {get;set;} 
        global String billing_lastname {get;set;} 
        global String billing_street {get;set;} 
        global String billing_postcode {get;set;} 
        global String billing_city {get;set;} 
        global String billing_country_id {get;set;}
    }

    global class Shipping_address {
        global String shipping_firstname {get;set;} 
        global String shipping_lastname {get;set;} 
        global String shipping_street {get;set;} 
        global String shipping_postcode {get;set;} 
        global String shipping_city {get;set;} 
        global String shipping_country_id {get;set;} 
    }
    
    global class Order {
        global String total_amount {get;set;} 
        global String discount_amount {get;set;} 
        global String shipping_amount {get;set;} 
        global String grand_total {get;set;} 
        global String tax_amount_01 {get;set;} 
        global String tax_amount_02 {get;set;} 
    }
    
    global class Lines {
        global String line_no {get;set;} 
        global String ean {get;set;} 
        global String name {get;set;} 
        global String qty_ordered {get;set;} 
        global String price {get;set;} 
        global String amount {get;set;} 
        global String discount_amount {get;set;} 
        global String discount_percent {get;set;} 
        global String grand_amount {get;set;} 
        global String item_id {get;set;} 
        global String tax_percent {get;set;} 
        global String tax_amount {get;set;} 
    }   

    global class Payment {
        global String payment_method {get;set;} 
        global String payment_status {get;set;} 
        global String payment_id {get;set;}
    }       
 
}