
/*
-- 생성자 :	강세미
-- 등록일 :	2024.09.03
-- 설 명  : 차량정보 리스트
-- 실행문 : EXEC PR_TRANS_CAR_INFO_LIST '','','0105555','',''
*/
CREATE PROCEDURE [dbo].[PR_TRANS_CAR_INFO_LIST]
( 
	@P_CAR_NO			NVARCHAR(8),	-- 차량번호
	@P_CAR_GB			NVARCHAR(1),	-- 차량구분
	@P_MOBIL_NO			NVARCHAR(11),	-- 휴대폰번호
	@P_DRIVER_NAME		NVARCHAR(20),	-- 기사명
	@P_DRIVER_VEN_NAME	NVARCHAR(50)	-- 회사명
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	BEGIN TRY 
	EXEC UMAC_CERT_OPEN_KEY; -- OPEN
		SELECT A.CAR_NO,
			   A.CAR_GB,
			   DBO.GET_DECRYPT(A.MOBIL_NO) AS MOBIL_NO,
			   A.DRIVER_NAME,
			   A.DRIVER_VEN_NAME,
			   FORMAT(A.IDATE, 'yyyyMMdd') AS IDATE,
			   FORMAT(A.UDATE, 'yyyyMMdd') AS UDATE,
			   A.IEMP_ID,
			   A.UEMP_ID,
			   B.CD_NM AS CAR_GB_NM
		  FROM PO_CAR_INFO AS A
		  LEFT OUTER JOIN TBL_COMM_CD_MST AS B ON B.CD_CL = 'CAR_GB' AND B.CD_ID = A.CAR_GB
		 WHERE 1 = (CASE WHEN @P_CAR_NO = '' THEN 1 WHEN  @P_CAR_NO <> '' AND CAR_NO LIKE '%' + @P_CAR_NO + '%' THEN 1 ELSE 0 END)
				AND 1 = (CASE WHEN @P_CAR_GB = '' THEN 1 WHEN  @P_CAR_GB <> '' AND CAR_GB = @P_CAR_GB THEN 1 ELSE 0 END)
				AND 1 = (CASE WHEN @P_MOBIL_NO = '' THEN 1 WHEN  @P_MOBIL_NO <> '' AND DBO.GET_DECRYPT(MOBIL_NO) LIKE '%' + @P_MOBIL_NO + '%' THEN 1 ELSE 0 END)
				AND 1 = (CASE WHEN @P_DRIVER_NAME = '' THEN 1 WHEN  @P_DRIVER_NAME <> '' AND DRIVER_NAME LIKE '%' + @P_DRIVER_NAME + '%' THEN 1 ELSE 0 END)
				AND 1 = (CASE WHEN @P_DRIVER_VEN_NAME = '' THEN 1 WHEN  @P_DRIVER_VEN_NAME <> '' AND DRIVER_VEN_NAME LIKE '%' + @P_DRIVER_VEN_NAME + '%' THEN 1 ELSE 0 END)
		  
	EXEC UMAC_CERT_CLOSE_KEY -- CLOSE
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

