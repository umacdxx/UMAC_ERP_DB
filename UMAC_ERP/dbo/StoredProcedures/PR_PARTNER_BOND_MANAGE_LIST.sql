/*
-- 생성자 :	윤현빈
-- 등록일 :	2024.06.11
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : 매출 거래처 채권 관리
-- 실행문 : EXEC PR_PARTNER_BOND_MANAGE_LIST '',''
*/
CREATE PROCEDURE [dbo].[PR_PARTNER_BOND_MANAGE_LIST]
( 
	@P_VEN_CODE		NVARCHAR(7) = '',	-- 거래처코드
	@P_DATE_YYYYMM	NVARCHAR(6) = ''	-- 조회년월
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY 	
		EXEC UMAC_CERT_OPEN_KEY; -- OPEN

		WITH W_CARRIED AS (
			SELECT SALE.VEN_CODE
				 , SALE.SALE_TOTAL_AMT - ISNULL(DEPOSIT.DEPOSIT_AMT, 0) AS CARRIED_AMT
				FROM (
					SELECT A.VEN_CODE
						 , SUM(A.SALE_TOTAL_AMT) AS SALE_TOTAL_AMT
						FROM SL_SALE_VEN AS A
					   WHERE SUBSTRING(A.SALE_DT, 1, 6) < @P_DATE_YYYYMM
					   GROUP BY A.VEN_CODE
				) AS SALE
				LEFT OUTER JOIN (
					SELECT A.VEN_CODE
						 , SUM(A.DEPOSIT_AMT) AS DEPOSIT_AMT
						FROM PA_ACCT_DEPOSIT AS A
					   WHERE DEPOSIT_FISH = 'Y'
						 AND SUBSTRING(DEPOSIT_DT, 1, 6) < @P_DATE_YYYYMM
					   GROUP BY A.VEN_CODE
				) AS DEPOSIT
				ON SALE.VEN_CODE = DEPOSIT.VEN_CODE
		), W_MON_SALE AS (
			SELECT A.VEN_CODE
				 , SUM(A.SALE_TOTAL_AMT) AS SALE_TOTAL_AMT
				FROM SL_SALE_VEN AS A
			   WHERE SUBSTRING(A.SALE_DT, 1, 6) = @P_DATE_YYYYMM
			   GROUP BY A.VEN_CODE
		), W_MON_DEPOSIT AS (
			SELECT A.VEN_CODE
				 , SUM(A.DEPOSIT_AMT) AS DEPOSIT_AMT
				FROM PA_ACCT_DEPOSIT AS A
			   WHERE DEPOSIT_FISH = 'Y'
				 AND SUBSTRING(DEPOSIT_DT, 1, 6) = @P_DATE_YYYYMM
			   GROUP BY A.VEN_CODE
		), W_CUR_RECEIVABLE_AMOUNT AS (
			SELECT SALE.VEN_CODE
				 , SALE.SALE_TOTAL_AMT - ISNULL(DEPOSIT.DEPOSIT_AMT, 0) AS RECEIVABLE_AMT
				FROM (
					SELECT A.VEN_CODE
						 , SUM(A.SALE_TOTAL_AMT) AS SALE_TOTAL_AMT
						FROM SL_SALE_VEN AS A
					   GROUP BY A.VEN_CODE
				) AS SALE
				LEFT OUTER JOIN (
					SELECT A.VEN_CODE
						 , SUM(A.DEPOSIT_AMT) AS DEPOSIT_AMT
						FROM PA_ACCT_DEPOSIT AS A
					   WHERE DEPOSIT_FISH = 'Y'
					   GROUP BY A.VEN_CODE
				) AS DEPOSIT
				ON SALE.VEN_CODE = DEPOSIT.VEN_CODE
		)
		SELECT A.VEN_CODE
			 , A.VEN_NAME
			 , ISNULL(DBO.GET_DECRYPT(B.VACT_NO), '미발행') AS VACT_NO
			 , ISNULL(C.CARRIED_AMT, 0) AS CARRIED_AMT
			 , ISNULL(D.SALE_TOTAL_AMT, 0) AS SALE_TOTAL_AMT
			 , ISNULL(E.DEPOSIT_AMT, 0) AS DEPOSIT_AMT
			 , ISNULL(F.RECEIVABLE_AMT, 0) AS RECEIVABLE_AMT
			 , ISNULL(A.CREDIT_LIMIT_YN, 'N') AS CREDIT_LIMIT_YN
			 , ISNULL(A.CREDIT_LIMIT, 0) AS CREDIT_LIMIT
			FROM CD_PARTNER_MST AS A
			LEFT OUTER JOIN PA_ACCT_MST AS B ON A.VEN_CODE = B.VEN_CODE
			LEFT OUTER JOIN W_CARRIED AS C ON A.VEN_CODE = C.VEN_CODE
			LEFT OUTER JOIN W_MON_SALE AS D ON A.VEN_CODE = D.VEN_CODE
			LEFT OUTER JOIN W_MON_DEPOSIT AS E ON A.VEN_CODE = E.VEN_CODE
			LEFT OUTER JOIN W_CUR_RECEIVABLE_AMOUNT AS F ON A.VEN_CODE = F.VEN_CODE
			
		   WHERE A.VEN_GB = '2'
			 AND 1=(CASE WHEN @P_VEN_CODE = '' THEN 1 WHEN @P_VEN_CODE != '' AND A.VEN_CODE = @P_VEN_CODE THEN 1 ELSE 2 END)
			ORDER BY CASE WHEN VACT_NO IS NULL THEN 1 ELSE 0 END, A.VEN_CODE
	 
		EXEC UMAC_CERT_CLOSE_KEY; -- CLOSE

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
