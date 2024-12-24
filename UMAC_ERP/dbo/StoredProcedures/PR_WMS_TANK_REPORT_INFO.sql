/*

-- 생성자 :	강세미
-- 등록일 :	2024.07.24
-- 수정자 : -
-- 설 명  : 입출고예정조회 > 탱크로리 표시사항
-- 실행문 : 
-- 수정 : 2024.11.07 윤현빈, 시험성적서용 명칭 추가
EXEC PR_WMS_TANK_REPORT_INFO '2240930012'

*/
CREATE PROCEDURE [dbo].[PR_WMS_TANK_REPORT_INFO]
( 

	@P_ORD_NO				VARCHAR(11) = ''  -- 주문번호
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY 
		
		SELECT--ISNULL(G.CD_NM, B.ITM_NAME) AS ITM_NAME,
			   CASE WHEN PARSENAME(REPLACE(D.LOT_NO, '-', '.'), 2) = G.MGMT_ENTRY_1 THEN G.MGMT_ENTRY_DESCRIPTION_1 ELSE COALESCE(G.CD_NM, G.CD_NM, B.ITM_NAME) END AS ITM_NAME,
			   (CASE WHEN A.SCAN_CODE = '120008' AND SUBSTRING(D.LOT_NO, 13, 2) = 'UM' THEN F.MGMT_ENTRY_2 ELSE B.EXPIRY_CNT END) AS EXPIRY_CNT,
			   C.RAW_MATERIALS,
			   C.ITM_PROD_NO,
			   FORMAT(CONVERT(DATE, D2.EXPIRATION_DT,112), 'yyyy.MM.dd') AS EXPIRATION_DATE,
			   E.CD_NM AS LOT_OIL_GB
		FROM PO_ORDER_DTL AS A
			INNER JOIN CD_PRODUCT_CMN AS B ON A.SCAN_CODE = B.SCAN_CODE
			INNER JOIN PD_TEST_REPORT_INFO AS C ON B.SCAN_CODE = C.SCAN_CODE
			LEFT OUTER JOIN PO_ORDER_LOT AS D ON D.ORD_NO = @P_ORD_NO AND D.SCAN_CODE = A.SCAN_CODE
			LEFT OUTER JOIN CD_LOT_MST AS D2 ON D.SCAN_CODE = D2.SCAN_CODE AND D.LOT_NO = D2.LOT_NO
			INNER JOIN TBL_COMM_CD_MST AS E ON E.CD_CL = 'LOT_OIL_GB' AND E.CD_ID = B.LOT_OIL_GB
			INNER JOIN TBL_COMM_CD_MST AS F ON F.CD_CL = 'LOT_PARTNER_GB' AND F.CD_ID = B.LOT_PARTNER_GB
			LEFT OUTER JOIN TBL_COMM_CD_MST AS G ON G.CD_CL = 'ITM_TEST_REPORT_NM' AND G.CD_ID = B.SCAN_CODE
		WHERE A.ORD_NO = @P_ORD_NO
	
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

