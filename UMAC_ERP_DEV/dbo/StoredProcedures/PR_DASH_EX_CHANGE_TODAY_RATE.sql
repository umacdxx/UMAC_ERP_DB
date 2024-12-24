
/*
-- 생성자 :	최수민
-- 등록일 :	2024.09.02
-- 설 명  : 대시보드 금일 환율
-- 수정자 :	최수민
-- 수정일 :	2024.09.02
-- 설 명  : 
-- 실행문 : EXEC PR_DASH_EX_CHANGE_TODAY_RATE '20240901'
*/
CREATE PROCEDURE [dbo].[PR_DASH_EX_CHANGE_TODAY_RATE]
(
	@P_SEACH_DT				NVARCHAR(8) = ''			-- 조회일자
)
AS
BEGIN


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	BEGIN TRY 

		(
			SELECT EXCHANGE_DATE
				 , USD_RATE
				 , EUR_RATE
			  FROM IM_EX_RATE_INFO
			 WHERE EXCHANGE_DATE = @P_SEACH_DT
		)
		UNION ALL
		(
			SELECT *
			  FROM ( SELECT TOP 1
							EXCHANGE_DATE
						  , USD_RATE
						  , EUR_RATE
					   FROM IM_EX_RATE_INFO
					  WHERE EXCHANGE_DATE < @P_SEACH_DT
					  ORDER BY EXCHANGE_DATE DESC) AS B
		)
		ORDER BY EXCHANGE_DATE DESC;

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

