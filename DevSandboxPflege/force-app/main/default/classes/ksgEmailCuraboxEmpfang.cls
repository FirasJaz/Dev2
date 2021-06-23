global class ksgEmailCuraboxEmpfang implements Messaging.InboundEmailHandler {
    public ksgEmailCuraboxBearbeiten ksgMail {get; set;}
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult resultData = new Messaging.InboundEmailresult();
        ksgMail = new ksgEmailCuraboxBearbeiten(email);
        
        resultData.success = true;
        return resultData;
    }
}