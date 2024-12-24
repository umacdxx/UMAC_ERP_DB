CREATE SYMMETRIC KEY [UMAC_CERT_KEY]
    AUTHORIZATION [dbo]
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE [UMAC_CERT];


GO
