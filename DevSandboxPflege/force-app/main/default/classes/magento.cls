/*
// 09.10.2015  durch wds  Eingefügt an zwei Stellen IS_salesforce_read 
// 9.10.15 wds
- Port.endpoint_x geändert
- salesOrderItemEntity.producttype hinzugefügt und salesOrderItemEntity.ean_type_info, da sonst Fehler:

    15:59:38.556 (4556081098)|EXCEPTION_THROWN|[910]|System.CalloutException: Web service callout failed: Unable to parse callout response. Apex type not found for element producttype
    15:59:38.556 (4556240263)|SYSTEM_METHOD_EXIT|[910]|WebServiceCallout.invoke(APEX_OBJECT, APEX_OBJECT, Map, List)
    15:59:38.556 (4556258911)|METHOD_EXIT|[93]|01p260000004kbD|magento.Port.salesOrderInfo(String, String)
    15:59:38.556 (4556270294)|SYSTEM_MODE_EXIT|false
    15:59:38.556 (4556346837)|FATAL_ERROR|System.CalloutException: Web service callout failed: Unable to parse callout response. Apex type not found for element producttype
    
    Class.magento.Port.salesOrderInfo: line 910, column 1
    Class.invoke_magento.createLead: line 93, column 1
    15:59:38.556 (4556360312)|CODE_UNIT_FINISHED|invoke_magento invoke(createLead)
*/ 
public class magento {

    public class filters {
        public magento.associativeArray filter;
        public magento.complexFilterArray complex_filter;
        private String[] filter_type_info = new String[]{'filter','urn:Magento',null,'0','1','false'};
        private String[] complex_filter_type_info = new String[]{'complex_filter','urn:Magento',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'filter','complex_filter'};
    }

    public class associativeArray {
        public magento.associativeEntity[] complexObjectArray;
        private String[] complexObjectArray_type_info = new String[]{'complexObjectArray','urn:Magento',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'complexObjectArray'};
    }

    public class complexFilterArray {
        public magento.complexFilter[] complexObjectArray;
        private String[] complexObjectArray_type_info = new String[]{'complexObjectArray','urn:Magento',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'complexObjectArray'};
    }
    
    public class complexFilter {
        public String key;
        public magento.associativeEntity value;
        private String[] key_type_info = new String[]{'key','urn:Magento',null,'1','1','false'};
        private String[] value_type_info = new String[]{'value','urn:Magento',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'key','value'};
    }
    
    public class associativeEntity {
        public String key;
        public String value;
        private String[] key_type_info = new String[]{'key','urn:Magento',null,'1','1','false'};
        private String[] value_type_info = new String[]{'value','urn:Magento',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'key','value'};
    }
    
    public class salesOrderItemEntityArray {
        public magento.salesOrderItemEntity[] complexObjectArray;
        private String[] complexObjectArray_type_info = new String[]{'complexObjectArray','urn:Magento',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'complexObjectArray'};
    }
    
    public class salesOrderItemEntity {
        public String item_id;
        public String order_id;
        public String quote_item_id;
        public String created_at;
        public String updated_at;
        public String product_id;
        public String product_type;
        public String producttype;
        public String product_options;
        public String weight;
        public String is_virtual;
        public String sku;
        public String ean;
        public String name;
        public String applied_rule_ids;
        public String free_shipping;
        public String is_qty_decimal;
        public String no_discount;
        public String qty_canceled;
        public String qty_invoiced;
        public String qty_ordered;
        public String qty_refunded;
        public String qty_shipped;
        public String cost;
        public String price;
        public String base_price;
        public String original_price;
        public String base_original_price;
        public String tax_percent;
        public String tax_amount;
        public String base_tax_amount;
        public String tax_invoiced;
        public String base_tax_invoiced;
        public String discount_percent;
        public String discount_amount;
        public String base_discount_amount;
        public String discount_invoiced;
        public String base_discount_invoiced;
        public String amount_refunded;
        public String base_amount_refunded;
        public String row_total;
        public String base_row_total;
        public String row_invoiced;
        public String base_row_invoiced;
        public String row_weight;
        public String gift_message_id;
        public String gift_message;
        public String gift_message_available;
        public String base_tax_before_discount;
        public String tax_before_discount;
        public String weee_tax_applied;
        public String weee_tax_applied_amount;
        public String weee_tax_applied_row_amount;
        public String base_weee_tax_applied_amount;
        public String base_weee_tax_applied_row_amount;
        public String weee_tax_disposition;
        public String weee_tax_row_disposition;
        public String base_weee_tax_disposition;
        public String base_weee_tax_row_disposition;
  
