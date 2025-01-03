
/*
-- 생성자 :	이동호
-- 등록일 :	2024.05.17
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : 가상계좌 주문번호 생성
-- 실행문 : 
DECLARE @R_MOID NVARCHAR(100)
EXEC PR_ACCT_ORDER_RETURN_ID @R_MOID OUT
SELECT @R_MOID
*/
CREATE PROCEDURE [dbo].[PR_ACCT_ORDER_RETURN_ID]	
	@R_RETURN_MOID 		NVARCHAR(100)	OUTPUT	--리턴 주문번호
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	BEGIN TRY 
				
		DECLARE @MOID VARCHAR(100) = FORMAT(GETDATE(), 'yyyyMMddHHmmssffff')
		
		--# 중복된 주문번호가 있는지 체크
		IF EXISTS(SELECT MOID FROM PA_ACCT_ISSUE WHERE MOID = @MOID)
		BEGIN
			--# 만약 매칭된 주문번호가 있다면 +1 해준다.
			SET @MOID = CAST((CAST(@MOID AS BIGINT) + 1) AS VARCHAR)
		END

		SET @R_RETURN_MOID = @MOID
						
	END TRY
	BEGIN CATCH		
		--에러 로그 테이블 저장
		INSERT INTO TBL_ERROR_LOG 
		SELECT ERROR_PROCEDURE()	-- 프로시저명
		, ERROR_MESSAGE()			-- 에러메시지
		, ERROR_LINE()				-- 에러라인
		, GETDATE()	
	END CATCH
END

GO

