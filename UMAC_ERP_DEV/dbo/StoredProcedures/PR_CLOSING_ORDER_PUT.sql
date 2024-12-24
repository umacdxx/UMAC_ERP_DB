
/*

-- 생성자 :	윤현빈
-- 등록일 :	2024.09.12
-- 수정자 : 2024.10.28 강세미 : 로직변경
-- 설 명  : 건별 마감데이터 저장
-- 실행문 : 

EXEC PR_CLOSING_ORDER_PUT '[{"ISSUE_GB":"1", "ORD_NO":"2240923009", "CLOSE_DT": "20241001","CLOSE_REMARKS":"하하하"},
{"ISSUE_GB":"1", "ORD_NO":"2240923010", "CLOSE_DT": "20241001","CLOSE_REMARKS":"히히히"}]','admin'

*/
CREATE PROCEDURE [dbo].[PR_CLOSING_ORDER_PUT]
( 
	@P_JSONDT			VARCHAR(MAX) = '',
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
				ORD_NO NVARCHAR(11),
				ISSUE_GB NVARCHAR(1),
				CLOSE_DT NVARCHAR(8),
				CLOSE_REMARKS NVARCHAR(2000)
		)
		
		INSERT INTO @TMP_ITEM
		SELECT ORD_NO, ISSUE_GB, CLOSE_DT, CLOSE_REMARKS
			FROM 
				OPENJSON ( @P_JSONDT )   
					WITH (    
						ORD_NO NVARCHAR(11) '$.ORD_NO',
						ISSUE_GB NVARCHAR(1) '$.ISSUE_GB',
						CLOSE_DT NVARCHAR(8) '$.CLOSE_DT',
						CLOSE_REMARKS NVARCHAR(2000) '$.CLOSE_REMARKS'
					)
				
		DECLARE CURSOR_REMARKS CURSOR FOR

		SELECT A.ORD_NO, A.ISSUE_GB, A.CLOSE_DT, A.CLOSE_REMARKS
			FROM @TMP_ITEM A
			

		OPEN CURSOR_REMARKS

		DECLARE @P_ORD_NO NVARCHAR(11),
				@P_ISSUE_GB NVARCHAR(1),
				@P_CLOSE_DT NVARCHAR(8),
				@P_CLOSE_REMARKS NVARCHAR(2000)

		FETCH NEXT FROM CURSOR_REMARKS INTO @P_ORD_NO, @P_ISSUE_GB, @P_CLOSE_DT, @P_CLOSE_REMARKS

			WHILE(@@FETCH_STATUS=0)
			BEGIN
			
			-- ************************************************************
			-- PO_ORDER_HDR 업데이트
			-- ************************************************************
			UPDATE PO_ORDER_HDR 
			   SET ISSUE_GB = @P_ISSUE_GB,
				   CLOSE_DT = @P_CLOSE_DT,
				   CLOSE_REMARKS = @P_CLOSE_REMARKS
			WHERE ORD_NO = @P_ORD_NO
			
				FETCH NEXT FROM CURSOR_REMARKS INTO @P_ORD_NO, @P_ISSUE_GB, @P_CLOSE_DT, @P_CLOSE_REMARKS

			END

		CLOSE CURSOR_REMARKS
		DEALLOCATE CURSOR_REMARKS

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

