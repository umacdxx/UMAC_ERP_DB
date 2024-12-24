
/*

-- 생성자 :	윤현빈
-- 등록일 :	2024.11.12
-- 설 명  : 생산일보 비고 저장
-- 실행문 : 

EXEC PR_ANALYSIS_DAILY_PROD_REMARKS_PUT '','','','',''

*/
CREATE PROCEDURE [dbo].[PR_ANALYSIS_DAILY_PROD_REMARKS_PUT]
( 
	@P_JSONDT			VARCHAR(8000) = '',
	@P_EMP_ID			NVARCHAR(20)				-- 아이디
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @RETURN_CODE	INT = 0										-- 리턴코드(저장완료)
	DECLARE @RETURN_MESSAGE NVARCHAR(MAX) = DBO.GET_ERR_MSG('0')		-- 리턴메시지
	
	BEGIN TRAN
	BEGIN TRY 

		DECLARE @TMP_ITEM TABLE (
			REPORT_DATE NVARCHAR(8),
			PARTNER_GB NVARCHAR(2),
			ITM_CATEGORY NVARCHAR(2),
			SCAN_CODE NVARCHAR(14),
			R_YN	NVARCHAR(1),
			REMARKS NVARCHAR(2000),
			MODE NVARCHAR(1)
		)
		
		INSERT INTO @TMP_ITEM
		SELECT REPORT_DATE, PARTNER_GB, ITM_CATEGORY, SCAN_CODE, R_YN, REMARKS, MODE
			FROM 
				OPENJSON ( @P_JSONDT )   
					WITH (    
						REPORT_DATE NVARCHAR(8) '$.REPORT_DATE',
						PARTNER_GB NVARCHAR(2) '$.PARTNER_GB',
						ITM_CATEGORY NVARCHAR(2) '$.ITM_CATEGORY',
						SCAN_CODE NVARCHAR(14) '$.SCAN_CODE',
						R_YN NVARCHAR(14) '$.R_YN',
						REMARKS NVARCHAR(2000) '$.REMARKS',
						MODE NVARCHAR(1) '$.MODE'
					)
				
		DECLARE CURSOR_DATA CURSOR FOR

			SELECT A.REPORT_DATE, A.PARTNER_GB, A.ITM_CATEGORY, A.SCAN_CODE, A.R_YN, A.REMARKS, MODE 
				FROM @TMP_ITEM A
			
		OPEN CURSOR_DATA

		DECLARE @P_REPORT_DATE NVARCHAR(8),
				@P_PARTNER_GB NVARCHAR(2),
				@P_ITM_CATEGORY NVARCHAR(2),
				@P_SCAN_CODE NVARCHAR(14),
				@P_R_YN	NVARCHAR(1),
				@P_REMARKS NVARCHAR(2000),
				@P_MODE NVARCHAR(1)

		FETCH NEXT FROM CURSOR_DATA INTO @P_REPORT_DATE, @P_PARTNER_GB, @P_ITM_CATEGORY, @P_SCAN_CODE, @P_R_YN, @P_REMARKS, @P_MODE

			WHILE(@@FETCH_STATUS=0)
			BEGIN

				MERGE INTO RP_ANALYSIS_DAILY_PROD AS A
					USING (SELECT 1 AS DUAL) AS B
					ON (
						A.REPORT_MON = LEFT(@P_REPORT_DATE, 6)
					AND A.PARTNER_GB = @P_PARTNER_GB
					AND A.ITM_CATEGORY = @P_ITM_CATEGORY
					AND A.SCAN_CODE = @P_SCAN_CODE
					AND A.R_YN = @P_R_YN
					)
				WHEN MATCHED THEN 
					UPDATE SET
						REMARKS = @P_REMARKS
					  , UDATE = GETDATE()
					  , UEMP_ID = @P_EMP_ID
					  
				WHEN NOT MATCHED THEN
					INSERT
					(
						REPORT_MON
					  , PARTNER_GB
					  , ITM_CATEGORY
					  , SCAN_CODE
					  , R_YN
					  , REMARKS
					  , IDATE
					  , IEMP_ID
					)
					VALUES
					(
						LEFT(@P_REPORT_DATE, 6)
					  , @P_PARTNER_GB
					  , @P_ITM_CATEGORY
					  , @P_SCAN_CODE
					  , @P_R_YN
					  , @P_REMARKS
					  , GETDATE()
					  , @P_EMP_ID
					)
				;

				FETCH NEXT FROM CURSOR_DATA INTO @P_REPORT_DATE, @P_PARTNER_GB, @P_ITM_CATEGORY, @P_SCAN_CODE, @P_R_YN, @P_REMARKS, @P_MODE

			END

		CLOSE CURSOR_DATA
		DEALLOCATE CURSOR_DATA

	COMMIT;
	END TRY
	
	BEGIN CATCH	
		
		IF @@TRANCOUNT > 0
		BEGIN 
			ROLLBACK TRAN
			SET @RETURN_CODE = -1
			SET @RETURN_MESSAGE = ERROR_MESSAGE()

			--에러 로그 테이블 저장
			INSERT INTO TBL_ERROR_LOG 
			SELECT ERROR_PROCEDURE()		-- 프로시저명
				, ERROR_MESSAGE()			-- 에러메시지
				, ERROR_LINE()				-- 에러라인
				, GETDATE()	
		END 
		
		SELECT @RETURN_CODE AS RETURN_CODE, @RETURN_MESSAGE AS RETURN_MESSAGE 

	END CATCH
	SELECT @RETURN_CODE AS RETURN_CODE, @RETURN_MESSAGE AS RETURN_MESSAGE 
END

GO

