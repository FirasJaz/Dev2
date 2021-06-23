/**
*  class to call out the entry event that initiates the journey
*
        * Change History
        * Date		    | 		Author		             |	Action
        * 07.06.21      |    FJ@cloudmonsters.de	     | Initial Creation
*
*/
public  class EventStreamService {
    public static final String HTTP_POST_METHOD = 'POST';
    public static final String CURABOX_AENDERN ='cb_curabox_aendern';
    public static MC_setting__mdt  settings = MC_setting__mdt.getInstance('Credentials');
    public static EventStream__c eventStream{get;set;}
    // Access partition
    public static Cache.OrgPartition orgPart = Cache.Org.getPartition('local.StoreAccessToken');
 
    /**
     *  read access token from cach orc ´calling when its expired or for the first time
     * @return the  token
     */
    public static String getAccessToken() {
        String accessToken ;
        //Get the token & expiry partitions initial values
        String cacheAccessToken = (String)orgPart.get('token');
        DateTime expiry = (DateTime)orgPart.get('expiry');

        //Check if access token is Null/Expired. Get the access token only when its expired or calling for the first time
      if(String.isBlank(cacheAccessToken)|| expiry == NULL || expiry < system.now()){

        String clientId = settings.Client_Id__c;
        String clientSecret = settings.Client_Secret__c;
        String endpoint = settings.Authorization_Endpoint__c;
        Map<String,String> params = new Map<String,String> {
            
            'client_id' => clientId,
            'client_secret' => clientSecret,
            'grant_type' => 'client_credentials'
            
        };
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);       
        req.setBody(JSON.serialize(params));
        req.setMethod(HTTP_POST_METHOD);
        req.setHeader('Content-Type', 'application/json');
        HTTPResponse resp = Test.isRunningTest() ? createMockupLoginResponse() : executeRequest(req) ;
        if(resp.getStatusCode() == 200){
         Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(resp.getBody());
          accessToken = (String)result.get('access_token');
         //Storing Access Token and Expiry to Org cache
         orgPart.put('token',accessToken);
         orgPart.put('expiry',system.now().addSeconds(3600));
        }    
      }
      else {
        accessToken = (String)orgPart.get('token');
      }      
        return accessToken;  
    }


    /**
     * execute the callout
     */
    @future (callout=true)
    public static void callout(List <String> eventStreamsAsString) {
        for(String eventAsString :eventStreamsAsString ){
            //get the Sobject from the JSON
            eventStream = (EventStream__c) JSON.deserialize(eventAsString, EventStream__c.class);
        try {
            System.debug('eventStream'+ eventStream);
            String requestBody = buildRequestBody(eventStream);
            System.debug('>>>>>>>>>>>> call out');
            HttpRequest req = createRequest(requestBody);
            HTTPResponse resp = Test.isRunningTest() ? createMockupPostResponse() : executeRequest(req) ;
            if (resp.getStatusCode() == 201) {
                system.debug('response created' + resp.getBody());  
            }else{
                system.debug('error');
                Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(resp.getBody());
                String message = (String)result.get('message'); 
                system.debug('message error' + message);
            }
        }
        catch (Exception e) {
            System.debug('An exception occurred: ' + e.getMessage());
        }

       }
    }

    /**
     *  prepare the request for the callout
     * @param requestBody
     * @return the httprequest
     */
    public static HttpRequest createRequest(String requestBody) {
        HttpRequest request = new HttpRequest();
        string url = settings.Endpoint__c +'/interaction/v1/events';
        request.setEndpoint(url);
        request.setTimeout(120000);
        //Set HTTPRequest Method
        request.setMethod(HTTP_POST_METHOD);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Authorization', 'Bearer ' + getAccessToken());
        if (String.isNotBlank(requestBody)) {
            request.setBody(requestBody);
        }
        return request;
    }

    /**
     * execute request
     * @param req
     * @return the response
     */
    public static HTTPResponse executeRequest(HttpRequest req) {
        Http http = new Http();
        HTTPResponse resp = null;
        resp = http.send(req);
        return resp;
    }


    /**
     * Build the json body
     * @param eventStream
     * @return the Json as String
     */
    public static String buildRequestBody(EventStream__c event){
       //maps
		Map<String, Object> body = new Map<String, Object>();
		Map<String, Object> data = new Map<String, Object>();
        // get the event definitionKey from the Custom Metadata
		String eventDefinitionKey = MC_Event__mdt.getInstance(event.EventStream_Description__c).eventDefinitionKey__c;
        System.debug('eventDefinitionKey'+ eventDefinitionKey);
        String contactSubscriberKey = event.EventStream_Description__c.equals(CURABOX_AENDERN) ?event.Email__c:  event.Contact_Key_ID__c; 
        //fill body object
        body.put('ContactKey', contactSubscriberKey);
        body.put('EventDefinitionKey', eventDefinitionKey);
        body.put('Data', data);
        //fill data object
        data.put('SubscriberKey', contactSubscriberKey);
        data.put('Email', event.Email__c);
         /**
          * Fill dynamically the other fields to be sent from FieldSet
          */
        List<Schema.FieldSetMember> fieldSetMemberList = SObjectType.EventStream__c.FieldSets.EventStream_Data_FieldSet.getFields();
        if(!fieldSetMemberList.isEmpty()){
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
            // get the value from the apiName 
            if(event.get(fieldSetMemberObj.getFieldPath())!= null){
                //put apiName of the field, and its value
                data.put(fieldSetMemberObj.getFieldPath(), event.get(fieldSetMemberObj.getFieldPath()));
             }
        }
       }    	
		//serialize object to json
		String jsonSerialized=JSON.serialize(body);
        system.debug(jsonSerialized);

        return jsonSerialized;

    }


     //this is response for test class
     private static HTTPResponse createMockupLoginResponse(){
        HTTPResponse resp = new HTTPResponse();
        resp.setBody('{"access_token": "78314322820e4922b47700dcdd65f844", "expires_in": 7200}');
        resp.setHeader('Content-Type', 'application/json');
        resp.setStatusCode(200);
        resp.setStatus('OK');
        return resp;
    }
    //this is response for test class
    private static HTTPResponse createMockupPostResponse(){
        HTTPResponse resp = new HTTPResponse();
        resp.setBody('{"eventInstanceId": "519bd003-4f8c-48db-bce1-6e6b19f47590"}');
        resp.setHeader('Content-Type', 'application/json');
        resp.setStatusCode(201);
        resp.setStatus('Created');
        return resp;

    }

   
}