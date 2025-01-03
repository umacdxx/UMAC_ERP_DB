/*
-- 생성자 :	강세미
-- 등록일 :	2023.12.20
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : 공통코드 중복 체크
-- 실행문 : EXEC PR_COMM_CODE_DUPL_CHECK 'IM_'
*/
CREATE PROCEDURE [dbo].[PR_COMM_CODE_DUPL_CHECK]
	@P_CD_ID		   VARCHAR(100) = ''	-- 공통코드
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @DUPL_CNT			INT
	DECLARE @RETURN_CODE		INT
	DECLARE @RETURN_MESSAGE VARCHAR(50)

	BEGIN TRY 
	 SELECT @DUPL_CNT = COUNT(1) 
	   FROM TBL_COMM_CD_MST
	  WHERE CD_CL = '0000'
	    AND CD_ID = @P_CD_ID

	 IF @DUPL_CNT > 0 
		BEGIN
			SET @RETURN_CODE = 9
			SET @RETURN_MESSAGE = '중복 코드가 존재합니다.'
		END
	 ELSE
		BEGIN
			SET @RETURN_CODE = 0
			SET @RETURN_MESSAGE = '중복 코드가 없습니다.'
		END

	SELECT @RETURN_CODE AS RETURN_CODE, 
		   @RETURN_MESSAGE AS RETURN_MESSAGE

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

