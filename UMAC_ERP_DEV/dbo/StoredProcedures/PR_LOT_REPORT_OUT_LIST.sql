/*
-- 생성자 :	윤현빈
-- 등록일 :	2024.03.07
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : LOT별 출고현황 리스트
-- 실행문 : EXEC PR_LOT_REPORT_OUT_LIST '','','20240901','20241001',10,0
-- 수정일 : 20240514 윤현빈, 쿼리개선 및 LOT merge 인덱스, cnt 추가
*/
CREATE PROCEDURE [dbo].[PR_LOT_REPORT_OUT_LIST]
( 
	@P_SCAN_CODE	 NVARCHAR(14) = '',	-- 상품코드
	@P_LOT_NO		 NVARCHAR(30) = '',	-- LOT번호
	@P_FROM_ORD_DT	 NVARCHAR(10) = '',	-- 출고 from 일자
	@P_TO_ORD_DT	 NVARCHAR(10) = '',	-- 출고 to 일자
	@P_TOT_PAGE_ROW	 INT,
	@P_PAGE_INDEX	 INT
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY 	
		-- 리스트 TOTAL COUNT 
		DECLARE @TOT_CNT INT = 0;

		--# TOTAL COUNT #	
		WITH W_ORD_LIST AS (
			SELECT DISTINCT A.ORD_NO
				FROM PO_ORDER_HDR AS A
				INNER JOIN PO_ORDER_LOT AS B ON A.ORD_NO = B.ORD_NO
			   WHERE A.DELIVERY_DEC_DT BETWEEN @P_FROM_ORD_DT AND @P_TO_ORD_DT
			     AND 1=(CASE WHEN @P_SCAN_CODE = '' THEN 1 WHEN @P_SCAN_CODE != '' AND B.SCAN_CODE = @P_SCAN_CODE THEN 1 ELSE 2 END)
			     AND 1=(CASE WHEN @P_LOT_NO = '' THEN 1 WHEN @P_LOT_NO != '' AND B.LOT_NO LIKE '%'+@P_LOT_NO+'%' THEN 1 ELSE 2 END)
			     AND A.ORD_STAT IN ('35','40')
		)
		SELECT @TOT_CNT = COUNT(1)
			FROM W_ORD_LIST AS A
			INNER JOIN PO_ORDER_LOT AS B ON A.ORD_NO = B.ORD_NO
			
		;
	
		--# MAIN
		WITH W_ORD_LIST AS (
			SELECT DISTINCT A.ORD_NO
				FROM PO_ORDER_HDR AS A
				INNER JOIN PO_ORDER_LOT AS B ON A.ORD_NO = B.ORD_NO
			   WHERE A.DELIVERY_DEC_DT BETWEEN @P_FROM_ORD_DT AND @P_TO_ORD_DT
			     AND 1=(CASE WHEN @P_SCAN_CODE = '' THEN 1 WHEN @P_SCAN_CODE != '' AND B.SCAN_CODE = @P_SCAN_CODE THEN 1 ELSE 2 END)
			     AND 1=(CASE WHEN @P_LOT_NO = '' THEN 1 WHEN @P_LOT_NO != '' AND B.LOT_NO LIKE '%'+@P_LOT_NO+'%' THEN 1 ELSE 2 END)
			     AND A.ORD_STAT IN ('35','40')
		
		), W_ORD AS (
			SELECT A.DELIVERY_DEC_DT
				 , A.ORD_NO
				 , A.VEN_CODE
				 , E.VEN_NAME
				 , ISNULL(F.DELIVERY_NAME, '') AS DELIVERY_NAME
				 , ISNULL(G.DELIVERY_NAME, '') AS UP_DELIVERY_NAME
				 , H.SCAN_CODE
				 , H.LOT_NO
				 , H.PICKING_QTY
				 , I.ITM_NAME
				 , I.WEIGHT_GB
				 , ISNULL(J.CAR_NO, '') AS CAR_NO
				FROM PO_ORDER_HDR AS A
				INNER JOIN W_ORD_LIST AS B ON A.ORD_NO = B.ORD_NO
--				INNER JOIN PO_ORDER_DTL AS C ON A.ORD_NO = C.ORD_NO
				LEFT OUTER JOIN CD_PARTNER_MST AS E ON A.VEN_CODE = E.VEN_CODE
				LEFT OUTER JOIN CD_PARTNER_DELIVERY AS F ON F.VEN_CODE = A.VEN_CODE AND F.DELIVERY_CODE = A.DELIVERY_CODE
				LEFT OUTER JOIN CD_PARTNER_DELIVERY AS G ON A.VEN_CODE = G.VEN_CODE AND CONCAT(SUBSTRING(A.DELIVERY_CODE, 1, 5), '01') = G.DELIVERY_CODE	
				INNER JOIN PO_ORDER_LOT AS H ON A.ORD_NO = H.ORD_NO/* AND C.SCAN_CODE = D.SCAN_CODE*/
				INNER JOIN CD_PRODUCT_CMN AS I ON H.SCAN_CODE = I.SCAN_CODE
				INNER JOIN PO_SCALE AS J ON J.ORD_NO = A.ORD_NO
			   WHERE I.ITM_FORM != '3'
			     AND I.ITM_FORM != '4'
			
		), W_SET_PAGING AS (
			SELECT * 
				FROM W_ORD AS A
			   --ORDER BY A.DELIVERY_DEC_DT DESC, A.ORD_NO DESC, A.SCAN_CODE
			   ORDER BY A.DELIVERY_DEC_DT DESC, A.VEN_CODE, A.UP_DELIVERY_NAME, A.DELIVERY_NAME
			   OFFSET @P_PAGE_INDEX ROW
			   FETCH NEXT @P_TOT_PAGE_ROW ROWS ONLY

		), W_MAIN AS (
			SELECT A.*
			     --, DENSE_RANK() OVER(ORDER BY A.DELIVERY_DEC_DT DESC, A.ORD_NO DESC) AS MERGE_INDEX_1
			     --, DENSE_RANK() OVER(ORDER BY A.DELIVERY_DEC_DT DESC, A.ORD_NO DESC, SCAN_CODE) AS MERGE_INDEX_2
				 , DENSE_RANK() OVER(ORDER BY A.DELIVERY_DEC_DT DESC, A.VEN_CODE, A.UP_DELIVERY_NAME) AS MERGE_INDEX_1
			     , DENSE_RANK() OVER(ORDER BY A.DELIVERY_DEC_DT DESC, A.VEN_CODE, A.UP_DELIVERY_NAME, A.DELIVERY_NAME) AS MERGE_INDEX_2
				FROM W_SET_PAGING AS A
		) 
		SELECT A.*
		     , COUNT(*) OVER(PARTITION BY MERGE_INDEX_1) AS MERGE_CNT_1
		     , COUNT(*) OVER(PARTITION BY MERGE_INDEX_2) AS MERGE_CNT_2
		     , @TOT_CNT AS TOT_CNT
			FROM W_MAIN AS A
	

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

