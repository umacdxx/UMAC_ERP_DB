
/*

-- 생성자 :	윤현빈
-- 등록일 :	2024.07.15
-- 설 명  : 재고실사등록(EXCEL)
-- 실행문 : 

EXEC PR_STOCK_AUDIT_EXCEL_PUT '','','','',''

*/
CREATE PROCEDURE [dbo].[PR_STOCK_AUDIT_EXCEL_PUT]
( 
	@P_SURVEY_ID	NVARCHAR(8) = '',	-- 재고실사ID
	@P_SCAN_CODE	NVARCHAR(14) = '',	-- SCAN_CODE
	@P_LOT_NO		NVARCHAR(30) = '',	-- LOT번호
	@P_SURVEY_QTY	INT,				-- 수중량
	@P_EMP_ID		NVARCHAR(20),		-- 아이디
	@P_INDEX		INT					-- 엑셀 인덱스
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @RETURN_CODE	INT = 0										-- 리턴코드(저장완료)
	DECLARE @RETURN_MESSAGE NVARCHAR(MAX) = DBO.GET_ERR_MSG('0')		-- 리턴메시지
	
	BEGIN TRAN
	BEGIN TRY 
		DECLARE @IS_LOT NVARCHAR(1) = 'Y';
		DECLARE @IS_VALIDATE  NVARCHAR(1) = 'Y';
		DECLARE @V_INV_DT NVARCHAR(8);
		DECLARE @V_SURVEY_GB NVARCHAR(1);
		DECLARE @V_ITM_CODE NVARCHAR(6);
		DECLARE @V_INV_END_QTY INT;
		DECLARE @MAX_SURVEY_ID NVARCHAR(8) = '';
		

		SELECT @V_INV_DT = INV_DT 
		     , @V_SURVEY_GB = SURVEY_GB
			FROM IV_SCHEDULER 
		   WHERE SURVEY_ID = @P_SURVEY_ID
		     AND CFM_FLAG = 'N'
		;

		SELECT @V_ITM_CODE = ITM_CODE 
			FROM CD_PRODUCT_CMN 
		   WHERE SCAN_CODE = @P_SCAN_CODE
		;

		-- validate: SURVEY_ID, SCAN_CODE
		IF @V_INV_DT IS NULL OR @V_SURVEY_GB IS NULL OR @V_ITM_CODE IS NULL
		BEGIN
			SET @IS_VALIDATE = 'N';
		END

		-- validate: LOT_NO
		IF @P_LOT_NO != ''
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM IV_LOT_STAT WHERE SCAN_CODE = @P_SCAN_CODE AND LOT_NO = @P_LOT_NO)
			BEGIN
				SET @IS_LOT = 'N';	
			END
		END

		ELSE
		BEGIN
			IF EXISTS (SELECT 1 FROM IV_LOT_STAT WHERE SCAN_CODE = @P_SCAN_CODE)
			BEGIN
				SET @IS_LOT = 'N';	
			END
		END

		-- validate: SUCCESS 일 때
		IF @IS_LOT = 'Y' AND @IS_VALIDATE = 'Y'
		BEGIN

			SELECT @MAX_SURVEY_ID = MAX(SURVEY_ID)
				FROM IV_SCHEDULER AS A
				WHERE A.CFM_FLAG = 'Y'
					AND A.INV_DT LIKE SUBSTRING(@P_SURVEY_ID, 1, 6) + '%'
					AND A.SURVEY_ID != @P_SURVEY_ID
			;

			IF @MAX_SURVEY_ID IS NOT NULL
			BEGIN
				SELECT @V_INV_END_QTY = MAX(A.SURVEY_QTY_2)
					FROM IV_STOCK_SURVEY AS A
					WHERE A.INV_DT = @V_INV_DT
						AND A.SURVEY_ID = @MAX_SURVEY_ID
						AND A.ITM_CODE = @V_ITM_CODE
						AND A.LOT_NO = @P_LOT_NO
				;
			END

			IF @MAX_SURVEY_ID IS NULL OR @V_INV_END_QTY IS NULL
			BEGIN
				SELECT @V_INV_END_QTY = ISNULL(MAX(A.INV_END_QTY), 0)
					FROM IV_DT_ITEM_LOT_COLL AS A
					WHERE A.INV_DT = CONVERT(VARCHAR(8), DATEADD(DAY, -1, CONVERT(DATE, @V_INV_DT, 112)), 112)
						AND A.ITM_CODE = @V_ITM_CODE
						AND A.LOT_NO = @P_LOT_NO
			END


			MERGE INTO IV_STOCK_SURVEY AS A
				USING (SELECT 1 AS dual) AS B ON A.SURVEY_ID = @P_SURVEY_ID AND SCAN_CODE = @P_SCAN_CODE AND LOT_NO = @P_LOT_NO AND A.INV_FLAG = '2'
			WHEN MATCHED THEN
				UPDATE SET
					--A.SURVEY_QTY_1 = ISNULL(A.SURVEY_QTY_2,  A.SURVEY_QTY_1)
				    A.SURVEY_QTY_2 = @P_SURVEY_QTY
				  , A.UDATE = GETDATE()
				  , A.UEMP_ID = @P_EMP_ID
			WHEN NOT MATCHED THEN
				INSERT 
				(
					INV_DT
				  , ITM_CODE
				  , SCAN_CODE
				  , SURVEY_ID
				  , LOT_NO
				  , SURVEY_QTY_1
				  , SURVEY_QTY_2
				  , SURVEY_GB
				  , INV_FLAG
				  , IDATE
				  , IEMP_ID
				)
				VALUES
				(
					@V_INV_DT
				  , @V_ITM_CODE
				  , @P_SCAN_CODE
				  , @P_SURVEY_ID
				  , @P_LOT_NO
				  , @V_INV_END_QTY
				  , @P_SURVEY_QTY
				  , @V_SURVEY_GB
				  , '2'
				  , GETDATE()
				  , @P_EMP_ID
				)
			;

			SET @RETURN_CODE = 0; -- 저장완료
			SET @RETURN_MESSAGE = DBO.GET_ERR_MSG('0');
		END

		-- validate: FAIL 일 때
		ELSE
		BEGIN
			SET @RETURN_CODE = -2; -- 엑셀업로드 validate 실패, @RETURN_MESSAGE에 실패 인덱스 담아서 화면에서 alert 처리
			SET @RETURN_MESSAGE = @P_INDEX+2;

		END

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
