
/*

-- 생성자 :	강세미
-- 등록일 :	2024.06.03
-- 수정자 : 2024.06.14 강세미 - 매출확정일자 추가, 판매일자 -> 출고일자로 변경
-- 설 명  : 일자별 상품 매출, PR_SL_SALE_PUT에서 호출
-- 실행문 : 

EXEC PR_SL_SALE_ITEM_PUT

*/
CREATE PROCEDURE [dbo].[PR_SL_SALE_ITEM_PUT]
(
	@SALE_DT			NVARCHAR(8),			-- 판매일자(출고일자)
	@R_RETURN_CODE 		INT 			OUTPUT,	-- 리턴코드
	@R_RETURN_MESSAGE 	NVARCHAR(MAX) 	OUTPUT 	-- 리턴메시지
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRAN
	BEGIN TRY 		
		--DECLARE @P INT = 0
		--SET @P = 1/0
			
		--일자별 상품 매출
		MERGE SL_SALE_ITEM AS A
		USING (	
			SELECT 
				SS.SALE_DT AS SALE_DT,							--판매일자(출고일자)
				SS.SCAN_CODE,									--거래처코드
				SS.ITM_CODE,									--거래처코드
				COUNT(DISTINCT OHDR.ORD_NO) AS ORD_CNT,			--주문건수
				SUM(SS.SALE_EA) AS SALE_EA,						--매출수량
				SUM(SS.SALE_KG) AS SALE_KG,						--매출중량
				SUM(SS.SALE_TOTAL_AMT) AS SALE_TOTAL_AMT,		--판매금액
				SS.TAX_GB
			FROM SL_SALE AS SS
				INNER JOIN PO_ORDER_HDR AS OHDR ON SS.ORD_NO = OHDR.ORD_NO
			WHERE SS.SALE_DT = @SALE_DT
			GROUP BY SS.SCAN_CODE, SS.ITM_CODE, SS.SALE_DT, SS.TAX_GB
		) AS B
		ON (
			A.SCAN_CODE  = B.SCAN_CODE AND A.SALE_DT = B.SALE_DT
		)		
		WHEN NOT MATCHED THEN
			INSERT (SALE_DT, SCAN_CODE, ITM_CODE, ORD_CNT, SALE_EA, SALE_KG, SALE_TOTAL_AMT, TAX_GB)
				VALUES (B.SALE_DT, B.SCAN_CODE, B.ITM_CODE, B.ORD_CNT, ISNULL(B.SALE_EA,0), ISNULL(B.SALE_KG,0), ISNULL(B.SALE_TOTAL_AMT,0), B.TAX_GB)
		WHEN MATCHED THEN
			UPDATE SET ORD_CNT = B.ORD_CNT,
					   SALE_EA = B.SALE_EA,
					   SALE_KG = B.SALE_KG,
					   SALE_TOTAL_AMT = B.SALE_TOTAL_AMT,
					   TAX_GB = B.TAX_GB
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
