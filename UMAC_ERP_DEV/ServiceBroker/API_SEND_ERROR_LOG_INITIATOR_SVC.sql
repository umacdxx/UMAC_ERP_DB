CREATE SERVICE [API_SEND_ERROR_LOG_INITIATOR_SVC]
    AUTHORIZATION [dbo]
    ON QUEUE [dbo].[API_SEND_ERROR_LOG_INITIATOR_Q]
    ([API_SEND_ERROR_LOG_CONTRACT]);


GO

