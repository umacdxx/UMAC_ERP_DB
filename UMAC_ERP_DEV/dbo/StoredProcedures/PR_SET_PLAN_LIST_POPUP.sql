/*
-- 생성자 :	윤현빈
-- 등록일 :	2024.08.12
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : SET 생산 계획 조회 팝업
-- 실행문 : EXEC PR_SET_PLAN_LIST_POPUP '','','','',''
*/
CREATE PROCEDURE [dbo].[PR_SET_PLAN_LIST_POPUP]
( 
	@P_SET_PLAN_NM			NVARCHAR(100) = '',		-- 작업명(코드)
	@P_SET_STATUS			NVARCHAR(2) = '',		-- 작업상태
	@P_SET_PLAN_SDATE		NVARCHAR(8) = '',		-- 작업예정시작일자
	@P_SET_PLAN_EDATE		NVARCHAR(8) = ''		-- 작업예정종료일자
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY 	
	

		SELECT A.SET_PLAN_ID
		     , A.SET_PLAN_NM
			 , A.SET_PLAN_SDATE
			 , A.SET_PLAN_EDATE
			 , A.SET_STATUS AS SET_STATUS_CD
			 , B.CD_NM AS SET_STATUS_NM
			FROM PD_SET_PLAN_MST AS A
			INNER JOIN TBL_COMM_CD_MST AS B ON B.CD_CL = 'SET_STATUS' AND A.SET_STATUS = B.CD_ID AND DEL_YN = 'N'
		   WHERE (A.SET_PLAN_SDATE <= @P_SET_PLAN_EDATE AND A.SET_PLAN_EDATE >= @P_SET_PLAN_SDATE)
		     AND (A.SET_PLAN_ID LIKE '%'+@P_SET_PLAN_NM+'%' OR A.SET_PLAN_NM LIKE '%'+@P_SET_PLAN_NM+'%')
		     AND 1=(CASE WHEN @P_SET_STATUS = '' THEN 1 WHEN @P_SET_STATUS != '' AND A.SET_STATUS = @P_SET_STATUS THEN 1 ELSE 2 END)
		   ORDER BY A.SET_STATUS, A.SET_PLAN_ID DESC


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
