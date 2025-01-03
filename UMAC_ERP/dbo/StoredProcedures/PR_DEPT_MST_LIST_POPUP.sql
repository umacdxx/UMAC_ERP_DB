/*
-- 생성자 :	강세미
-- 등록일 :	2024.01.05
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : 조직 리스트 출력(Popup)
-- 실행문 : 
EXEC PR_DEPT_MST_LIST_POPUP ''
*/
CREATE PROCEDURE [dbo].[PR_DEPT_MST_LIST_POPUP]
(
	@P_DEPT_CODE	NVARCHAR(25) = ''				-- 조직코드
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	SET @P_DEPT_CODE = ISNULL(@P_DEPT_CODE, '')
	
	BEGIN TRY 	
		WITH TEMP_TBL
		AS (
			SELECT 
				DEPT_CODE,
				DEPT_NAME,
				UPPER_DEPT,     
				GRADE,
				USE_YN,
				CONVERT(VARCHAR(50), DEPT_CODE) AS SORT,
				CONVERT(VARCHAR(20), '') AS UPPER_DEPT_NAME 
			FROM TBL_DEPT_MST
			WHERE  UPPER_DEPT = 0
			UNION ALL
			SELECT 
				DM.DEPT_CODE,
				DM.DEPT_NAME,
				DM.UPPER_DEPT,
				DM.GRADE,
				DM.USE_YN,
				CONVERT(VARCHAR(50), CONVERT(NVARCHAR, TT.SORT) + N' > ' + CONVERT(VARCHAR(255), dbo.FN_DEPT_CODE_SORT_CH(DM.DEPT_CODE,DM.SORT_ORDER))) SORT,
				CONVERT(VARCHAR(20),TT.DEPT_NAME) AS UPPER_DEPT_NAME
			FROM TBL_DEPT_MST AS DM,
				TEMP_TBL AS TT
			WHERE  DM.UPPER_DEPT = TT.DEPT_CODE
		)
		SELECT DEPT_CODE,
				DEPT_NAME,
				UPPER_DEPT,     
				GRADE,
				USE_YN,
				UPPER_DEPT_NAME
			FROM TEMP_TBL 
			WHERE USE_YN = 'Y' 
			  AND (DEPT_CODE LIKE '%' + @P_DEPT_CODE + '%' 
				   OR DEPT_NAME LIKE '%' + @P_DEPT_CODE + '%')
		ORDER BY SORT
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

