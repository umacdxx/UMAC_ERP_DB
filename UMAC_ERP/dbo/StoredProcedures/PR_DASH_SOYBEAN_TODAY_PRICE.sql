
/*
-- 생성자 :	최수민
-- 등록일 :	2024.06.20
-- 설 명  : 대시보드 근월물, 원월물 금일 가격
-- 수정자 :	최수민
-- 수정일 :	2024.06.20
			2024.10.04 최수민 대두유 데이터 중 가장 최신일로 조회, 북미 -> 남미로 수정
-- 설 명  : 
-- 실행문 : EXEC PR_DASH_SOYBEAN_TODAY_PRICE '20240902'
*/
CREATE PROCEDURE [dbo].[PR_DASH_SOYBEAN_TODAY_PRICE]
(
	@P_SEACH_DT				NVARCHAR(8) = ''			-- 조회일자
)
AS
BEGIN


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	BEGIN TRY 

		SELECT TOP 2 PRICE_DATE
			 , CASE WHEN NEAR_SELECT = 1 THEN PRICE_MONTH_1
					WHEN NEAR_SELECT = 2 THEN PRICE_MONTH_2
					WHEN NEAR_SELECT = 3 THEN PRICE_MONTH_3
					ELSE NULL
			   END AS NEAR_SELECTED
			 , NEAR_MTH_SOUTH
			 , CASE WHEN CURRENT_SELECT = 1 THEN PRICE_MONTH_1
					WHEN CURRENT_SELECT = 2 THEN PRICE_MONTH_2
					WHEN CURRENT_SELECT = 3 THEN PRICE_MONTH_3
					ELSE NULL
			   END AS CURRENT_SELECTED
			 , CURRENT_MTH_SOUTH
		  FROM IM_SOYBEAN_PRICE
		 ORDER BY PRICE_DATE DESC

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
