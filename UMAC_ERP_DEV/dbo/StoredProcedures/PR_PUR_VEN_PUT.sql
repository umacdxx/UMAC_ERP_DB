
/*

-- 생성자 :	강세미
-- 등록일 :	2024.06.27
-- 수정자 : 
-- 설 명  : 일자별 거래처 매입
-- 실행문 : 

EXEC PR_PUR_VEN_PUT

*/
CREATE PROCEDURE [dbo].[PR_PUR_VEN_PUT]
(
	@PUR_DT				NVARCHAR(8),			-- 매입일자(입고일자)
	@R_RETURN_CODE 		INT 			OUTPUT,	-- 리턴코드
	@R_RETURN_MESSAGE 	NVARCHAR(MAX) 	OUTPUT 	-- 리턴메시지
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRAN
	BEGIN TRY 				
		--입고일자별 거래처 매입
		MERGE PUR_VEN AS A
		USING (			
			SELECT 
				PUR.PUR_DT AS PUR_DT,							--매입일자(입고일자)
				PUR.VEN_CODE,									--거래처코드
				COUNT(DISTINCT PHDR.ORD_NO) AS ORD_CNT,			--주문건수
				SUM(PUR.PUR_TOTAL_AMT) AS PUR_TOTAL_AMT		--판매금액
			FROM PUR_INFO AS PUR
				INNER JOIN PO_PURCHASE_HDR AS PHDR ON PUR.ORD_NO = PHDR.ORD_NO
			WHERE PUR.PUR_DT = @PUR_DT
			GROUP BY PUR.PUR_DT, PUR.VEN_CODE
		) AS B
		ON (
			A.PUR_DT = B.PUR_DT AND A.VEN_CODE  = B.VEN_CODE
		)		
		WHEN NOT MATCHED THEN
			INSERT (PUR_DT, VEN_CODE, ORD_CNT, PUR_TOTAL_AMT)
				VALUES (B.PUR_DT, B.VEN_CODE, B.ORD_CNT, ISNULL(B.PUR_TOTAL_AMT,0))
		WHEN MATCHED THEN
			UPDATE SET ORD_CNT = B.ORD_CNT,
					   PUR_TOTAL_AMT = B.PUR_TOTAL_AMT
		;		
		
		SET @R_RETURN_CODE = 0							
		SET @R_RETURN_MESSAGE = DBO.GET_ERR_MSG('0')
		
	COMMIT;
	END TRY
	
	BEGIN CATCH	
		
		IF @@TRANCOUNT > 0
		BEGIN 
			ROLLBACK TRAN
			
			--에러 로그 테이블 저장
			INSERT INTO TBL_ERROR_LOG 
			SELECT ERROR_PROCEDURE()		-- 프로시저명
				, ERROR_MESSAGE()			-- 에러메시지
				, ERROR_LINE()				-- 에러라인
				, GETDATE()	

			SET @R_RETURN_CODE = -80
			SET @R_RETURN_MESSAGE = ERROR_MESSAGE()
		END 

	END CATCH
	
END

GO

