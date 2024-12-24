
/*
-- 생성자 :	최수민
-- 등록일 :	2024.07.18
-- 설 명  : 대시보드 캘린더 제품별 주문 건수
			출고 : 일반제품(1, 2) 묶어서 / 벌크(제품) / 벌크(기타)
			입고 : 입고예정일 기준
-- 수정자 :	최수민
-- 수정일 :	2024.07.18
-- 설 명  : 
-- 실행문 : EXEC PR_DASH_CAL_ORDER_CNT_BY_ITM '20240701', '20240731'
*/
CREATE PROCEDURE [dbo].[PR_DASH_CAL_ORDER_CNT_BY_ITM]
(
	@P_START_DT		NVARCHAR(8) = '',			-- 조회시작일자
	@P_END_DT		NVARCHAR(8) = ''			-- 조회종료일자
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	BEGIN TRY 

		WITH VIEW_ORDERED_PRD AS (
			-- 출고
			SELECT HDR.ORD_NO
				 , HDR.DELIVERY_REQ_DT
				 , DTL.SCAN_CODE
				 , CMN.ITM_FORM
				 , CASE WHEN ITM_FORM IN ('1', '2') THEN '0'
						WHEN ITM_FORM = '3' THEN '3'
						WHEN ITM_FORM = '4' THEN '4'
						ELSE '5' END AS ITM_FORM_DESC
				 , CASE WHEN ORD_STAT IN ('35', '40') THEN '35' ELSE '0' END AS ORD_STAT
				 , ROW_NUMBER() OVER (PARTITION BY HDR.ORD_NO ORDER BY DTL.SCAN_CODE) AS RN
			  FROM PO_ORDER_HDR AS HDR
			 INNER JOIN PO_ORDER_DTL AS DTL ON HDR.ORD_NO = DTL.ORD_NO
			 INNER JOIN CD_PRODUCT_CMN AS CMN ON DTL.SCAN_CODE = CMN.SCAN_CODE
			 WHERE HDR.DELIVERY_REQ_DT BETWEEN @P_START_DT AND @P_END_DT
			   AND HDR.ORD_STAT IN ('10', '25', '33', '35', '40')

			UNION ALL

			-- 입고
			SELECT HDR.ORD_NO
				 , HDR.DELIVERY_EXP_DT AS DELIVERY_REQ_DT
				 , DTL.SCAN_CODE
				 , CMN.ITM_FORM
				 , '6' AS ITM_FORM_DESC
				 , CASE WHEN PUR_STAT IN ('35', '40') THEN '35' ELSE '0' END AS ORD_STAT
				 , ROW_NUMBER() OVER (PARTITION BY HDR.ORD_NO ORDER BY DTL.SCAN_CODE) AS RN
			FROM PO_PURCHASE_HDR AS HDR
			INNER JOIN PO_PURCHASE_DTL AS DTL ON HDR.ORD_NO = DTL.ORD_NO
			INNER JOIN CD_PRODUCT_CMN AS CMN ON DTL.SCAN_CODE = CMN.SCAN_CODE
			WHERE HDR.DELIVERY_EXP_DT BETWEEN @P_START_DT AND @P_END_DT
			  AND HDR.PUR_STAT IN ('10', '25', '33', '35', '40')
		)
		, VIEW_FILTERED_ORDERED_PRD AS (
			SELECT ORD_NO
				 , DELIVERY_REQ_DT
				 , SCAN_CODE
				 , ITM_FORM
				 , ITM_FORM_DESC
				 , ORD_STAT
			  FROM VIEW_ORDERED_PRD
			 WHERE RN = 1
		)
		SELECT DELIVERY_REQ_DT
			 , ITM_FORM_DESC
			 , COUNT(*) AS ORD_CNT
			 , MIN(ORD_STAT) AS ORD_STAT
		  FROM VIEW_FILTERED_ORDERED_PRD
		 GROUP BY DELIVERY_REQ_DT, ITM_FORM_DESC
		 ORDER BY DELIVERY_REQ_DT, ITM_FORM_DESC;
	
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
