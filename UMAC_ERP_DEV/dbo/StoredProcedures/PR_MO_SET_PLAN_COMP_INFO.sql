
/*
-- 생성자 :	최수민
-- 등록일 :	2024.12.22
-- 설 명  : 앱(API) SET 계획서에 등록된 제품 조회
-- 수정자 : 2024.12.23 최수민 날짜 조건 추가
-- 실행문 : EXEC PR_MO_SET_PLAN_COMP_INFO 'SET20241212'
*/
CREATE PROCEDURE [dbo].[PR_MO_SET_PLAN_COMP_INFO]
( 
	@P_SET_PLAN_ID		NVARCHAR(11) = '',		-- 작업번호
	@P_PROD_DT		    NVARCHAR(8) = ''		-- 생산일자
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY 

		WITH VIEW_PLAN_COMP AS (
		SELECT MIN(PCOMP.SET_PLAN_ID) AS SET_PLAN_ID
			 , MIN(PCOMP.SCAN_CODE) AS SCAN_CODE
			 , PCOMP.SET_COMP_CD
		  FROM PD_SET_PLAN_COMP AS PCOMP
		 WHERE PCOMP.SET_PLAN_ID = @P_SET_PLAN_ID
		 GROUP BY PCOMP.SET_COMP_CD
		)
		SELECT CMN.ITM_CODE
			 , VCOMP.SET_COMP_CD AS SCAN_CODE
			 , CMN.ITM_NAME
			 , 0 AS PLT_BOX_QTY
			 , 0 AS IPSU_QTY
			 , NULL AS LOT_NO
		  FROM VIEW_PLAN_COMP AS VCOMP
		 INNER JOIN CD_PRODUCT_CMN AS CMN ON VCOMP.SET_COMP_CD = CMN.SCAN_CODE
		  LEFT OUTER JOIN (SELECT SET_PLAN_ID, MAX(SET_COMP_CD) AS SET_COMP_CD, COMP_CFM_FLAG
							 FROM PD_SET_RESULT_COMP
							WHERE RESTORE_YN = 'N'
							  AND PROD_DT = @P_PROD_DT
							GROUP BY SET_PLAN_ID, COMP_CFM_FLAG) AS RESULT ON VCOMP.SET_PLAN_ID = RESULT.SET_PLAN_ID AND VCOMP.SET_COMP_CD = RESULT.SET_COMP_CD
		 WHERE CMN.ITM_GB = '1'
		   AND (RESULT.COMP_CFM_FLAG = 'N' OR RESULT.COMP_CFM_FLAG IS NULL)
					
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

