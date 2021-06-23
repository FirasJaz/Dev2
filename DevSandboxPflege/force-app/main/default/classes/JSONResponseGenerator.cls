public class JSONResponseGenerator {
	public class FailedSubmittedData {
		public String message {
			get;set;
		}
		public Map<String, String> submitted{
			get;set;
		}
	}

	public class SFResponse {
		public Boolean success {
			get;set;
		}
		public List<String> errors {
			get;set;
		}
		public String id {
			get;set;
		}
	}

	public class ApprovedResponse {
		public String message {
			get;set;
		}
		public List<Map<String, Boolean>> products {
			get;set;
		}
		public Map<String, Map<String,String>> tracking_data {
			get;set;
		}
	}

	public class PendingApprovalResponse {
		public String message {
			get;set;
		}
		//    public Map<String, String> tracking_data {get;set;}

	}

	public class CanceledCuraboxResponse {
		public String message {
			get;set;
		}
		//    public Map<String, String> tracking_data {get;set;}

	}

	public class PendingApprovalShipmentResponse {
		public String message {
			get;set;
		}

	}

	public class ApprovedShipmentResponse {
		public String message {
			get;set;
		}
		public Map<String, Map<String,String>> tracking_data {
			get;set;
		}


	}

	public static String generateJsonResponse(String success, Object data, Integer statusCode) {
		// Create a JSONGenerator object.
		// Pass true to the constructor for pretty print formatting.
		JSONGenerator gen = JSON.createGenerator(true);

		// Write data to the JSON string.
		gen.writeStartObject(); // start
		gen.writeStringField('status', success);
		gen.writeNumberField('status_code', statusCode);
		//    gen.writeEndObject();
		gen.writeFieldName('data');
		gen.writeObject(data);
		gen.writeEndObject();
		// Get the JSON string.
		String pretty = gen.getAsString();

		return pretty;
	}

	public static String generateJsonResponse(Object data) {
		// Create a JSONGenerator object.
		// Pass true to the constructor for pretty print formatting.
		JSONGenerator gen = JSON.createGenerator(true);

		// Write data to the JSON string.
		//		gen.writeStartObject(); // start
		gen.writeObject(data);
		//		gen.writeEndObject();
		// Get the JSON string.
		String pretty = gen.getAsString();

		return pretty;
	}

}