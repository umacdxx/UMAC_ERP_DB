

/*

-- 생성자 :	이동호
-- 등록일 :	2024.11.29
-- 수정자 : 
-- 수정일 : 
-- 설 명  : 입금내역 주문별 매출 등록
-- 실행문 : 

SET @P_ORDER_LIST = '[{"ORD_NO":"2240617001"}]'
SET @P_VEN_CODE = ''
SET @P_EMP_ID = ''

*/
CREATE PROCEDURE [dbo].[PR_ACCT_DEPOSIT_ORD_HDR_PUT]
( 
	
	@P_ORDER_LIST		NVARCHAR(MAX) = '',
	@P_EMP_ID			VARCHAR(20) = '',		
	@R_RETURN_CODE 		INT 			OUTPUT,		-- 리턴코드
	@R_RETURN_MESSAGE 	NVARCHAR(2000) 	OUTPUT 		-- 리턴메시지
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SET @R_RETURN_CODE = 0		-- 리턴코드
	SET @R_RETURN_MESSAGE = ''	-- 리턴메시지
		
	DECLARE @VEN_CODE	NVARCHAR(7) = ''
	DECLARE @JSONDT		NVARCHAR(MAX) = ''		
	DECLARE @ORDER_TBL TABLE (
		ORD_NO NVARCHAR(11)
	)


	INSERT INTO @ORDER_TBL
		SELECT ORD_NO FROM 
			OPENJSON ( @P_ORDER_LIST )   
				WITH (    
					ORD_NO NVARCHAR(11) '$.ORD_NO'									
				)
		WHERE LEFT(ORD_NO,1) = '2'


	BEGIN TRAN
	BEGIN TRY 	
		
		-- ***********************************************
		-- 주문별 입금처리내역 등록(PA_ACCT_DEPOSIT_ORD)
		-- ***********************************************		
		MERGE PA_ACCT_DEPOSIT_ORD AS A
		USING (			
			SELECT 
				SL.SALE_DT, 
				SL.ORD_NO, 
				SL.VEN_CODE,
				ISNULL(SUM(SL.SALE_TOTAL_AMT),0) AS DEPOSIT_AMT_SUM
			FROM SL_SALE AS SL 
				INNER JOIN @ORDER_TBL AS OT 
					ON SL.ORD_NO = OT.ORD_NO
				GROUP BY SL.SALE_DT, SL.ORD_NO, SL.VEN_CODE
		) AS B
		ON (
			A.ORD_NO  = B.ORD_NO AND A.SALE_TOTAL_AMT > 0
		)		
		WHEN NOT MATCHED THEN		
			INSERT (SALE_DT, ORD_NO, VEN_CODE, SALE_TOTAL_AMT, DEPOSIT_GB, DEPOSIT_NO, MOID, DEPOSIT_AMT, DEPOSIT_DT, DEPOSIT_FISH, DEL_YN, IDATE)
				VALUES (B.SALE_DT, B.ORD_NO, B.VEN_CODE, B.DEPOSIT_AMT_SUM, '', '', '', 0, '', CASE WHEN B.DEPOSIT_AMT_SUM = 0 THEN 'Y' ELSE 'N' END, 'N', GETDATE())
		WHEN MATCHED THEN
			UPDATE SET SALE_TOTAL_AMT = B.DEPOSIT_AMT_SUM, SALE_DT = B.SALE_DT
		;
		 
		-- ****************************************************************
		-- 거래처에 초과된 입금액이 있으면 주문확정시 해당 금액 차감 처리	
		-- ****************************************************************
		DECLARE @SALE_TOTAL_AMT		NUMERIC(17,4),
				@DEPOSIT_ORD_AMT	NUMERIC(17,4),
				@DEPOSIT_AMT		NUMERIC(17,4)

		DECLARE CURSOR_VEN_CODE	CURSOR FOR
			SELECT SL.VEN_CODE FROM SL_SALE AS SL 
				INNER JOIN @ORDER_TBL AS OT ON SL.ORD_NO = OT.ORD_NO 
					GROUP BY SL.VEN_CODE
		OPEN CURSOR_VEN_CODE

		FETCH NEXT FROM CURSOR_VEN_CODE INTO @VEN_CODE
		WHILE(@@FETCH_STATUS=0)
		BEGIN		
				
			--해당거래처의 매출총합, 입금총합
			SELECT @SALE_TOTAL_AMT = SUM(SALE_TOTAL_AMT), @DEPOSIT_ORD_AMT = SUM((CASE WHEN DEPOSIT_AMT < 0 THEN -DEPOSIT_AMT ELSE DEPOSIT_AMT END)) FROM PA_ACCT_DEPOSIT_ORD WHERE VEN_CODE = @VEN_CODE
			--해당거래처의 입금한 금액의 총합
			SELECT @DEPOSIT_AMT = SUM(DEPOSIT_AMT) FROM PA_ACCT_DEPOSIT WHERE VEN_CODE = @VEN_CODE

			--해당 거래처에 초과 입금된 금액이 있거나, 선입금이 있는 거래처가 일경우 
			--IF((SELECT COUNT(1) AS CNT FROM PA_ACCT_DEPOSIT_ORD WHERE VEN_CODE = @VEN_CODE AND DEPOSIT_AMT < 0) > 0) OR (@DEPOSIT_ORD_AMT = 0 AND @DEPOSIT_AMT > 0)
			--총 매출 금액과 입금된 금액이 틀리고 입금처리된 금액이 있을 경우 
			IF ((SELECT COUNT(1) AS CNT FROM PA_ACCT_DEPOSIT_ORD WHERE VEN_CODE = @VEN_CODE AND @DEPOSIT_AMT > 0) > 0 )
			BEGIN	
										
					--[{"DEPOSIT_DT":"20241202","DEPOSIT_GB_NAME":"","DEPOSIT_AMT":0,"MODE":"I","DEPOSIT_NO":"","VEN_CODE":"UM29999"}]
					
					SET @JSONDT = (				
						SELECT 
							CONVERT(CHAR(8), GETDATE(), 112) AS DEPOSIT_DT, 
							'' AS DEPOSIT_GB_NAME, 
							0 AS DEPOSIT_AMT, 
							'I' AS MODE, 
							0 AS DEPOSIT_NO, 
							@VEN_CODE AS VEN_CODE													
						FOR JSON PATH
					)										
					
					EXEC PR_ACCT_DEPOSIT_MANUAL_PUT @JSONDT, @P_EMP_ID, @R_RETURN_CODE OUT, @R_RETURN_MESSAGE OUT;

					--SET @JSONDT = (				
					--	SELECT 
					--		'' AS MOID, 
					--		'' AS DEPOSIT_DT, 
					--		'' AS DEPOSIT_GB_NAME, 
					--		'' AS DEPOSIT_NO, 
					--		0 AS DEPOSIT_AMT, 
					--		'' AS ISSUER_CODE, 
					--		'' AS APP_NO, 
					--		@VEN_CODE AS VEN_CODE, 
					--		'' AS IEMP_ID											
					--	FOR JSON PATH
					--)										
					--EXEC PR_ACCT_DEPOSIT_MANUAL_PUT @JSONDT, @P_EMP_ID, @R_RETURN_CODE OUT, @R_RETURN_MESSAGE OUT;
			END 
													
		FETCH NEXT FROM CURSOR_VEN_CODE INTO @VEN_CODE

		END

		CLOSE CURSOR_VEN_CODE
		DEALLOCATE CURSOR_VEN_CODE
		--//	

		COMMIT;

	END TRY
	BEGIN CATCH	
				
		IF @@TRANCOUNT > 0
		BEGIN 
		
			ROLLBACK TRAN
		
			IF CURSOR_STATUS('global', 'CURSOR_VEN_CODE') >= 0
			BEGIN
				CLOSE CURSOR_VEN_CODE;
				DEALLOCATE CURSOR_VEN_CODE;
			END

						
			--에러 로그 테이블 저장
			INSERT INTO TBL_ERROR_LOG 
			SELECT ERROR_PROCEDURE()			-- 프로시저명
					, ERROR_MESSAGE()			-- 에러메시지
					, ERROR_LINE()				-- 에러라인
					, GETDATE()	

			
			SET @R_RETURN_CODE = -1
			SET @R_RETURN_MESSAGE = ERROR_MESSAGE()
			
		END 
	END CATCH
	
END

GO

