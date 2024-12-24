/*
-- 생성자 :	윤현빈
-- 등록일 :	2024.08.09
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : SET 예상 소요 자재 조회
-- 실행문 : EXEC PR_SET_PLAN_DTL_LIST '','','','',''
*/
CREATE PROCEDURE [dbo].[PR_SET_PLAN_COMP_LIST]
( 
	@P_SET_PLAN_ID			NVARCHAR(11) = ''		-- 작업명
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY 	

		WITH W_PLAN AS (
			SELECT SET_COMP_CD AS SCAN_CODE
                 , MAX(SCAN_CODE) AS UP_SCAN_CODE
				 , SUM(PLAN_QTY) AS PLAN_QTY
				FROM PD_SET_PLAN_COMP
			   WHERE SET_PLAN_ID = @P_SET_PLAN_ID
			   GROUP BY SET_COMP_CD
		), W_INPUT AS (
			SELECT SET_COMP_CD AS SCAN_CODE
				 , SUM(COMP_QTY) AS INPUT_QTY
				FROM PD_SET_RESULT_COMP
			   WHERE SET_PLAN_ID = @P_SET_PLAN_ID
			     AND RESTORE_YN = 'N'
			   GROUP BY SET_COMP_CD
		), W_REAL AS (
			SELECT B.SET_COMP_CD AS SCAN_CODE
				 , SUM(A.PROD_QTY * B.COMP_QTY) AS REAL_QTY
				FROM PD_SET_RESULT_PROD AS A
				INNER JOIN (
					SELECT A.SET_PROD_CD AS SCAN_CODE
						 , B.SET_COMP_CD
						 --, SUM(B.COMP_QTY) AS COMP_QTY
						 , B.COMP_QTY
						FROM CD_SET_HDR AS A
						INNER JOIN CD_SET_DTL AS B ON A.SET_CD = B.SET_CD
						--GROUP BY A.SET_PROD_CD, B.SET_COMP_CD
				) AS B ON A.SCAN_CODE = B.SCAN_CODE
				WHERE A.SET_PLAN_ID = @P_SET_PLAN_ID
				GROUP BY B.SET_COMP_CD
		), W_RESTORE AS (
			SELECT SET_COMP_CD AS SCAN_CODE
				 , SUM(COMP_QTY) AS RESTORE_QTY
				FROM PD_SET_RESULT_COMP
			   WHERE SET_PLAN_ID = @P_SET_PLAN_ID
				 AND RESTORE_YN = 'Y'
			   GROUP BY SET_COMP_CD
		)
		SELECT ROW_NUMBER() OVER(ORDER BY MST_PRD.ITM_GB, A.UP_SCAN_CODE, A.SCAN_CODE) AS ROW_NUM
			 , A.SCAN_CODE
			 , MST_PRD.ITM_NAME_DETAIL AS ITM_NAME
			 , A.PLAN_QTY
			 , ISNULL(B.INPUT_QTY, 0) AS INPUT_QTY
			 , CAST(ISNULL(C.REAL_QTY, 0) AS INT) AS REAL_QTY
			 , ISNULL(D.RESTORE_QTY, 0) AS RESTORE_QTY
			 , CAST(ISNULL(B.INPUT_QTY, 0) - (ISNULL(C.REAL_QTY, 0) + ISNULL(D.RESTORE_QTY, 0)) AS INT) AS DIFF_QTY
			FROM W_PLAN AS A
			INNER JOIN CD_PRODUCT_CMN AS MST_PRD ON A.SCAN_CODE = MST_PRD.SCAN_CODE
			LEFT OUTER JOIN W_INPUT AS B ON A.SCAN_CODE = B.SCAN_CODE
			LEFT OUTER JOIN W_REAL AS C ON A.SCAN_CODE = C.SCAN_CODE
			LEFT OUTER JOIN W_RESTORE AS D ON A.SCAN_CODE = D.SCAN_CODE
		   WHERE A.PLAN_QTY != 0

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

