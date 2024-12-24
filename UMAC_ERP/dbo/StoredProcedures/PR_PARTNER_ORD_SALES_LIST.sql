/*
-- 생성자 :	강세미
-- 등록일 :	2024.06.04
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : 거래처 주문별 매출조회
-- 실행문 : EXEC PR_PARTNER_ORD_SALES_LIST 'UM20030'
*/
CREATE PROCEDURE [dbo].[PR_PARTNER_ORD_SALES_LIST]
	@P_VEN_CODE			VARCHAR(7),	-- 거래처코드
	@P_FROM_SALE_DT		VARCHAR(8),	-- 조회시작일자
	@P_TO_SALE_DT		VARCHAR(8)	-- 조회종료일자
AS 
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY 

		SELECT ROW_NUMBER() OVER(ORDER BY A.SALE_DT DESC) AS ROW_NUM,
			   A.SALE_DT,
			   A.VEN_CODE,
			   A.ORD_NO,
			   SUM(A.SALE_TOTAL_AMT) AS SALE_TOTAL_AMT,
			   --A.SALE_TOTAL_AMT,
			   B.DELIVERY_DEC_DT,
			   ISNULL(C.PRODUCT_WGHT,0) AS PRODUCT_WGHT,
			   ISNULL(D.DELIVERY_NAME, '배송지코드 없음') AS DELIVERY_NAME,
			   ISNULL(E.OFFICIAL_WGHT,0) AS OFFICIAL_WGHT,
			   ISNULL(E.NET_WGHT,0) AS NET_WGHT,
			   F.VEN_NAME
		FROM SL_SALE AS A
			INNER JOIN PO_ORDER_HDR AS B ON A.ORD_NO = B.ORD_NO
			INNER JOIN (SELECT ODTL.ORD_NO,
								CAST(SUM(CASE WHEN CMN.WEIGHT_GB = 'QTY' THEN ROUND(CONVERT(FLOAT, CMN.UNIT_WEIGHT) / 1000, 2, 0) * ODTL.PICKING_QTY
									     WHEN CMN.WEIGHT_GB = 'WT' THEN ODTL.PICKING_QTY END) AS INT) AS PRODUCT_WGHT
						FROM PO_ORDER_DTL AS ODTL
							INNER JOIN CD_PRODUCT_CMN CMN ON ODTL.SCAN_CODE = CMN.SCAN_CODE
						GROUP BY ODTL.ORD_NO
						) AS C ON A.ORD_NO = C.ORD_NO
			LEFT OUTER JOIN CD_PARTNER_DELIVERY AS D ON D.DELIVERY_CODE = B.DELIVERY_CODE AND D.VEN_CODE = B.VEN_CODE
			LEFT OUTER JOIN PO_SCALE AS E ON A.ORD_NO = E.ORD_NO
			INNER JOIN CD_PARTNER_MST AS F ON A.VEN_CODE = F.VEN_CODE
		WHERE A.SALE_DT BETWEEN @P_FROM_SALE_DT AND @P_TO_SALE_DT
			AND A.VEN_CODE = @P_VEN_CODE
		GROUP BY A.SALE_DT, A.VEN_CODE, A.ORD_NO, B.DELIVERY_DEC_DT, C.PRODUCT_WGHT, D.DELIVERY_NAME, E.OFFICIAL_WGHT, E.NET_WGHT, F.VEN_NAME

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

