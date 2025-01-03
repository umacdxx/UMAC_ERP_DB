
/*
-- 생성자 :	최수민
-- 등록일 :	2024.07.18
-- 설 명  : 대시보드 출고 예정 & 출고 완료 목록 조회
-- 수정자 :	최수민
-- 수정일 :	2024.07.18
-- 설 명  : 
-- 실행문 : 
	EXEC PR_DASH_OIL_ORDER_CNT '20240724', '20240807'
	EXEC PR_DASH_OIL_ORDER_CNT '20240807', '20240807'
*/
CREATE PROCEDURE [dbo].[PR_DASH_OIL_ORDER_CNT]
(
	@P_START_DT		NVARCHAR(8) = '',			-- 조회시작일자
	@P_END_DT		NVARCHAR(8) = ''			-- 조회종료일자
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	BEGIN TRY 

		WITH VIEW_ORDERED_PRD AS (
			SELECT ISNULL(CMN.LOT_OIL_GB, '') AS LOT_OIL_GB
				 , CMN.WEIGHT_GB
				 , SUM(DTL.PICKING_QTY) AS PICKING_SUM
				 , COUNT(HDR.ORD_NO) AS PICKING_CNT
			  FROM PO_ORDER_HDR AS HDR
			 INNER JOIN PO_ORDER_DTL AS DTL ON HDR.ORD_NO = DTL.ORD_NO
			 INNER JOIN CD_PRODUCT_CMN AS CMN ON DTL.SCAN_CODE = CMN.SCAN_CODE
			 WHERE HDR.DELIVERY_REQ_DT BETWEEN @P_START_DT AND @P_END_DT
			   AND HDR.ORD_STAT IN ('10','25','33','35','40')
			 GROUP BY ISNULL(CMN.LOT_OIL_GB, ''), WEIGHT_GB
		)
		SELECT A.LOT_OIL_GB
			 , A.WEIGHT_GB
			 , A.PICKING_SUM
			 , A.PICKING_CNT
			 , ISNULL(F.CD_NM, '기타') AS LOT_OIL_GB_NM
		  FROM VIEW_ORDERED_PRD AS A
		  LEFT OUTER JOIN TBL_COMM_CD_MST AS F ON F.CD_CL = 'LOT_OIL_GB' AND A.LOT_OIL_GB = F.CD_ID
		 ORDER BY A.LOT_OIL_GB DESC, A.WEIGHT_GB

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

