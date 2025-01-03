
/*
-- 생성자 :	최수민
-- 등록일 :	2024.08.14
-- 설 명  : 
			앱(API) SET 계획서에 등록된 제품인지 조회
			등록된 제품이라면 제품 정보 출력
-- 수정자 : 2024.08.26 최수민 제품명 -> 단축제품명 변경,
			2024.11.28 임현태 @P_MENU_GUBUN = 'C' 경우 ITM_CODE 조건 검색 추가
			2024.12.02 임현태 @P_MENU_GUBUN = 'C' 경우 ITM_CODE 조건을 SCAN_CODE 검색으로 변경
			2024.12.22 최수민 검색조건 ITM_CODE 추가
-- 실행문 : 
			EXEC PR_MO_SET_PLAN_INFO 'SET20240808', '210125', 'A'
			EXEC PR_MO_SET_PLAN_INFO 'SET20240808', '8801052062297', 'B'
			EXEC PR_MO_SET_PLAN_INFO 'SET20240808', '8801052062297', 'C'
*/
CREATE PROCEDURE [dbo].[PR_MO_SET_PLAN_INFO]
( 
	@P_SET_PLAN_ID		NVARCHAR(11) = '',		-- 작업번호
	@P_ITM_SCAN_CODE	NVARCHAR(20) = '',		-- 관리코드/제품코드
	@P_MENU_GUBUN		NVARCHAR(1) = ''		-- 메뉴구분
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY 

		IF @P_MENU_GUBUN = 'A'
		BEGIN
		
			SELECT COMP.SET_COMP_CD AS SCAN_CODE
				 , CMN.ITM_CODE
				 , CMN.ITM_NAME
				 , CMN.PLT_BOX_QTY
				 , CMN.IPSU_QTY
				 , NULL AS LOT_NO
			  FROM PD_SET_PLAN_COMP AS COMP
			 INNER JOIN CD_PRODUCT_CMN AS CMN ON COMP.SET_COMP_CD= CMN.SCAN_CODE
			 WHERE COMP.SET_PLAN_ID = @P_SET_PLAN_ID
			   AND (CMN.ITM_CODE = @P_ITM_SCAN_CODE OR CMN.SCAN_CODE = @P_ITM_SCAN_CODE)
		END
		ELSE		
		IF @P_MENU_GUBUN = 'B'
		BEGIN

			SELECT PROD.SCAN_CODE
				 , CMN.ITM_CODE
				 , CMN.ITM_NAME
				 , CMN.PLT_BOX_QTY
				 , CMN.IPSU_QTY
				 , NULL AS LOT_NO
			  FROM PD_SET_PLAN_PROD AS PROD
			 INNER JOIN CD_PRODUCT_CMN AS CMN ON PROD.SCAN_CODE= CMN.SCAN_CODE
			 WHERE PROD.SET_PLAN_ID = @P_SET_PLAN_ID
			   AND (CMN.ITM_CODE = @P_ITM_SCAN_CODE OR CMN.SCAN_CODE = @P_ITM_SCAN_CODE)
		END
		ELSE
		BEGIN

			WITH VIEW_SET_RESULT_COMP AS (
				SELECT LOT_NO
					 , SET_COMP_CD AS SCAN_CODE
				  FROM PD_SET_RESULT_COMP AS RCOMP
				 WHERE RCOMP.SET_PLAN_ID = @P_SET_PLAN_ID
				   AND RCOMP.LOT_NO IS NOT NULL
				 GROUP BY LOT_NO, SET_COMP_CD
			)
			SELECT VCOMP.SCAN_CODE
				 , CMN.ITM_CODE
				 , CMN.ITM_NAME
				 , CMN.PLT_BOX_QTY
				 , CMN.IPSU_QTY
				 , STRING_AGG(VCOMP.LOT_NO, ',') AS LOT_NO
			  FROM VIEW_SET_RESULT_COMP AS VCOMP
			 INNER JOIN CD_PRODUCT_CMN AS CMN ON VCOMP.SCAN_CODE = CMN.SCAN_CODE
			 WHERE (CMN.ITM_CODE = @P_ITM_SCAN_CODE OR CMN.SCAN_CODE = @P_ITM_SCAN_CODE)
			 GROUP BY VCOMP.SCAN_CODE, CMN.ITM_CODE, CMN.ITM_NAME, CMN.PLT_BOX_QTY, CMN.IPSU_QTY
		END
					
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

