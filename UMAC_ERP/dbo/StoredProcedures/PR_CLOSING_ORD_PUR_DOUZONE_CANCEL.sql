
/*

-- 생성자 :	윤현빈
-- 등록일 :	2024.12.04
-- 설 명  : 더존 마감 취소
-- 실행문 : 

EXEC PR_CLOSING_ORD_PUR_DOUZONE_CANCEL '',''

*/
CREATE PROCEDURE [dbo].[PR_CLOSING_ORD_PUR_DOUZONE_CANCEL]
( 
	@P_JSONDT			VARCHAR(8000) = '',
	@P_GRE_GB			NVARCHAR(1),
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
			CLOSE_NO NVARCHAR(11),
			VEN_CODE NVARCHAR(7),
			CLOSE_MON NVARCHAR(2)
		)
		
		INSERT INTO @TMP_ITEM
		SELECT CLOSE_NO, VEN_CODE, CLOSE_MON
			FROM 
				OPENJSON ( @P_JSONDT )   
					WITH (    
						CLOSE_NO NVARCHAR(11) '$.CLOSE_NO',
						VEN_CODE NVARCHAR(11) '$.VEN_CODE',
						CLOSE_MON NVARCHAR(11) '$.CLOSE_MON'
					)
				
		DECLARE CURSOR_DATA CURSOR FOR

			SELECT A.CLOSE_NO, A.VEN_CODE, A.CLOSE_MON
				FROM @TMP_ITEM A
			
		OPEN CURSOR_DATA

		DECLARE @P_CLOSE_NO NVARCHAR(8),
				@P_VEN_CODE NVARCHAR(7),
				@P_CLOSE_MON NVARCHAR(2)

		FETCH NEXT FROM CURSOR_DATA INTO @P_CLOSE_NO, @P_VEN_CODE, @P_CLOSE_MON

			WHILE(@@FETCH_STATUS=0)
			BEGIN
			
				IF @P_GRE_GB = '1'
				BEGIN
					UPDATE PO_PURCHASE_HDR 
						SET DOUZONE_FLAG = 'N'
						  , UDATE = GETDATE()
						  , UEMP_ID = @P_EMP_ID
					   WHERE VEN_CODE = @P_VEN_CODE
					     AND SUBSTRING(CLOSE_DT, 5, 2) = @P_CLOSE_MON
					;
				END

				ELSE IF @P_GRE_GB = '2'
				BEGIN
					UPDATE PO_ORDER_HDR 
						SET DOUZONE_FLAG = 'N'
						  , UDATE = GETDATE()
						  , UEMP_ID = @P_EMP_ID
					   WHERE CLOSE_NO = @P_CLOSE_NO
					     AND SUBSTRING(CLOSE_DT, 5, 2) = @P_CLOSE_MON
					;
				END

				FETCH NEXT FROM CURSOR_DATA INTO @P_CLOSE_NO, @P_VEN_CODE, @P_CLOSE_MON

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

	END CATCH
	SELECT @RETURN_CODE AS RETURN_CODE, @RETURN_MESSAGE AS RETURN_MESSAGE 
END

GO

