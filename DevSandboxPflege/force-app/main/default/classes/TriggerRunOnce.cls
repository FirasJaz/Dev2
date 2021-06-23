public class TriggerRunOnce {
    private static Set <Id> idSet = new Set <Id>();

    // has this Id been processed? 
    public static boolean isAlreadyDone(Id objectId) {
        return (idSet.contains(objectId));
    }

    // set that this Id has been processed.
    public static void setAlreadyDone(Id objectId) {
        idSet.add(objectId);
    }

    // empty set if we need to for some reason. 
    public static void resetAlreadyDone() {
        idSet.clear();
    }

}