/*
-- 생성자 :	최수민
-- 등록일 :	2024.08.28
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : 환율 정보 저장
-- 실행문 : EXEC PR_BATCH_IM_EX_RATE_PUT '20240826'
			EXEC PR_BATCH_IM_EX_RATE_PUT '20240909'
*/
CREATE PROCEDURE [dbo].[PR_BATCH_IM_EX_RATE_PUT]
(
	@P_SEARCH_DATE		NVARCHAR(8)	= ''		-- 조회일자
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	 
	DECLARE @RETURN_CODE INT = 0						-- 리턴코드(저장완료)
	DECLARE @RETURN_MESSAGE NVARCHAR(10) = DBO.GET_ERR_MSG('0')		-- 리턴메시지
	
	BEGIN TRAN
	BEGIN TRY 
			 
		DECLARE @R_RETURN_CODE 		INT,
				@R_RETURN_DATA 		NVARCHAR(MAX),
				@V_START_TIME		DATETIME = GETDATE(),
				@P_URL				NVARCHAR(200),
				@P_USD_RATE			DECIMAL(10, 2),
				@P_EUR_RATE			DECIMAL(10, 2),
				@P_EXCHANGE_DATE	NVARCHAR(8) = CASE WHEN @P_SEARCH_DATE = '' THEN CONVERT(NVARCHAR(8), GETDATE(), 112) ELSE @P_SEARCH_DATE END;
				

		SET @P_URL = 'https://www.koreaexim.go.kr/site/program/financial/exchangeJSON?authkey=9TI7kykmfG6k7137fID5NqXYdaGlxDLm&searchdate='+@P_EXCHANGE_DATE+'&data=AP01';

		EXEC SP_SEND_API 'GET', @P_URL, '', @R_RETURN_CODE OUT, @R_RETURN_DATA OUT;

        IF @R_RETURN_DATA IS NULL OR @R_RETURN_DATA = '[]'
        BEGIN
		
			SET @RETURN_CODE = -1
			SET @RETURN_MESSAGE = '데이터가 없습니다';

			INSERT INTO TBL_BATCH_LOG
			SELECT CONVERT(VARCHAR(8), GETDATE(), 112)
				, 'PR_BATCH_IM_EX_RATE_PUT'
				, 'F'
				, @V_START_TIME
				, GETDATE()
				, CONCAT(@RETURN_MESSAGE, ' / ', @RETURN_CODE)
				, 'N'
			;

			COMMIT;
            RETURN;
        END
		;
		

		-- JSON 데이터에서 필요한 정보를 추출하여 변수에 할당
		WITH VIEW_EXCHANGE_RATE AS (
			SELECT JSON_VALUE(value, '$.cur_unit') AS CUR_UNIT
				 , CAST(ROUND(CONVERT(DECIMAL(10, 2), REPLACE(JSON_VALUE(value, '$.deal_bas_r'), ',', '')), 2) AS DECIMAL(10, 2)) AS DEAL_BAS_R
				 , JSON_VALUE(value, '$.result') AS RESULT
			FROM OPENJSON(@R_RETURN_DATA) 
		)
		SELECT @P_USD_RATE = MAX(CASE WHEN CUR_UNIT = 'USD' THEN DEAL_BAS_R END)
			 , @P_EUR_RATE = MAX(CASE WHEN CUR_UNIT = 'EUR' THEN DEAL_BAS_R END)
		  FROM VIEW_EXCHANGE_RATE
		 WHERE CUR_UNIT IN ('USD', 'EUR');


		MERGE IM_EX_RATE_INFO AS target
		USING (
			SELECT
				@P_EXCHANGE_DATE AS EXCHANGE_DATE,
				@P_USD_RATE AS USD_RATE,
				@P_EUR_RATE AS EUR_RATE
		) AS source
		ON target.EXCHANGE_DATE = source.EXCHANGE_DATE
		WHEN MATCHED THEN
			UPDATE SET
				target.USD_RATE = source.USD_RATE,
				target.EUR_RATE = source.EUR_RATE,
				target.IDATE = GETDATE()  -- 수정 일자를 현재 시간으로 설정
		WHEN NOT MATCHED THEN
			INSERT (EXCHANGE_DATE, USD_RATE, EUR_RATE, IDATE)
			VALUES (source.EXCHANGE_DATE, source.USD_RATE, source.EUR_RATE, GETDATE());

		COMMIT;

	END TRY
	BEGIN CATCH		

	    IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRAN;
			
			SET @RETURN_CODE = -1
			SET @RETURN_MESSAGE = ERROR_MESSAGE();

			INSERT INTO TBL_BATCH_LOG
			SELECT CONVERT(VARCHAR(8), GETDATE(), 112)
				, 'PR_BATCH_IM_EX_RATE_PUT'
				, 'F'
				, @V_START_TIME
				, GETDATE()
				, CONCAT(ERROR_MESSAGE(), ' / ', @RETURN_CODE)
				, 'N'
			;
					
		END;
		
	END CATCH

	
	SELECT @RETURN_CODE AS RETURN_CODE, @RETURN_MESSAGE AS RETURN_MESSAGE
END

GO

