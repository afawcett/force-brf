/**
 * Implement this interface to allow the framework to pass 
 *   back errors to your Batch Apex class for handling and retry. This interface
 *   also extends the RaisesPlatformEvents interface ensuring that error events are sent
 **/
public interface brf_BatchableErrorHandler extends Database.RaisesPlatformEvents {
    /**
     * Update related records that errors have occured
     **/
    void handleErrors(brf_BatchableError error);
}