        private String[] item_id_type_info = new String[]{'item_id','urn:Magento',null,'0','1','false'};
        private String[] order_id_type_info = new String[]{'order_id','urn:Magento',null,'0','1','false'};
        private String[] quote_item_id_type_info = new String[]{'quote_item_id','urn:Magento',null,'0','1','false'};
        private String[] created_at_type_info = new String[]{'created_at','urn:Magento',null,'0','1','false'};
        private String[] updated_at_type_info = new String[]{'updated_at','urn:Magento',null,'0','1','false'};
        private String[] product_id_type_info = new String[]{'product_id','urn:Magento',null,'0','1','false'};
        private String[] product_type_type_info = new String[]{'product_type','urn:Magento',null,'0','1','false'};
        private String[] producttype_type_info = new String[]{'producttype','urn:Magento',null,'0','1','false'};
        private String[] product_options_type_info = new String[]{'product_options','urn:Magento',null,'0','1','false'};
        private String[] weight_type_info = new String[]{'weight','urn:Magento',null,'0','1','false'};
        private String[] is_virtual_type_info = new String[]{'is_virtual','urn:Magento',null,'0','1','false'};
        private String[] sku_type_info = new String[]{'sku','urn:Magento',null,'0','1','false'};
        private String[] ean_type_info = new String[]{'ean','urn:Magento',null,'0','1','false'};
        private String[] name_type_info = new String[]{'name','urn:Magento',null,'0','1','false'};
        private String[] applied_rule_ids_type_info = new String[]{'applied_rule_ids','urn:Magento',null,'0','1','false'};
        private String[] free_shipping_type_info = new String[]{'free_shipping','urn:Magento',null,'0','1','false'};
        private String[] is_qty_decimal_type_info = new String[]{'is_qty_decimal','urn:Magento',null,'0','1','false'};
        private String[] no_discount_type_info = new String[]{'no_discount','urn:Magento',null,'0','1','false'};
        private String[] qty_canceled_type_info = new String[]{'qty_canceled','urn:Magento',null,'0','1','false'};
        private String[] qty_invoiced_type_info = new String[]{'qty_invoiced','urn:Magento',null,'0','1','false'};
        private String[] qty_ordered_type_info = new String[]{'qty_ordered','urn:Magento',null,'0','1','false'};
        private String[] qty_refunded_type_info = new String[]{'qty_refunded','urn:Magento',null,'0','1','false'};
        private String[] qty_shipped_type_info = new String[]{'qty_shipped','urn:Magento',null,'0','1','false'};
        private String[] cost_type_info = new String[]{'cost','urn:Magento',null,'0','1','false'};
        private String[] price_type_info = new String[]{'price','urn:Magento',null,'0','1','false'};
        private String[] base_price_type_info = new String[]{'base_price','urn:Magento',null,'0','1','false'};
        private String[] original_price_type_info = new String[]{'original_price','urn:Magento',null,'0','1','false'};
        private String[] base_original_price_type_info = new String[]{'base_original_price','urn:Magento',null,'0','1','false'};
        private String[] tax_percent_type_info = new String[]{'tax_percent','urn:Magento',null,'0','1','false'};
        private String[] tax_amount_type_info = new String[]{'tax_amount','urn:Magento',null,'0','1','false'};
        private String[] base_tax_amount_type_info = new String[]{'base_tax_amount','urn:Magento',null,'0','1','false'};
        private String[] tax_invoiced_type_info = new String[]{'tax_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_tax_invoiced_type_info = new String[]{'base_tax_invoiced','urn:Magento',null,'0','1','false'};
        private String[] discount_percent_type_info = new String[]{'discount_percent','urn:Magento',null,'0','1','false'};
        private String[] discount_amount_type_info = new String[]{'discount_amount','urn:Magento',null,'0','1','false'};
        private String[] base_discount_amount_type_info = new String[]{'base_discount_amount','urn:Magento',null,'0','1','false'};
        private String[] discount_invoiced_type_info = new String[]{'discount_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_discount_invoiced_type_info = new String[]{'base_discount_invoiced','urn:Magento',null,'0','1','false'};
        private String[] amount_refunded_type_info = new String[]{'amount_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_amount_refunded_type_info = new String[]{'base_amount_refunded','urn:Magento',null,'0','1','false'};
        private String[] row_total_type_info = new String[]{'row_total','urn:Magento',null,'0','1','false'};
        private String[] base_row_total_type_info = new String[]{'base_row_total','urn:Magento',null,'0','1','false'};
        private String[] row_invoiced_type_info = new String[]{'row_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_row_invoiced_type_info = new String[]{'base_row_invoiced','urn:Magento',null,'0','1','false'};
        private String[] row_weight_type_info = new String[]{'row_weight','urn:Magento',null,'0','1','false'};
        private String[] gift_message_id_type_info = new String[]{'gift_message_id','urn:Magento',null,'0','1','false'};
        private String[] gift_message_type_info = new String[]{'gift_message','urn:Magento',null,'0','1','false'};
        private String[] gift_message_available_type_info = new String[]{'gift_message_available','urn:Magento',null,'0','1','false'};
        private String[] base_tax_before_discount_type_info = new String[]{'base_tax_before_discount','urn:Magento',null,'0','1','false'};
        private String[] tax_before_discount_type_info = new String[]{'tax_before_discount','urn:Magento',null,'0','1','false'};
        private String[] weee_tax_applied_type_info = new String[]{'weee_tax_applied','urn:Magento',null,'0','1','false'};
        private String[] weee_tax_applied_amount_type_info = new String[]{'weee_tax_applied_amount','urn:Magento',null,'0','1','false'};
        private String[] weee_tax_applied_row_amount_type_info = new String[]{'weee_tax_applied_row_amount','urn:Magento',null,'0','1','false'};
        private String[] base_weee_tax_applied_amount_type_info = new String[]{'base_weee_tax_applied_amount','urn:Magento',null,'0','1','false'};
        private String[] base_weee_tax_applied_row_amount_type_info = new String[]{'base_weee_tax_applied_row_amount','urn:Magento',null,'0','1','false'};
        private String[] weee_tax_disposition_type_info = new String[]{'weee_tax_disposition','urn:Magento',null,'0','1','false'};
        private String[] weee_tax_row_disposition_type_info = new String[]{'weee_tax_row_disposition','urn:Magento',null,'0','1','false'};
        private String[] base_weee_tax_disposition_type_info = new String[]{'base_weee_tax_disposition','urn:Magento',null,'0','1','false'};
        private String[] base_weee_tax_row_disposition_type_info = new String[]{'base_weee_tax_row_disposition','urn:Magento',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'item_id','order_id','quote_item_id','created_at','updated_at','product_id','product_type','product_options','weight','is_virtual','sku','name','applied_rule_ids','free_shipping','is_qty_decimal','no_discount','qty_canceled','qty_invoiced','qty_ordered','qty_refunded','qty_shipped','cost','price','base_price','original_price','base_original_price','tax_percent','tax_amount','base_tax_amount','tax_invoiced','base_tax_invoiced','discount_percent','discount_amount','base_discount_amount','discount_invoiced','base_discount_invoiced','amount_refunded','base_amount_refunded','row_total','base_row_total','row_invoiced','base_row_invoiced','row_weight','gift_message_id','gift_message','gift_message_available','base_tax_before_discount','tax_before_discount','weee_tax_applied','weee_tax_applied_amount','weee_tax_applied_row_amount','base_weee_tax_applied_amount','base_weee_tax_applied_row_amount','weee_tax_disposition','weee_tax_row_disposition','base_weee_tax_disposition','base_weee_tax_row_disposition'};
    }
    
    public class salesOrderListRequestParam_element {
        public String sessionId;
        public magento.filters filters;
        private String[] sessionId_type_info = new String[]{'sessionId','urn:Magento',null,'1','1','false'};
        private String[] filters_type_info = new String[]{'filters','urn:Magento',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'sessionId','filters'};
    }    
    
    public class salesOrderListResponseParam_element {
        public magento.salesOrderListEntityArray result;
        private String[] result_type_info = new String[]{'result','urn:Magento',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    public class salesOrderListEntityArray {
        public magento.salesOrderListEntity[] complexObjectArray;
        private String[] complexObjectArray_type_info = new String[]{'complexObjectArray','urn:Magento',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'complexObjectArray'};
    }

    public class salesOrderListEntity {
        public String increment_id;
        public String store_id;
        public String created_at;
        public String updated_at;
        public String customer_id;
        public String tax_amount;
        public String shipping_amount;
        public String discount_amount;
        public String subtotal;
        public String grand_total;
        public String total_paid;
        public String total_refunded;
        public String total_qty_ordered;
        public String total_canceled;
        public String total_invoiced;
        public String total_online_refunded;
        public String total_offline_refunded;
        public String base_tax_amount;
        public String base_shipping_amount;
        public String base_discount_amount;
        public String base_subtotal;
        public String base_grand_total;
        public String base_total_paid;
        public String base_total_refunded;
        public String base_total_qty_ordered;
        public String base_total_canceled;
        public String base_total_invoiced;
        public String base_total_online_refunded;
        public String base_total_offline_refunded;
        public String billing_address_id;
        public String billing_firstname;
        public String billing_lastname;
        public String shipping_address_id;
        public String shipping_firstname;
        public String shipping_lastname;
        public String billing_name;
        public String shipping_name;
        public String store_to_base_rate;
        public String store_to_order_rate;
        public String base_to_global_rate;
        public String base_to_order_rate;
        public String weight;
        public String store_name;
        public String remote_ip;
        public String status;
        public String state;
        public String applied_rule_ids;
        public String global_currency_code;
        public String base_currency_code;
        public String store_currency_code;
        public String order_currency_code;
        public String shipping_method;
        public String shipping_description;
        public String customer_email;
        public String customer_firstname;
        public String customer_lastname;
        public String quote_id;
        public String is_virtual;
        public String customer_group_id;
        public String customer_note_notify;
        public String customer_is_guest;
        public String email_sent;
        public String order_id;
        public String gift_message_id;
        public String coupon_code;
        public String protect_code;
        public String base_discount_canceled;
        public String base_discount_invoiced;
        public String base_discount_refunded;
        public String base_shipping_canceled;
        public String base_shipping_invoiced;
        public String base_shipping_refunded;
        public String base_shipping_tax_amount;
        public String base_shipping_tax_refunded;
        public String base_subtotal_canceled;
        public String base_subtotal_invoiced;
        public String base_subtotal_refunded;
        public String base_tax_canceled;
        public String base_tax_invoiced;
        public String base_tax_refunded;
        public String base_total_invoiced_cost;
        public String discount_canceled;
        public String discount_invoiced;
        public String discount_refunded;
        public String shipping_canceled;
        public String shipping_invoiced;
        public String shipping_refunded;
        public String shipping_tax_amount;
        public String shipping_tax_refunded;
        public String subtotal_canceled;
        public String subtotal_invoiced;
        public String subtotal_refunded;
        public String tax_canceled;
        public String tax_invoiced;
        public String tax_refunded;
        public String can_ship_partially;
        public String can_ship_partially_item;
        public String edit_increment;
        public String forced_do_shipment_with_invoice;
        public String payment_authorization_expiration;
        public String paypal_ipn_customer_notified;
        public String quote_address_id;
        public String adjustment_negative;
        public String adjustment_positive;
        public String base_adjustment_negative;
        public String base_adjustment_positive;
        public String base_shipping_discount_amount;
        public String base_subtotal_incl_tax;
        public String base_total_due;
        public String payment_authorization_amount;
        public String shipping_discount_amount;
        public String subtotal_incl_tax;
        public String total_due;
        public String customer_dob;
        public String customer_middlename;
        public String customer_prefix;
        public String customer_suffix;
        public String customer_taxvat;
        public String discount_description;
        public String ext_customer_id;
        public String ext_order_id;
        public String hold_before_state;
        public String hold_before_status;
        public String original_increment_id;
        public String relation_child_id;
        public String relation_child_real_id;
        public String relation_parent_id;
        public String relation_parent_real_id;
        public String x_forwarded_for;
        public String customer_note;
        public String total_item_count;
        public String customer_gender;
        public String hidden_tax_amount;
        public String base_hidden_tax_amount;
        public String shipping_hidden_tax_amount;
        public String base_shipping_hidden_tax_amount;
        public String hidden_tax_invoiced;
        public String base_hidden_tax_invoiced;
        public String hidden_tax_refunded;
        public String base_hidden_tax_refunded;
        public String shipping_incl_tax;
        public String base_shipping_incl_tax;
        public String base_customer_balance_amount;
        public String customer_balance_amount;
        public String base_customer_balance_invoiced;
        public String customer_balance_invoiced;
        public String base_customer_balance_refunded;
        public String customer_balance_refunded;
        public String base_customer_balance_total_refunded;
        public String customer_balance_total_refunded;
        public String gift_cards;
        public String base_gift_cards_amount;
        public String gift_cards_amount;
        public String base_gift_cards_invoiced;
        public String gift_cards_invoiced;
        public String base_gift_cards_refunded;
        public String gift_cards_refunded;
        public String reward_points_balance;
        public String base_reward_currency_amount;
        public String reward_currency_amount;
        public String base_reward_currency_amount_invoiced;
        public String reward_currency_amount_invoiced;
        public String base_reward_currency_amount_refunded;
        public String reward_currency_amount_refunded;
        public String reward_points_balance_refunded;
        public String reward_points_balance_to_refund;
        public String reward_salesrule_points;
        public String firstname;
        public String lastname;
        public String telephone;
        public String postcode;
        
        public String is_salesforce_read;
        private String[] increment_id_type_info = new String[]{'increment_id','urn:Magento',null,'0','1','false'};
        private String[] store_id_type_info = new String[]{'store_id','urn:Magento',null,'0','1','false'};
        private String[] created_at_type_info = new String[]{'created_at','urn:Magento',null,'0','1','false'};
        private String[] updated_at_type_info = new String[]{'updated_at','urn:Magento',null,'0','1','false'};
        private String[] customer_id_type_info = new String[]{'customer_id','urn:Magento',null,'0','1','false'};
        private String[] tax_amount_type_info = new String[]{'tax_amount','urn:Magento',null,'0','1','false'};
        private String[] shipping_amount_type_info = new String[]{'shipping_amount','urn:Magento',null,'0','1','false'};
        private String[] discount_amount_type_info = new String[]{'discount_amount','urn:Magento',null,'0','1','false'};
        private String[] subtotal_type_info = new String[]{'subtotal','urn:Magento',null,'0','1','false'};
        private String[] grand_total_type_info = new String[]{'grand_total','urn:Magento',null,'0','1','false'};
        private String[] total_paid_type_info = new String[]{'total_paid','urn:Magento',null,'0','1','false'};
        private String[] total_refunded_type_info = new String[]{'total_refunded','urn:Magento',null,'0','1','false'};
        private String[] total_qty_ordered_type_info = new String[]{'total_qty_ordered','urn:Magento',null,'0','1','false'};
        private String[] total_canceled_type_info = new String[]{'total_canceled','urn:Magento',null,'0','1','false'};
        private String[] total_invoiced_type_info = new String[]{'total_invoiced','urn:Magento',null,'0','1','false'};
        private String[] total_online_refunded_type_info = new String[]{'total_online_refunded','urn:Magento',null,'0','1','false'};
        private String[] total_offline_refunded_type_info = new String[]{'total_offline_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_tax_amount_type_info = new String[]{'base_tax_amount','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_amount_type_info = new String[]{'base_shipping_amount','urn:Magento',null,'0','1','false'};
        private String[] base_discount_amount_type_info = new String[]{'base_discount_amount','urn:Magento',null,'0','1','false'};
        private String[] base_subtotal_type_info = new String[]{'base_subtotal','urn:Magento',null,'0','1','false'};
        private String[] base_grand_total_type_info = new String[]{'base_grand_total','urn:Magento',null,'0','1','false'};
        private String[] base_total_paid_type_info = new String[]{'base_total_paid','urn:Magento',null,'0','1','false'};
        private String[] base_total_refunded_type_info = new String[]{'base_total_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_total_qty_ordered_type_info = new String[]{'base_total_qty_ordered','urn:Magento',null,'0','1','false'};
        private String[] base_total_canceled_type_info = new String[]{'base_total_canceled','urn:Magento',null,'0','1','false'};
        private String[] base_total_invoiced_type_info = new String[]{'base_total_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_total_online_refunded_type_info = new String[]{'base_total_online_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_total_offline_refunded_type_info = new String[]{'base_total_offline_refunded','urn:Magento',null,'0','1','false'};
        private String[] billing_address_id_type_info = new String[]{'billing_address_id','urn:Magento',null,'0','1','false'};
        private String[] billing_firstname_type_info = new String[]{'billing_firstname','urn:Magento',null,'0','1','false'};
        private String[] billing_lastname_type_info = new String[]{'billing_lastname','urn:Magento',null,'0','1','false'};
        private String[] shipping_address_id_type_info = new String[]{'shipping_address_id','urn:Magento',null,'0','1','false'};
        private String[] shipping_firstname_type_info = new String[]{'shipping_firstname','urn:Magento',null,'0','1','false'};
        private String[] shipping_lastname_type_info = new String[]{'shipping_lastname','urn:Magento',null,'0','1','false'};
        private String[] billing_name_type_info = new String[]{'billing_name','urn:Magento',null,'0','1','false'};
        private String[] shipping_name_type_info = new String[]{'shipping_name','urn:Magento',null,'0','1','false'};
        private String[] store_to_base_rate_type_info = new String[]{'store_to_base_rate','urn:Magento',null,'0','1','false'};
        private String[] store_to_order_rate_type_info = new String[]{'store_to_order_rate','urn:Magento',null,'0','1','false'};
        private String[] base_to_global_rate_type_info = new String[]{'base_to_global_rate','urn:Magento',null,'0','1','false'};
        private String[] base_to_order_rate_type_info = new String[]{'base_to_order_rate','urn:Magento',null,'0','1','false'};
        private String[] weight_type_info = new String[]{'weight','urn:Magento',null,'0','1','false'};
        private String[] store_name_type_info = new String[]{'store_name','urn:Magento',null,'0','1','false'};
        private String[] remote_ip_type_info = new String[]{'remote_ip','urn:Magento',null,'0','1','false'};
        private String[] status_type_info = new String[]{'status','urn:Magento',null,'0','1','false'};
        private String[] state_type_info = new String[]{'state','urn:Magento',null,'0','1','false'};
        private String[] applied_rule_ids_type_info = new String[]{'applied_rule_ids','urn:Magento',null,'0','1','false'};
        private String[] global_currency_code_type_info = new String[]{'global_currency_code','urn:Magento',null,'0','1','false'};
        private String[] base_currency_code_type_info = new String[]{'base_currency_code','urn:Magento',null,'0','1','false'};
        private String[] store_currency_code_type_info = new String[]{'store_currency_code','urn:Magento',null,'0','1','false'};
        private String[] order_currency_code_type_info = new String[]{'order_currency_code','urn:Magento',null,'0','1','false'};
        private String[] shipping_method_type_info = new String[]{'shipping_method','urn:Magento',null,'0','1','false'};
        private String[] shipping_description_type_info = new String[]{'shipping_description','urn:Magento',null,'0','1','false'};
        private String[] customer_email_type_info = new String[]{'customer_email','urn:Magento',null,'0','1','false'};
        private String[] customer_firstname_type_info = new String[]{'customer_firstname','urn:Magento',null,'0','1','false'};
        private String[] customer_lastname_type_info = new String[]{'customer_lastname','urn:Magento',null,'0','1','false'};
        private String[] quote_id_type_info = new String[]{'quote_id','urn:Magento',null,'0','1','false'};
        private String[] is_virtual_type_info = new String[]{'is_virtual','urn:Magento',null,'0','1','false'};
        private String[] customer_group_id_type_info = new String[]{'customer_group_id','urn:Magento',null,'0','1','false'};
        private String[] customer_note_notify_type_info = new String[]{'customer_note_notify','urn:Magento',null,'0','1','false'};
        private String[] customer_is_guest_type_info = new String[]{'customer_is_guest','urn:Magento',null,'0','1','false'};
        private String[] email_sent_type_info = new String[]{'email_sent','urn:Magento',null,'0','1','false'};
        private String[] order_id_type_info = new String[]{'order_id','urn:Magento',null,'0','1','false'};
        private String[] gift_message_id_type_info = new String[]{'gift_message_id','urn:Magento',null,'0','1','false'};
        private String[] coupon_code_type_info = new String[]{'coupon_code','urn:Magento',null,'0','1','false'};
        private String[] protect_code_type_info = new String[]{'protect_code','urn:Magento',null,'0','1','false'};
        private String[] base_discount_canceled_type_info = new String[]{'base_discount_canceled','urn:Magento',null,'0','1','false'};
        private String[] base_discount_invoiced_type_info = new String[]{'base_discount_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_discount_refunded_type_info = new String[]{'base_discount_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_canceled_type_info = new String[]{'base_shipping_canceled','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_invoiced_type_info = new String[]{'base_shipping_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_refunded_type_info = new String[]{'base_shipping_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_tax_amount_type_info = new String[]{'base_shipping_tax_amount','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_tax_refunded_type_info = new String[]{'base_shipping_tax_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_subtotal_canceled_type_info = new String[]{'base_subtotal_canceled','urn:Magento',null,'0','1','false'};
        private String[] base_subtotal_invoiced_type_info = new String[]{'base_subtotal_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_subtotal_refunded_type_info = new String[]{'base_subtotal_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_tax_canceled_type_info = new String[]{'base_tax_canceled','urn:Magento',null,'0','1','false'};
        private String[] base_tax_invoiced_type_info = new String[]{'base_tax_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_tax_refunded_type_info = new String[]{'base_tax_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_total_invoiced_cost_type_info = new String[]{'base_total_invoiced_cost','urn:Magento',null,'0','1','false'};
        private String[] discount_canceled_type_info = new String[]{'discount_canceled','urn:Magento',null,'0','1','false'};
        private String[] discount_invoiced_type_info = new String[]{'discount_invoiced','urn:Magento',null,'0','1','false'};
        private String[] discount_refunded_type_info = new String[]{'discount_refunded','urn:Magento',null,'0','1','false'};
        private String[] shipping_canceled_type_info = new String[]{'shipping_canceled','urn:Magento',null,'0','1','false'};
        private String[] shipping_invoiced_type_info = new String[]{'shipping_invoiced','urn:Magento',null,'0','1','false'};
        private String[] shipping_refunded_type_info = new String[]{'shipping_refunded','urn:Magento',null,'0','1','false'};
        private String[] shipping_tax_amount_type_info = new String[]{'shipping_tax_amount','urn:Magento',null,'0','1','false'};
        private String[] shipping_tax_refunded_type_info = new String[]{'shipping_tax_refunded','urn:Magento',null,'0','1','false'};
        private String[] subtotal_canceled_type_info = new String[]{'subtotal_canceled','urn:Magento',null,'0','1','false'};
        private String[] subtotal_invoiced_type_info = new String[]{'subtotal_invoiced','urn:Magento',null,'0','1','false'};
        private String[] subtotal_refunded_type_info = new String[]{'subtotal_refunded','urn:Magento',null,'0','1','false'};
        private String[] tax_canceled_type_info = new String[]{'tax_canceled','urn:Magento',null,'0','1','false'};
        private String[] tax_invoiced_type_info = new String[]{'tax_invoiced','urn:Magento',null,'0','1','false'};
        private String[] tax_refunded_type_info = new String[]{'tax_refunded','urn:Magento',null,'0','1','false'};
        private String[] can_ship_partially_type_info = new String[]{'can_ship_partially','urn:Magento',null,'0','1','false'};
        private String[] can_ship_partially_item_type_info = new String[]{'can_ship_partially_item','urn:Magento',null,'0','1','false'};
        private String[] edit_increment_type_info = new String[]{'edit_increment','urn:Magento',null,'0','1','false'};
        private String[] forced_do_shipment_with_invoice_type_info = new String[]{'forced_do_shipment_with_invoice','urn:Magento',null,'0','1','false'};
        private String[] payment_authorization_expiration_type_info = new String[]{'payment_authorization_expiration','urn:Magento',null,'0','1','false'};
        private String[] paypal_ipn_customer_notified_type_info = new String[]{'paypal_ipn_customer_notified','urn:Magento',null,'0','1','false'};
        private String[] quote_address_id_type_info = new String[]{'quote_address_id','urn:Magento',null,'0','1','false'};
        private String[] adjustment_negative_type_info = new String[]{'adjustment_negative','urn:Magento',null,'0','1','false'};
        private String[] adjustment_positive_type_info = new String[]{'adjustment_positive','urn:Magento',null,'0','1','false'};
        private String[] base_adjustment_negative_type_info = new String[]{'base_adjustment_negative','urn:Magento',null,'0','1','false'};
        private String[] base_adjustment_positive_type_info = new String[]{'base_adjustment_positive','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_discount_amount_type_info = new String[]{'base_shipping_discount_amount','urn:Magento',null,'0','1','false'};
        private String[] base_subtotal_incl_tax_type_info = new String[]{'base_subtotal_incl_tax','urn:Magento',null,'0','1','false'};
        private String[] base_total_due_type_info = new String[]{'base_total_due','urn:Magento',null,'0','1','false'};
        private String[] payment_authorization_amount_type_info = new String[]{'payment_authorization_amount','urn:Magento',null,'0','1','false'};
        private String[] shipping_discount_amount_type_info = new String[]{'shipping_discount_amount','urn:Magento',null,'0','1','false'};
        private String[] subtotal_incl_tax_type_info = new String[]{'subtotal_incl_tax','urn:Magento',null,'0','1','false'};
        private String[] total_due_type_info = new String[]{'total_due','urn:Magento',null,'0','1','false'};
        private String[] customer_dob_type_info = new String[]{'customer_dob','urn:Magento',null,'0','1','false'};
        private String[] customer_middlename_type_info = new String[]{'customer_middlename','urn:Magento',null,'0','1','false'};
        private String[] customer_prefix_type_info = new String[]{'customer_prefix','urn:Magento',null,'0','1','false'};
        private String[] customer_suffix_type_info = new String[]{'customer_suffix','urn:Magento',null,'0','1','false'};
        private String[] customer_taxvat_type_info = new String[]{'customer_taxvat','urn:Magento',null,'0','1','false'};
        private String[] discount_description_type_info = new String[]{'discount_description','urn:Magento',null,'0','1','false'};
        private String[] ext_customer_id_type_info = new String[]{'ext_customer_id','urn:Magento',null,'0','1','false'};
        private String[] ext_order_id_type_info = new String[]{'ext_order_id','urn:Magento',null,'0','1','false'};
        private String[] hold_before_state_type_info = new String[]{'hold_before_state','urn:Magento',null,'0','1','false'};
        private String[] hold_before_status_type_info = new String[]{'hold_before_status','urn:Magento',null,'0','1','false'};
        private String[] original_increment_id_type_info = new String[]{'original_increment_id','urn:Magento',null,'0','1','false'};
        private String[] relation_child_id_type_info = new String[]{'relation_child_id','urn:Magento',null,'0','1','false'};
        private String[] relation_child_real_id_type_info = new String[]{'relation_child_real_id','urn:Magento',null,'0','1','false'};
        private String[] relation_parent_id_type_info = new String[]{'relation_parent_id','urn:Magento',null,'0','1','false'};
        private String[] relation_parent_real_id_type_info = new String[]{'relation_parent_real_id','urn:Magento',null,'0','1','false'};
        private String[] x_forwarded_for_type_info = new String[]{'x_forwarded_for','urn:Magento',null,'0','1','false'};
        private String[] customer_note_type_info = new String[]{'customer_note','urn:Magento',null,'0','1','false'};
        private String[] total_item_count_type_info = new String[]{'total_item_count','urn:Magento',null,'0','1','false'};
        private String[] customer_gender_type_info = new String[]{'customer_gender','urn:Magento',null,'0','1','false'};
        private String[] hidden_tax_amount_type_info = new String[]{'hidden_tax_amount','urn:Magento',null,'0','1','false'};
        private String[] base_hidden_tax_amount_type_info = new String[]{'base_hidden_tax_amount','urn:Magento',null,'0','1','false'};
        private String[] shipping_hidden_tax_amount_type_info = new String[]{'shipping_hidden_tax_amount','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_hidden_tax_amount_type_info = new String[]{'base_shipping_hidden_tax_amount','urn:Magento',null,'0','1','false'};
        private String[] hidden_tax_invoiced_type_info = new String[]{'hidden_tax_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_hidden_tax_invoiced_type_info = new String[]{'base_hidden_tax_invoiced','urn:Magento',null,'0','1','false'};
        private String[] hidden_tax_refunded_type_info = new String[]{'hidden_tax_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_hidden_tax_refunded_type_info = new String[]{'base_hidden_tax_refunded','urn:Magento',null,'0','1','false'};
        private String[] shipping_incl_tax_type_info = new String[]{'shipping_incl_tax','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_incl_tax_type_info = new String[]{'base_shipping_incl_tax','urn:Magento',null,'0','1','false'};
        private String[] base_customer_balance_amount_type_info = new String[]{'base_customer_balance_amount','urn:Magento',null,'0','1','false'};
        private String[] customer_balance_amount_type_info = new String[]{'customer_balance_amount','urn:Magento',null,'0','1','false'};
        private String[] base_customer_balance_invoiced_type_info = new String[]{'base_customer_balance_invoiced','urn:Magento',null,'0','1','false'};
        private String[] customer_balance_invoiced_type_info = new String[]{'customer_balance_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_customer_balance_refunded_type_info = new String[]{'base_customer_balance_refunded','urn:Magento',null,'0','1','false'};
        private String[] customer_balance_refunded_type_info = new String[]{'customer_balance_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_customer_balance_total_refunded_type_info = new String[]{'base_customer_balance_total_refunded','urn:Magento',null,'0','1','false'};
        private String[] customer_balance_total_refunded_type_info = new String[]{'customer_balance_total_refunded','urn:Magento',null,'0','1','false'};
        private String[] gift_cards_type_info = new String[]{'gift_cards','urn:Magento',null,'0','1','false'};
        private String[] base_gift_cards_amount_type_info = new String[]{'base_gift_cards_amount','urn:Magento',null,'0','1','false'};
        private String[] gift_cards_amount_type_info = new String[]{'gift_cards_amount','urn:Magento',null,'0','1','false'};
        private String[] base_gift_cards_invoiced_type_info = new String[]{'base_gift_cards_invoiced','urn:Magento',null,'0','1','false'};
        private String[] gift_cards_invoiced_type_info = new String[]{'gift_cards_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_gift_cards_refunded_type_info = new String[]{'base_gift_cards_refunded','urn:Magento',null,'0','1','false'};
        private String[] gift_cards_refunded_type_info = new String[]{'gift_cards_refunded','urn:Magento',null,'0','1','false'};
        private String[] reward_points_balance_type_info = new String[]{'reward_points_balance','urn:Magento',null,'0','1','false'};
        private String[] base_reward_currency_amount_type_info = new String[]{'base_reward_currency_amount','urn:Magento',null,'0','1','false'};
        private String[] reward_currency_amount_type_info = new String[]{'reward_currency_amount','urn:Magento',null,'0','1','false'};
        private String[] base_reward_currency_amount_invoiced_type_info = new String[]{'base_reward_currency_amount_invoiced','urn:Magento',null,'0','1','false'};
        private String[] reward_currency_amount_invoiced_type_info = new String[]{'reward_currency_amount_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_reward_currency_amount_refunded_type_info = new String[]{'base_reward_currency_amount_refunded','urn:Magento',null,'0','1','false'};
        private String[] reward_currency_amount_refunded_type_info = new String[]{'reward_currency_amount_refunded','urn:Magento',null,'0','1','false'};
        private String[] reward_points_balance_refunded_type_info = new String[]{'reward_points_balance_refunded','urn:Magento',null,'0','1','false'};
        private String[] reward_points_balance_to_refund_type_info = new String[]{'reward_points_balance_to_refund','urn:Magento',null,'0','1','false'};
        private String[] reward_salesrule_points_type_info = new String[]{'reward_salesrule_points','urn:Magento',null,'0','1','false'};
        private String[] firstname_type_info = new String[]{'firstname','urn:Magento',null,'0','1','false'};
        private String[] lastname_type_info = new String[]{'lastname','urn:Magento',null,'0','1','false'};
        private String[] telephone_type_info = new String[]{'telephone','urn:Magento',null,'0','1','false'};
        private String[] postcode_type_info = new String[]{'postcode','urn:Magento',null,'0','1','false'};
        
        private String[] is_salesforce_read_type_info = new String[]{'is_salesforce_read','urn:Magento',null,'0','1','false'};
        
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'increment_id','store_id','created_at','updated_at','customer_id','tax_amount','shipping_amount','discount_amount','subtotal','grand_total','total_paid','total_refunded','total_qty_ordered','total_canceled','total_invoiced','total_online_refunded','total_offline_refunded','base_tax_amount','base_shipping_amount','base_discount_amount','base_subtotal','base_grand_total','base_total_paid','base_total_refunded','base_total_qty_ordered','base_total_canceled','base_total_invoiced','base_total_online_refunded','base_total_offline_refunded','billing_address_id','billing_firstname','billing_lastname','shipping_address_id','shipping_firstname','shipping_lastname','billing_name','shipping_name','store_to_base_rate','store_to_order_rate','base_to_global_rate','base_to_order_rate','weight','store_name','remote_ip','status','state','applied_rule_ids','global_currency_code','base_currency_code','store_currency_code','order_currency_code','shipping_method','shipping_description','customer_email','customer_firstname','customer_lastname','quote_id','is_virtual','customer_group_id','customer_note_notify','customer_is_guest','email_sent','order_id','gift_message_id','coupon_code','protect_code','base_discount_canceled','base_discount_invoiced','base_discount_refunded','base_shipping_canceled','base_shipping_invoiced','base_shipping_refunded','base_shipping_tax_amount','base_shipping_tax_refunded','base_subtotal_canceled','base_subtotal_invoiced','base_subtotal_refunded','base_tax_canceled','base_tax_invoiced','base_tax_refunded','base_total_invoiced_cost','discount_canceled','discount_invoiced','discount_refunded','shipping_canceled','shipping_invoiced','shipping_refunded','shipping_tax_amount','shipping_tax_refunded','subtotal_canceled','subtotal_invoiced','subtotal_refunded','tax_canceled','tax_invoiced','tax_refunded','can_ship_partially','can_ship_partially_item','edit_increment','forced_do_shipment_with_invoice','payment_authorization_expiration','paypal_ipn_customer_notified','quote_address_id','adjustment_negative','adjustment_positive','base_adjustment_negative','base_adjustment_positive','base_shipping_discount_amount','base_subtotal_incl_tax','base_total_due','payment_authorization_amount','shipping_discount_amount','subtotal_incl_tax','total_due','customer_dob','customer_middlename','customer_prefix','customer_suffix','customer_taxvat','discount_description','ext_customer_id','ext_order_id','hold_before_state','hold_before_status','original_increment_id','relation_child_id','relation_child_real_id','relation_parent_id','relation_parent_real_id','x_forwarded_for','customer_note','total_item_count','customer_gender','hidden_tax_amount','base_hidden_tax_amount','shipping_hidden_tax_amount','base_shipping_hidden_tax_amount','hidden_tax_invoiced','base_hidden_tax_invoiced','hidden_tax_refunded','base_hidden_tax_refunded','shipping_incl_tax','base_shipping_incl_tax','base_customer_balance_amount','customer_balance_amount','base_customer_balance_invoiced','customer_balance_invoiced','base_customer_balance_refunded','customer_balance_refunded','base_customer_balance_total_refunded','customer_balance_total_refunded','gift_cards','base_gift_cards_amount','gift_cards_amount','base_gift_cards_invoiced','gift_cards_invoiced','base_gift_cards_refunded','gift_cards_refunded','reward_points_balance','base_reward_currency_amount','reward_currency_amount','base_reward_currency_amount_invoiced','reward_currency_amount_invoiced','base_reward_currency_amount_refunded','reward_currency_amount_refunded','reward_points_balance_refunded','reward_points_balance_to_refund','reward_salesrule_points','firstname','lastname','telephone','postcode'};
    }

    public class loginParam_element {
        public String username;
        public String apiKey;
        private String[] username_type_info = new String[]{'username','urn:Magento',null,'1','1','false'};
        private String[] apiKey_type_info = new String[]{'apiKey','urn:Magento',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'username','apiKey'};
    }

    public class loginResponseParam_element {
        public String result;
        private String[] result_type_info = new String[]{'result','urn:Magento',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    public class salesOrderInfoRequestParam_element {
        public String sessionId;
        public String orderIncrementId;
        private String[] sessionId_type_info = new String[]{'sessionId','urn:Magento',null,'1','1','false'};
        private String[] orderIncrementId_type_info = new String[]{'orderIncrementId','urn:Magento',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'sessionId','orderIncrementId'};
    }
    
    public class salesOrderInfoResponseParam_element {
        public magento.salesOrderEntity result;
        private String[] result_type_info = new String[]{'result','urn:Magento',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }   

    public class salesOrderEntity {
        public String increment_id;
        public String parent_id;
        public String store_id;
        public String created_at;
        public String updated_at;
        public String is_active;
        public String customer_id;
        public String tax_amount;
        public String shipping_amount;
        public String discount_amount;
        public String subtotal;
        public String grand_total;
        public String total_paid;
        public String total_refunded;
        public String total_qty_ordered;
        public String total_canceled;
        public String total_invoiced;
        public String total_online_refunded;
        public String total_offline_refunded;
        public String base_tax_amount;
        public String base_shipping_amount;
        public String base_discount_amount;
        public String base_subtotal;
        public String base_grand_total;
        public String base_total_paid;
        public String base_total_refunded;
        public String base_total_qty_ordered;
        public String base_total_canceled;
        public String base_total_invoiced;
        public String base_total_online_refunded;
        public String base_total_offline_refunded;
        public String billing_address_id;
        public String billing_firstname;
        public String billing_lastname;
        public String shipping_address_id;
        public String shipping_firstname;
        public String shipping_lastname;
        public String billing_name;
        public String shipping_name;
        public String store_to_base_rate;
        public String store_to_order_rate;
        public String base_to_global_rate;
        public String base_to_order_rate;
        public String weight;
        public String store_name;
        public String remote_ip;
        public String status;
        public String state;
        public String applied_rule_ids;
        public String global_currency_code;
        public String base_currency_code;
        public String store_currency_code;
        public String order_currency_code;
        public String shipping_method;
        public String shipping_description;
        public String customer_email;
        public String customer_prefix;
        public String customer_firstname;
        public String customer_lastname;
        public String quote_id;
        public String is_virtual;
        public String customer_group_id;
        public String customer_note_notify;
        public String customer_is_guest;
        public String email_sent;
        public String order_id;
        public String gift_message_id;
        public String gift_message;
        public String is_salesforce_read;
        public magento.salesOrderAddressEntity shipping_address;
        public magento.salesOrderAddressEntity billing_address;
        public magento.salesOrderItemEntityArray items;
        public magento.salesOrderPaymentEntity payment;
        public magento.salesOrderStatusHistoryEntityArray status_history;
        private String[] increment_id_type_info = new String[]{'increment_id','urn:Magento',null,'0','1','false'};
        private String[] parent_id_type_info = new String[]{'parent_id','urn:Magento',null,'0','1','false'};
        private String[] store_id_type_info = new String[]{'store_id','urn:Magento',null,'0','1','false'};
        private String[] created_at_type_info = new String[]{'created_at','urn:Magento',null,'0','1','false'};
        private String[] updated_at_type_info = new String[]{'updated_at','urn:Magento',null,'0','1','false'};
        private String[] is_active_type_info = new String[]{'is_active','urn:Magento',null,'0','1','false'};
        private String[] customer_id_type_info = new String[]{'customer_id','urn:Magento',null,'0','1','false'};
        private String[] tax_amount_type_info = new String[]{'tax_amount','urn:Magento',null,'0','1','false'};
        private String[] shipping_amount_type_info = new String[]{'shipping_amount','urn:Magento',null,'0','1','false'};
        private String[] discount_amount_type_info = new String[]{'discount_amount','urn:Magento',null,'0','1','false'};
        private String[] subtotal_type_info = new String[]{'subtotal','urn:Magento',null,'0','1','false'};
        private String[] grand_total_type_info = new String[]{'grand_total','urn:Magento',null,'0','1','false'};
        private String[] total_paid_type_info = new String[]{'total_paid','urn:Magento',null,'0','1','false'};
        private String[] total_refunded_type_info = new String[]{'total_refunded','urn:Magento',null,'0','1','false'};
        private String[] total_qty_ordered_type_info = new String[]{'total_qty_ordered','urn:Magento',null,'0','1','false'};
        private String[] total_canceled_type_info = new String[]{'total_canceled','urn:Magento',null,'0','1','false'};
        private String[] total_invoiced_type_info = new String[]{'total_invoiced','urn:Magento',null,'0','1','false'};
        private String[] total_online_refunded_type_info = new String[]{'total_online_refunded','urn:Magento',null,'0','1','false'};
        private String[] total_offline_refunded_type_info = new String[]{'total_offline_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_tax_amount_type_info = new String[]{'base_tax_amount','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_amount_type_info = new String[]{'base_shipping_amount','urn:Magento',null,'0','1','false'};
        private String[] base_discount_amount_type_info = new String[]{'base_discount_amount','urn:Magento',null,'0','1','false'};
        private String[] base_subtotal_type_info = new String[]{'base_subtotal','urn:Magento',null,'0','1','false'};
        private String[] base_grand_total_type_info = new String[]{'base_grand_total','urn:Magento',null,'0','1','false'};
        private String[] base_total_paid_type_info = new String[]{'base_total_paid','urn:Magento',null,'0','1','false'};
        private String[] base_total_refunded_type_info = new String[]{'base_total_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_total_qty_ordered_type_info = new String[]{'base_total_qty_ordered','urn:Magento',null,'0','1','false'};
        private String[] base_total_canceled_type_info = new String[]{'base_total_canceled','urn:Magento',null,'0','1','false'};
        private String[] base_total_invoiced_type_info = new String[]{'base_total_invoiced','urn:Magento',null,'0','1','false'};
        private String[] base_total_online_refunded_type_info = new String[]{'base_total_online_refunded','urn:Magento',null,'0','1','false'};
        private String[] base_total_offline_refunded_type_info = new String[]{'base_total_offline_refunded','urn:Magento',null,'0','1','false'};
        private String[] billing_address_id_type_info = new String[]{'billing_address_id','urn:Magento',null,'0','1','false'};
        private String[] billing_firstname_type_info = new String[]{'billing_firstname','urn:Magento',null,'0','1','false'};
        private String[] billing_lastname_type_info = new String[]{'billing_lastname','urn:Magento',null,'0','1','false'};
        private String[] shipping_address_id_type_info = new String[]{'shipping_address_id','urn:Magento',null,'0','1','false'};
        private String[] shipping_firstname_type_info = new String[]{'shipping_firstname','urn:Magento',null,'0','1','false'};
        private String[] shipping_lastname_type_info = new String[]{'shipping_lastname','urn:Magento',null,'0','1','false'};
        private String[] billing_name_type_info = new String[]{'billing_name','urn:Magento',null,'0','1','false'};
        private String[] shipping_name_type_info = new String[]{'shipping_name','urn:Magento',null,'0','1','false'};
        private String[] store_to_base_rate_type_info = new String[]{'store_to_base_rate','urn:Magento',null,'0','1','false'};
        private String[] store_to_order_rate_type_info = new String[]{'store_to_order_rate','urn:Magento',null,'0','1','false'};
        private String[] base_to_global_rate_type_info = new String[]{'base_to_global_rate','urn:Magento',null,'0','1','false'};
        private String[] base_to_order_rate_type_info = new String[]{'base_to_order_rate','urn:Magento',null,'0','1','false'};
        private String[] weight_type_info = new String[]{'weight','urn:Magento',null,'0','1','false'};
        private String[] store_name_type_info = new String[]{'store_name','urn:Magento',null,'0','1','false'};
        private String[] remote_ip_type_info = new String[]{'remote_ip','urn:Magento',null,'0','1','false'};
        private String[] status_type_info = new String[]{'status','urn:Magento',null,'0','1','false'};
        private String[] state_type_info = new String[]{'state','urn:Magento',null,'0','1','false'};
        private String[] applied_rule_ids_type_info = new String[]{'applied_rule_ids','urn:Magento',null,'0','1','false'};
        private String[] global_currency_code_type_info = new String[]{'global_currency_code','urn:Magento',null,'0','1','false'};
        private String[] base_currency_code_type_info = new String[]{'base_currency_code','urn:Magento',null,'0','1','false'};
        private String[] store_currency_code_type_info = new String[]{'store_currency_code','urn:Magento',null,'0','1','false'};
        private String[] order_currency_code_type_info = new String[]{'order_currency_code','urn:Magento',null,'0','1','false'};
        private String[] shipping_method_type_info = new String[]{'shipping_method','urn:Magento',null,'0','1','false'};
        private String[] shipping_description_type_info = new String[]{'shipping_description','urn:Magento',null,'0','1','false'};
        private String[] customer_email_type_info = new String[]{'customer_email','urn:Magento',null,'0','1','false'};
        private String[] customer_prefix_type_info = new String[]{'customer_prefix','urn:Magento',null,'0','1','false'};
        private String[] customer_firstname_type_info = new String[]{'customer_firstname','urn:Magento',null,'0','1','false'};
        private String[] customer_lastname_type_info = new String[]{'customer_lastname','urn:Magento',null,'0','1','false'};
        private String[] quote_id_type_info = new String[]{'quote_id','urn:Magento',null,'0','1','false'};
        private String[] is_virtual_type_info = new String[]{'is_virtual','urn:Magento',null,'0','1','false'};
        private String[] customer_group_id_type_info = new String[]{'customer_group_id','urn:Magento',null,'0','1','false'};
        private String[] customer_note_notify_type_info = new String[]{'customer_note_notify','urn:Magento',null,'0','1','false'};
        private String[] customer_is_guest_type_info = new String[]{'customer_is_guest','urn:Magento',null,'0','1','false'};
        private String[] email_sent_type_info = new String[]{'email_sent','urn:Magento',null,'0','1','false'};
        private String[] order_id_type_info = new String[]{'order_id','urn:Magento',null,'0','1','false'};
        private String[] gift_message_id_type_info = new String[]{'gift_message_id','urn:Magento',null,'0','1','false'};
        private String[] gift_message_type_info = new String[]{'gift_message','urn:Magento',null,'0','1','false'};
        private String[] shipping_address_type_info = new String[]{'shipping_address','urn:Magento',null,'0','1','false'};
        private String[] billing_address_type_info = new String[]{'billing_address','urn:Magento',null,'0','1','false'};
        private String[] items_type_info = new String[]{'items','urn:Magento',null,'0','1','false'};
        private String[] payment_type_info = new String[]{'payment','urn:Magento',null,'0','1','false'};
        private String[] status_history_type_info = new String[]{'status_history','urn:Magento',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'increment_id','parent_id','store_id','created_at','updated_at','is_active','customer_id','tax_amount','shipping_amount','discount_amount','subtotal','grand_total','total_paid','total_refunded','total_qty_ordered','total_canceled','total_invoiced','total_online_refunded','total_offline_refunded','base_tax_amount','base_shipping_amount','base_discount_amount','base_subtotal','base_grand_total','base_total_paid','base_total_refunded','base_total_qty_ordered','base_total_canceled','base_total_invoiced','base_total_online_refunded','base_total_offline_refunded','billing_address_id','billing_firstname','billing_lastname','shipping_address_id','shipping_firstname','shipping_lastname','billing_name','shipping_name','store_to_base_rate','store_to_order_rate','base_to_global_rate','base_to_order_rate','weight','store_name','remote_ip','status','state','applied_rule_ids','global_currency_code','base_currency_code','store_currency_code','order_currency_code','shipping_method','shipping_description','customer_email','customer_prefix','customer_firstname','customer_lastname','quote_id','is_virtual','customer_group_id','customer_note_notify','customer_is_guest','email_sent','order_id','gift_message_id','gift_message','shipping_address','billing_address','items','payment','status_history'};
        private String[] is_salesforce_read_type_info = new String[]{'is_salesforce_read','urn:Magento',null,'0','1','false'};
    }

    public class salesOrderAddressEntity {
        public String increment_id;
        public String parent_id;
        public String created_at;
        public String updated_at;
        public String is_active;
        public String address_type;
        public String firstname;
        public String lastname;
        public String company;
        public String street;
        public String city;
        public String region;
        public String postcode;
        public String country_id;
        public String telephone;
        public String fax;
        public String region_id;
        public String address_id;
        private String[] increment_id_type_info = new String[]{'increment_id','urn:Magento',null,'0','1','false'};
        private String[] parent_id_type_info = new String[]{'parent_id','urn:Magento',null,'0','1','false'};
        private String[] created_at_type_info = new String[]{'created_at','urn:Magento',null,'0','1','false'};
        private String[] updated_at_type_info = new String[]{'updated_at','urn:Magento',null,'0','1','false'};
        private String[] is_active_type_info = new String[]{'is_active','urn:Magento',null,'0','1','false'};
        private String[] address_type_type_info = new String[]{'address_type','urn:Magento',null,'0','1','false'};
        private String[] firstname_type_info = new String[]{'firstname','urn:Magento',null,'0','1','false'};
        private String[] lastname_type_info = new String[]{'lastname','urn:Magento',null,'0','1','false'};
        private String[] company_type_info = new String[]{'company','urn:Magento',null,'0','1','false'};
        private String[] street_type_info = new String[]{'street','urn:Magento',null,'0','1','false'};
        private String[] city_type_info = new String[]{'city','urn:Magento',null,'0','1','false'};
        private String[] region_type_info = new String[]{'region','urn:Magento',null,'0','1','false'};
        private String[] postcode_type_info = new String[]{'postcode','urn:Magento',null,'0','1','false'};
        private String[] country_id_type_info = new String[]{'country_id','urn:Magento',null,'0','1','false'};
        private String[] telephone_type_info = new String[]{'telephone','urn:Magento',null,'0','1','false'};
        private String[] fax_type_info = new String[]{'fax','urn:Magento',null,'0','1','false'};
        private String[] region_id_type_info = new String[]{'region_id','urn:Magento',null,'0','1','false'};
        private String[] address_id_type_info = new String[]{'address_id','urn:Magento',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'increment_id','parent_id','created_at','updated_at','is_active','address_type','firstname','lastname','company','street','city','region','postcode','country_id','telephone','fax','region_id','address_id'};
    }

    public class salesOrderPaymentEntity {
        public String increment_id;
        public String parent_id;
        public String created_at;
        public String updated_at;
        public String is_active;
        public String amount_ordered;
        public String shipping_amount;
        public String base_amount_ordered;
        public String base_shipping_amount;
        public String method;
        public String po_number;
        public String cc_type;
        public String cc_number_enc;
        public String cc_last4;
        public String cc_owner;
        public String cc_exp_month;
        public String cc_exp_year;
        public String cc_ss_start_month;
        public String cc_ss_start_year;
        public String payment_id;
        private String[] increment_id_type_info = new String[]{'increment_id','urn:Magento',null,'0','1','false'};
        private String[] parent_id_type_info = new String[]{'parent_id','urn:Magento',null,'0','1','false'};
        private String[] created_at_type_info = new String[]{'created_at','urn:Magento',null,'0','1','false'};
        private String[] updated_at_type_info = new String[]{'updated_at','urn:Magento',null,'0','1','false'};
        private String[] is_active_type_info = new String[]{'is_active','urn:Magento',null,'0','1','false'};
        private String[] amount_ordered_type_info = new String[]{'amount_ordered','urn:Magento',null,'0','1','false'};
        private String[] shipping_amount_type_info = new String[]{'shipping_amount','urn:Magento',null,'0','1','false'};
        private String[] base_amount_ordered_type_info = new String[]{'base_amount_ordered','urn:Magento',null,'0','1','false'};
        private String[] base_shipping_amount_type_info = new String[]{'base_shipping_amount','urn:Magento',null,'0','1','false'};
        private String[] method_type_info = new String[]{'method','urn:Magento',null,'0','1','false'};
        private String[] po_number_type_info = new String[]{'po_number','urn:Magento',null,'0','1','false'};
        private String[] cc_type_type_info = new String[]{'cc_type','urn:Magento',null,'0','1','false'};
        private String[] cc_number_enc_type_info = new String[]{'cc_number_enc','urn:Magento',null,'0','1','false'};
        private String[] cc_last4_type_info = new String[]{'cc_last4','urn:Magento',null,'0','1','false'};
        private String[] cc_owner_type_info = new String[]{'cc_owner','urn:Magento',null,'0','1','false'};
        private String[] cc_exp_month_type_info = new String[]{'cc_exp_month','urn:Magento',null,'0','1','false'};
        private String[] cc_exp_year_type_info = new String[]{'cc_exp_year','urn:Magento',null,'0','1','false'};
        private String[] cc_ss_start_month_type_info = new String[]{'cc_ss_start_month','urn:Magento',null,'0','1','false'};
        private String[] cc_ss_start_year_type_info = new String[]{'cc_ss_start_year','urn:Magento',null,'0','1','false'};
        private String[] payment_id_type_info = new String[]{'payment_id','urn:Magento',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'increment_id','parent_id','created_at','updated_at','is_active','amount_ordered','shipping_amount','base_amount_ordered','base_shipping_amount','method','po_number','cc_type','cc_number_enc','cc_last4','cc_owner','cc_exp_month','cc_exp_year','cc_ss_start_month','cc_ss_start_year','payment_id'};
    }

    public class salesOrderStatusHistoryEntityArray {
        public magento.salesOrderStatusHistoryEntity[] complexObjectArray;
        private String[] complexObjectArray_type_info = new String[]{'complexObjectArray','urn:Magento',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'complexObjectArray'};
    }

    public class salesOrderStatusHistoryEntity {
        public String increment_id;
        public String parent_id;
        public String created_at;
        public String updated_at;
        public String is_active;
        public String is_customer_notified;
        public String status;
        public String comment;
        private String[] increment_id_type_info = new String[]{'increment_id','urn:Magento',null,'0','1','false'};
        private String[] parent_id_type_info = new String[]{'parent_id','urn:Magento',null,'0','1','false'};
        private String[] created_at_type_info = new String[]{'created_at','urn:Magento',null,'0','1','false'};
        private String[] updated_at_type_info = new String[]{'updated_at','urn:Magento',null,'0','1','false'};
        private String[] is_active_type_info = new String[]{'is_active','urn:Magento',null,'0','1','false'};
        private String[] is_customer_notified_type_info = new String[]{'is_customer_notified','urn:Magento',null,'0','1','false'};
        private String[] status_type_info = new String[]{'status','urn:Magento',null,'0','1','false'};
        private String[] comment_type_info = new String[]{'comment','urn:Magento',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:Magento','false','false'};
        private String[] field_order_type_info = new String[]{'increment_id','parent_id','created_at','updated_at','is_active','is_customer_notified','status','comment'};
    }

    public class Port {
        public String endpoint_x = 'https://shop.pflege.de/index.php/api/v2_soap/index/';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'urn:Magento', 'magento'};
    
        public String login(String username,String apiKey) {
            magento.loginParam_element request_x = new magento.loginParam_element();
            request_x.username = username;
            request_x.apiKey = apiKey;
            magento.loginResponseParam_element response_x;
            Map<String, magento.loginResponseParam_element> response_map_x = new Map<String, magento.loginResponseParam_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              'urn:Magento',
              'loginParam',
              'urn:Magento',
              'loginResponseParam',
              'magento.loginResponseParam_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }   

        public magento.salesOrderListEntityArray salesOrderList(String sessionId,magento.filters filters) {
            magento.salesOrderListRequestParam_element request_x = new magento.salesOrderListRequestParam_element();
            request_x.sessionId = sessionId;
            request_x.filters = filters;
            magento.salesOrderListResponseParam_element response_x;
            Map<String, magento.salesOrderListResponseParam_element> response_map_x = new Map<String, magento.salesOrderListResponseParam_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              'urn:Magento',
              'salesOrderListRequestParam',
              'urn:Magento',
              'salesOrderListResponseParam',
              'magento.salesOrderListResponseParam_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }
    
        public magento.salesOrderEntity salesOrderInfo(String sessionId,String orderIncrementId) {
            magento.salesOrderInfoRequestParam_element request_x = new magento.salesOrderInfoRequestParam_element();
            request_x.sessionId = sessionId;
            request_x.orderIncrementId = orderIncrementId;
            magento.salesOrderInfoResponseParam_element response_x;
            Map<String, magento.salesOrderInfoResponseParam_element> response_map_x = new Map<String, magento.salesOrderInfoResponseParam_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              'urn:Magento',
              'salesOrderInfoRequestParam',
              'urn:Magento',
              'salesOrderInfoResponseParam',
              'magento.salesOrderInfoResponseParam_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }   

    }
}