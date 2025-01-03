

/*
-- 생성자 :	이동호
-- 등록일 :	2024.08.30
-- 수정자 : -
-- 수정일 : - 
-- 설 명	: 유맥 운영서버 인지 개발 서버 인지 확인
-- 실행문 : SELECT DBO.UMAC_ENV()
*/
CREATE FUNCTION [dbo].[UMAC_ENV](
)
RETURNS NVARCHAR(5)
AS
BEGIN
	DECLARE @RESULT NVARCHAR(5)

	DECLARE @SERVERNAME NVARCHAR(50)
	DECLARE @DB_NAME NVARCHAR(50)

	SET @SERVERNAME = @@SERVERNAME;
	SET @DB_NAME = DB_NAME();

	--운영서버
	IF @SERVERNAME = 'WIN-9OUKUT1FR5I'
	BEGIN 				
		SET @RESULT = 'REAL'
	END
	ELSE 
	--개발서버
	BEGIN
		SET @RESULT = 'DEV'
	END

RETURN @RESULT
END

GO

