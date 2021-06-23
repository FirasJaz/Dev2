@istest
public class ksgMagentoController_test {
    static testMethod void  testPostRestService() {
        list<ksgMagentoController.Lines> lnList = new list<ksgMagentoController.Lines>();
        String jsonstring = '{'+
        '   \"order_id\" : \"160\",'+
        '   \"increment_id\" : \"20151000\",'+
        '   \"status\" : \"processed\",'+
        '   \"customer\" :'+
        '       {'+
        '           \"customer_prefix\" : \"Herr\",'+
        '           \"customer_firstname\" : \"Marius\",'+
        '           \"customer_lastname\" : \"Müller\",'+
        '           \"customer_email\" : \"mm@gmx.de\",'+
        '           \"customer_telephone\" : \"040 222 333 555\",'+
        '           \"customer_fax\" : \"040 222 333 555-1\",'+
        '           \"customer_id\" : \"m12345678\"         '+
        '       },'+
        '   \"shipping_address\" :'+
        '   {'+
        '       \"shipping_firstname\" : \"Marius\",'+
        '       \"shipping_lastname\" : \"Müller\",'+
        '       \"shipping_street\" : \"Großstr. 22\",'+
        '       \"shipping_postcode\" : \"20339\",'+
        '       \"shipping_city\" : \"Hamburg\",'+
        '       \"shipping_country_id\" : \"DE\"'+
        '   },'+
        '   \"billing_address\" : '+
        '   {'+
        '       \"billing_firstname\" : \"Marius\",'+
        '       \"billing_lastname\" : \"Müller\",'+
        '       \"billing_street\" : \"Großstr. 22\",'+
        '       \"billing_postcode\" : \"20339\",'+
        '       \"billing_city\" : \"Hamburg\",'+
        '       \"billing_country_id\" : \"DE\" '+
        '   },'+
        '   \"order\" : {       '+
        '       \"total_amount\" : \"11.10\", '+
        '       \"discount_amount\" : \"\",'+
        '       \"shipping_amount\" : \"3.90\",'+
        '       \"grand_total\" : \"15.00\", '+
        '       \"tax_amount_01\" : \"0.00\",   '+
        '       \"tax_amount_02\" : \"\" '+
        '   },'+
        '   \"payment\" : {'+
        '       \"payment_method\" : \"Invoice\",'+
        '       \"payment_status\" : \"processed\",'+
        '       \"payment_id\" : \"I001-33\"'+
        '   },'+
        '   \"lines\" : ['+
        '           {   \"line_no\" : \"1\", '+
        '               \"ean\" : \"4.031.678.001.132\",'+
        '               \"name\" : \"Sterillium Virugard. 500ml\",'+
        '               \"qty_ordered\" : \"2\",'+
        '               \"price\" : \"2.10\",'+
        '               \"amount\" : \"4.20\",'+
        '               \"discount_amount\" : \"\",'+
        '               \"discount_percent\" : \"\",'+
        '               \"grand_amount\" : \"4.20\",'+
        '               \"item_id\" : \"1234567\",'+
        '               \"tax_percent\" : \"\", '+
        '               \"tax_amount\" : \"\"               '+
        '           },'+
        '           {   \"line_no\" : \"2\", '+
        '               \"ean\" : \"4.049.500.112.758\",'+
        '               \"qty_ordered\" : \"1\",'+
        '               \"name\" : \"Menalind professional clean Reinigungsschaum 400ml\",'+
        '               \"price\" : \"6.90\",'+
        '               \"amount\" : \"6.90\",'+
        '               \"discount_amount\" : \"\",'+
        '               \"discount_percent\" : \"\",'+
        '               \"grand_amount\" : \"6.90\",'+
        '               \"item_id\" : \"901234\",'+
        '               \"tax_percent\" : \"\", '+
        '               \"tax_amount\" : \"\"                   '+
        '           }               '+
        '   ]'+
        '}';        
        
        
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/magentoshop'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        ksgMagentoController.Payment p = new ksgMagentoController.Payment();

        
        ksgMagentoController.Customer c = new ksgMagentoController.Customer();
        c.customer_lastname = 'test';
        ksgMagentoController.Billing_address b = new ksgMagentoController.Billing_address();
        ksgMagentoController.Shipping_address s = new ksgMagentoController.Shipping_address();
        ksgMagentoController.Order o = new ksgMagentoController.Order();
        ksgMagentoController.Lines l1 = new ksgMagentoController.Lines();
        lnList.add(l1);
        ksgMagentoController.Lines l2 = new ksgMagentoController.Lines();
        lnList.add(l2);

        ksgMagentoController.createNewLead( '123', 
                                        '123',
                                        'status', 
                                        c, 
                                        s, 
                                        b, 
                                        o,
                                        p,
                                        lnList);
                                        
    }

}