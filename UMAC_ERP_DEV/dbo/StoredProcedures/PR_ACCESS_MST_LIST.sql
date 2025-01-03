

/*
-- 생성자 :	윤현빈
-- 등록일 :	2024.03.12
-- 수정자 : -
-- 수정일 : - 
-- 설 명  :  IP 접근 허용 리스트 조회
-- 실행문 : 
EXEC PR_ACCESS_MST_LIST '0', '' ,'Y'
*/
CREATE PROCEDURE [dbo].[PR_ACCESS_MST_LIST]
	@P_ACCESS_GB     VARCHAR(1), -- 접근 구분 0:IP, 2:IP 대역, 3:ID
	@P_ACCESS_ID     VARCHAR(20), -- 접근 아이디
	@P_USE_YN		 VARCHAR(1) -- 사용여부
AS
BEGIN
   SET NOCOUNT ON;
   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY 

	SELECT ROW_NUMBER() OVER(ORDER BY ACC.ACCESS_GB, ACC.ACCESS_ID) AS ROW_NUM
	     , ACC.ACCESS_GB
		 , CMM.CD_NM AS ACCESS_GB_NM
		 , ACC.ACCESS_ID
		 , ACC.LAST_IP_ADDRESS
		 , ACC.REMARKS
		 , ACC.USE_YN
		 , FORMAT(ACC.IDATE, 'yyyy-MM-dd') AS IDATE
		 , ACC.IEMP_ID
		FROM TBL_ACCESS_MST AS ACC
	   INNER JOIN TBL_COMM_CD_MST AS CMM
	     ON CMM.CD_CL = 'ACC_GB'
	    AND CMM.CD_ID = ACC.ACCESS_GB
       WHERE 1=1
	     AND ACC.ACCESS_GB = (CASE WHEN @P_ACCESS_GB <> '' THEN @P_ACCESS_GB ELSE ACC.ACCESS_GB END)
		 AND ACC.ACCESS_ID LIKE '%' + @P_ACCESS_ID + '%'
		 AND ACC.USE_YN = (CASE WHEN @P_USE_YN <> '' THEN @P_USE_YN ELSE ACC.USE_YN END)
		 AND CMM.DEL_YN = 'N'
		
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

