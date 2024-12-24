

/*
-- 생성자 :	이동호
-- 등록일 :	2024.06.20
-- 수정자 : -
-- 수정일 : - 
-- 설 명	: 입금번호 출력
-- 실행문 : 
	
	SELECT DBO.GET_DEPOSIT_NO('20240712')

*/
CREATE FUNCTION [dbo].[GET_DEPOSIT_NO](
	@P_DATE VARCHAR(8)
)
RETURNS VARCHAR(11)
AS
BEGIN
	DECLARE @DEPOSIT_NO NVARCHAR(11)	
	DECLARE @DEPOSIT_NO_MAX BIGINT

	SELECT @DEPOSIT_NO_MAX = MAX(DEPOSIT_NO) FROM PA_ACCT_DEPOSIT WITH(NOLOCK) WHERE DEPOSIT_DT = @P_DATE

	IF @DEPOSIT_NO_MAX IS NULL 
	BEGIN
		SET @DEPOSIT_NO = @P_DATE + '001'
	END
	ELSE
	BEGIN
		SET @DEPOSIT_NO = CONVERT(NVARCHAR(11), CAST(@DEPOSIT_NO_MAX AS BIGINT) + 1)
	END
	
RETURN @DEPOSIT_NO
END

GO

