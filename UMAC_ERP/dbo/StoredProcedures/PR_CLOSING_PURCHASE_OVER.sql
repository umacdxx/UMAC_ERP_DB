
/*

-- 생성자 :	강세미
-- 등록일 :	2024.09.27
-- 수정일 : 2024.10.29 강세미 - 이월, 전월처리 로직 변경
-- 설 명  : 월 매입마감 이월처리
-- 실행문 : 

EXEC PR_CLOSING_PURCHASE_OVER '[{"ORD_NO":"2241011003","CLOSE_REMARKS":null, "OVER_TYPE":"PRE"}]','admin'
EXEC PR_CLOSING_PURCHASE_OVER '[{"ORD_NO":"2241011003","CLOSE_REMARKS":null, "OVER_TYPE":"NEXT"}]','admin'

*/
CREATE PROCEDURE [dbo].[PR_CLOSING_PURCHASE_OVER]
( 
	@P_JSONDT			VARCHAR(MAX) = '',
	@P_EMP_ID			NVARCHAR(20)				-- 아이디
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @RETURN_CODE	INT = 0										-- 리턴코드(저장완료)
	DECLARE @RETURN_MESSAGE NVARCHAR(MAX) = DBO.GET_ERR_MSG('0')		-- 리턴메시지
	DECLARE @PRE_MONTH_DT NVARCHAR(8) -- 전월처리 시 변경될 마감일자(출고일 기준 전월 말일)
	DECLARE @NEXT_MONTH_DT NVARCHAR(8) -- 이월처리 시 변경될 마감일자(출고일 기준 익월 1일)
	
	BEGIN TRAN
	BEGIN TRY 
		DECLARE @TMP_ITEM TABLE (
				ORD_NO NVARCHAR(11),
				CLOSE_REMARKS NVARCHAR(2000),
				OVER_TYPE NVARCHAR(10)
		)
		
		INSERT INTO @TMP_ITEM
		SELECT ORD_NO, CLOSE_REMARKS, OVER_TYPE
			FROM 
				OPENJSON ( @P_JSONDT )   
					WITH (    
						ORD_NO NVARCHAR(11) '$.ORD_NO',
						CLOSE_REMARKS NVARCHAR(2000) '$.CLOSE_REMARKS',
						OVER_TYPE NVARCHAR(10) '$.OVER_TYPE'
					)
				
		DECLARE CURSOR_REMARKS CURSOR FOR

			SELECT A.ORD_NO, A.CLOSE_REMARKS, A.OVER_TYPE
				FROM @TMP_ITEM A
			
		OPEN CURSOR_REMARKS

		DECLARE @P_ORD_NO NVARCHAR(11),
				@P_CLOSE_REMARKS NVARCHAR(2000),
				@P_OVER_TYPE NVARCHAR(10)

		FETCH NEXT FROM CURSOR_REMARKS INTO @P_ORD_NO, @P_CLOSE_REMARKS, @P_OVER_TYPE

			WHILE(@@FETCH_STATUS=0)
			BEGIN
				
				-- ************************************************************
				-- 1. 마감일자, 비고 수정
				-- ************************************************************
				IF @P_OVER_TYPE = 'PRE' --전월처리
				BEGIN
					-- 출고일 기준 전월 말일 세팅
					SELECT @PRE_MONTH_DT = CONVERT(VARCHAR(8),EOMONTH(DATEADD(MONTH, -1, DELIVERY_IN_DT)), 112) 
					  FROM PO_PURCHASE_HDR
					 WHERE ORD_NO = @P_ORD_NO

					UPDATE PO_PURCHASE_HDR
					   SET CLOSE_DT = @PRE_MONTH_DT,
						   CLOSE_REMARKS = @P_CLOSE_REMARKS,
						   UDATE = GETDATE(),
						   UEMP_ID = @P_EMP_ID
					 WHERE ORD_NO = @P_ORD_NO
				END
				ELSE IF @P_OVER_TYPE = 'NEXT' --이월처리
				BEGIN
					-- 출고일 기준 익월 1일 세팅
					SELECT @NEXT_MONTH_DT = CONVERT(VARCHAR(8),DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(DELIVERY_IN_DT), MONTH(DELIVERY_IN_DT), 1)), 112) 
					  FROM PO_PURCHASE_HDR
					 WHERE ORD_NO = @P_ORD_NO

					UPDATE PO_PURCHASE_HDR
					   SET CLOSE_DT = @NEXT_MONTH_DT,
						   CLOSE_REMARKS = @P_CLOSE_REMARKS,
						   UDATE = GETDATE(),
						   UEMP_ID = @P_EMP_ID
					 WHERE ORD_NO = @P_ORD_NO
				END
				ELSE IF @P_OVER_TYPE = 'CANCEL' --취소
				BEGIN
					UPDATE PO_PURCHASE_HDR
					   SET CLOSE_DT = DELIVERY_IN_DT,
						   CLOSE_REMARKS = @P_CLOSE_REMARKS,
						   UDATE = GETDATE(),
						   UEMP_ID = @P_EMP_ID
					 WHERE ORD_NO = @P_ORD_NO
				END

				FETCH NEXT FROM CURSOR_REMARKS INTO @P_ORD_NO, @P_CLOSE_REMARKS, @P_OVER_TYPE

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

