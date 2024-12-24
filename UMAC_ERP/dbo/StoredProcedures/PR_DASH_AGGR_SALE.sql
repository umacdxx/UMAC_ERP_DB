
/*
-- 생성자 :	최수민
-- 등록일 :	2024.09.03
-- 설 명  : 대시보드 매출 집계
-- 수정자 :	-
-- 수정일 :	-
-- 설 명  : 
-- 실행문 : EXEC PR_DASH_AGGR_SALE '20240801' ,'20240831', 'DW,DS'
			EXEC PR_DASH_AGGR_SALE '20240801' ,'20240831', NULL
			EXEC PR_DASH_AGGR_SALE '20240101' ,'20240831', 'DW,DS'
			EXEC PR_DASH_AGGR_SALE '20240101' ,'20240831', NULL

			
			EXEC PR_DASH_AGGR_SALE '20240901' ,'20240930', NULL
*/
CREATE PROCEDURE [dbo].[PR_DASH_AGGR_SALE]
(
	@P_START_DT				NVARCHAR(8) = '',			-- 조회시작일자
	@P_END_DT				NVARCHAR(8) = '',			-- 조회종료일자
	@P_LOT_PARTNER_GB	    NVARCHAR(25) = '',			-- LOT 거래처 구분
	@P_WEIGHT_GB			NVARCHAR(3) = ''			-- 수중량구분(QTY, WT)
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	BEGIN TRY 

	
		WITH MONTHLY_AGGREGATION AS (
			SELECT LEFT(AGGR_DT, 4) AS AGGR_YEAR
				 , SUBSTRING(AGGR_DT, 5, 2) AS AGGR_MONTH
				 , SUM(AGGR_EA_AMT) AS MONTHLY_EA_AMT
				 , SUM(AGGR_KG_AMT) AS MONTHLY_KG_AMT
				 , SUM(AGGR_AMT) AS MONTHLY_AMT
			  FROM AG_SALE
			 WHERE (AGGR_DT BETWEEN @P_START_DT AND @P_END_DT
			    OR (AGGR_DT BETWEEN CAST(DATEADD(YEAR, -1, @P_START_DT) AS NVARCHAR) AND CAST(DATEADD(YEAR, -1, @P_END_DT) AS NVARCHAR)))
			   AND (
						ISNULL(@P_LOT_PARTNER_GB, '') = '' 
						OR LOT_PARTNER_GB IN (SELECT value FROM STRING_SPLIT(@P_LOT_PARTNER_GB, ','))
				   )
			 GROUP BY LEFT(AGGR_DT, 4), SUBSTRING(AGGR_DT, 5, 2)
		),
		CUMULATIVE_AGGREGATION AS (
			SELECT AGGR_YEAR
				 , AGGR_MONTH
				 , CASE WHEN @P_WEIGHT_GB = 'QTY' THEN MONTHLY_EA_AMT
						WHEN @P_WEIGHT_GB = 'WT' THEN MONTHLY_KG_AMT
						ELSE MONTHLY_AMT 
				   END AS MONTHLY_AMT
				 , SUM(CASE WHEN @P_WEIGHT_GB = 'QTY' THEN MONTHLY_EA_AMT
							WHEN @P_WEIGHT_GB = 'WT' THEN MONTHLY_KG_AMT
							ELSE MONTHLY_AMT 
					   END) OVER (PARTITION BY AGGR_YEAR ORDER BY AGGR_MONTH) AS CUM_MONTHLY_AMT
			  FROM MONTHLY_AGGREGATION
		),
		CURRENT_YEAR AS (
			SELECT AGGR_MONTH
				 , MONTHLY_AMT AS CUR_MONTHLY_AMT
				 , CUM_MONTHLY_AMT AS CUR_CUM_MONTHLY_AMT
			  FROM CUMULATIVE_AGGREGATION
			 WHERE AGGR_YEAR = LEFT(@P_START_DT, 4)
		),
		PREVIOUS_YEAR AS (
			SELECT AGGR_MONTH
				 , MONTHLY_AMT AS PRE_MONTHLY_AMT
				 , CUM_MONTHLY_AMT AS PRE_CUM_MONTHLY_AMT
			  FROM CUMULATIVE_AGGREGATION
			 WHERE AGGR_YEAR = LEFT(DATEADD(YEAR, -1, @P_START_DT), 4)
		)
		SELECT AGGR_MONTH
			 , ROUND(CUR_MONTHLY_AMT, 0) AS CUR_MONTHLY_AMT
			 , ROUND(CUR_CUM_MONTHLY_AMT, 0) AS CUR_CUM_MONTHLY_AMT
			 , 0.0 AS PRE_MONTHLY_AMT
			 , 0.0 AS PRE_CUM_MONTHLY_AMT
		  FROM CURRENT_YEAR CUR

		UNION ALL

		SELECT AGGR_MONTH
			 , 0.0 AS CUR_MONTHLY_AMT
			 , 0.0 AS CUR_CUM_MONTHLY_AMT
			 , ROUND(PRE_MONTHLY_AMT, 0) AS PRE_MONTHLY_AMT
			 , ROUND(PRE_CUM_MONTHLY_AMT, 0) AS PRE_CUM_MONTHLY_AMT
		  FROM PREVIOUS_YEAR PRE
		-- WHERE PRE.AGGR_MONTH NOT IN (SELECT AGGR_MONTH FROM CURRENT_YEAR)

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

