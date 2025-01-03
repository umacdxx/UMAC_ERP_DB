
/*
-- 생성자 :	이동호
-- 등록일 :	2024.05.21
-- 설 명  : 모바일(앱) 지시서 상세 상품 LOT별 피킹 수량 출력
			
-- 수정자 : -
-- 수정일 : - 
-- 실행문 : 

EXEC PR_MO_WMS_ORD_PRODUCT_LOT_LIST '2240523002'

*/
CREATE PROCEDURE [dbo].[PR_MO_WMS_ORD_PRODUCT_LOT_LIST]
( 	
	@P_ORD_NO			NVARCHAR(11) = ''		-- 주문번호	
	--@P_SCAN_CODE		NVARCHAR(14) = ''		-- 상품 스캔코드
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY 
		
		
		SELECT 
			OLOT.ORD_NO, 
			OLOT.SCAN_CODE, 
			OLOT.LOT_NO, 
			LMST.EXPIRATION_DT,
			ISNULL(OLOT.PICKING_QTY, 0) AS PICKING_QTY
		FROM PO_ORDER_DTL AS ODTL
			INNER JOIN PO_ORDER_LOT AS OLOT
			ON ODTL.ORD_NO = OLOT.ORD_NO AND ODTL.SCAN_CODE = OLOT.SCAN_CODE
			LEFT OUTER JOIN VIEW_CD_LOT_MST AS LMST
			ON OLOT.LOT_NO = LMST.LOT_NO
			WHERE ODTL.ORD_NO = @P_ORD_NO 
			--AND ODTL.SCAN_CODE = @P_SCAN_CODE
				
	
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

