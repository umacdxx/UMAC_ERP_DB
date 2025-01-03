/*
-- 생성자 :	윤현빈
-- 등록일 :	2024.06.19
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : 거래처 별 입금내역 상세 조회
-- 실행문 : PR_PARTNER_DEPOSIT_SUM_DTL_LIST 'UM20128','20240606','20240706'


*/
CREATE PROCEDURE [dbo].[PR_PARTNER_DEPOSIT_SUM_DTL_LIST]
( 
	@P_VEN_CODE		NVARCHAR(7) = '',	-- 거래처코드
	@P_FROM_DT		NVARCHAR(8) = '',	-- FROM 일자
	@P_TO_DT		NVARCHAR(8) = ''	-- TO 일자
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY 	
		EXEC UMAC_CERT_OPEN_KEY; -- OPEN

		SELECT A.MOID
			 , A.DEPOSIT_DT
			 , A.DEPOSIT_GB
			 , COM.CD_NM AS DEPOSIT_GB_NAME
			 , A.DEPOSIT_AMT
			 , ISNULL(CONVERT(VARCHAR(10), CAST(B.ISSUE_DT AS DATE), 23), '미발행') AS ISSUE_DT
			 , CASE WHEN DEPOSIT_GB = '01' THEN CONCAT(D.CD_NM, ' : ', ISNULL(DBO.GET_DECRYPT(B.VACT_NO), '미발행') ) ELSE '-' END AS VACT_NO						
			FROM PA_ACCT_DEPOSIT AS A
			INNER JOIN TBL_COMM_CD_MST AS COM ON A.DEPOSIT_GB = COM.CD_ID AND COM.CD_CL = 'DEPOSIT_GB'
			LEFT OUTER JOIN PA_ACCT_ISSUE AS B ON A.MOID = B.MOID
			LEFT OUTER JOIN PA_ACCT_MST AS C ON A.VEN_CODE = C.VEN_CODE
			LEFT OUTER JOIN TBL_COMM_CD_MST AS D ON C.BANK_CODE = D.CD_ID AND D.CD_CL = 'TOSS_BANK'
		   WHERE A.DEPOSIT_DT BETWEEN @P_FROM_DT AND @P_TO_DT
			 AND 1=(CASE WHEN @P_VEN_CODE = '' THEN 1 WHEN @P_VEN_CODE != '' AND A.VEN_CODE = @P_VEN_CODE THEN 1 ELSE 2 END)
		   ORDER BY A.MOID
	
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

