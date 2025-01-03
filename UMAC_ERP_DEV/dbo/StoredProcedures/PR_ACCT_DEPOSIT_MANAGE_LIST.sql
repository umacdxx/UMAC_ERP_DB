/*
-- 생성자 :	윤현빈
-- 등록일 :	2024.12.09
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : 일반계좌입금처리
-- 실행문 : EXEC PR_ACCT_DEPOSIT_MANAGE_LIST '','','','',''
*/
CREATE PROCEDURE [dbo].[PR_ACCT_DEPOSIT_MANAGE_LIST]
( 
	@P_VEN_CODE			NVARCHAR(7) = '',
	@P_FROM_DT			NVARCHAR(8) = '',
	@P_TO_DT			NVARCHAR(8) = '',
	@P_DEPOSIT_USER_NM	NVARCHAR(20) = '',
	@P_GENERAL_ACC_NO	NVARCHAR(30) = '',
	@P_DPS_YN			NVARCHAR(1) = '',
	@P_DPS_AMT			INT 
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY 	

		SELECT ROW_NUMBER() OVER(ORDER BY DPS_YN, ACCT_DT DESC, ACCT_NO) AS ROW_NUM
			 , A.* 
			FROM (
				SELECT A.CMS_SEQ
					 , CASE WHEN B.MOID IS NULL THEN '미처리' ELSE '완료' END AS DPS_YN
				     , CASE WHEN B.MOID IS NULL THEN 'N' ELSE 'Y' END AS DPS_GB					 
					 , A.CRYP_CMSV_ACCT_NO AS ACCT_NO
					 , A.TRSC_DT AS ACCT_DT
					 --, A.CMSV_ACCT_TRSC_DV_CTT AS BANK_NM
					 , E.CD_DESCRIPTION AS BANK_NM
					 , A.TX_AMT
					 , A.RCRD_MTTR_CTT AS DPS_USER_NM
					 , ISNULL(C.VEN_NAME, '') AS VEN_NAME
					 , ISNULL(D.USER_NM, '') AS CFM_USER_NM
					 , ISNULL(B.VEN_CODE, '') AS VEN_CODE
					 , ISNULL(B.VEN_CODE, '') AS ORG_VEN_CODE
					 , A.INST_DV_NO
					 , A.CMSV_CUR_CD
					 , A.CMSV_ACCT_TRSC_SEQ_NO
					 , ISNULL(A.MOID, '') AS MOID
					 , ISNULL(B.DEPOSIT_NO, '') AS DEPOSIT_NO
					FROM HCMS_ACCT_TRSC_PTCL AS A
					INNER JOIN TBL_COMM_CD_MST AS E ON E.CD_CL = 'GENERAL_ACC_NO_LIST' AND A.CRYP_CMSV_ACCT_NO = E.CD_NM
					LEFT OUTER JOIN PA_ACCT_DEPOSIT AS B ON A.MOID = B.MOID
					LEFT OUTER JOIN CD_PARTNER_MST AS C ON B.VEN_CODE = C.VEN_CODE
					LEFT OUTER JOIN TBL_USER_MST AS D ON A.CFM_EMP_ID = D.USER_ID
					LEFT JOIN TBL_COMM_CD_MST AS F ON F.CD_CL = 'GENERAL_EXCLUDE_LIST' AND F.CD_NM = A.RCRD_MTTR_CTT
				   WHERE A.RCV_WDRW_DV_CD = '1'
					 --AND A.CRYP_CMSV_ACCT_NO IN (SELECT CD_NM FROM TBL_COMM_CD_MST WHERE CD_CL = 'GENERAL_ACC_NO_LIST')
					 AND A.TRSC_DT BETWEEN @P_FROM_DT AND @P_TO_DT
					 AND 1=(CASE WHEN @P_VEN_CODE = '' THEN 1 WHEN @P_VEN_CODE != '' AND B.VEN_CODE = @P_VEN_CODE THEN 1 ELSE 2 END)
					 AND 1=(CASE WHEN @P_GENERAL_ACC_NO = '' THEN 1 WHEN @P_GENERAL_ACC_NO != '' AND A.CRYP_CMSV_ACCT_NO = @P_GENERAL_ACC_NO THEN 1 ELSE 2 END)
					 AND 1=(CASE WHEN @P_DEPOSIT_USER_NM = '' THEN 1 WHEN @P_DEPOSIT_USER_NM != '' AND A.RCRD_MTTR_CTT LIKE '%'+@P_DEPOSIT_USER_NM+'%' THEN 1 ELSE 2 END)
					 AND 1=(CASE WHEN @P_DPS_AMT = '' THEN 1 WHEN @P_DPS_AMT != '' AND A.TX_AMT = @P_DPS_AMT THEN 1 ELSE 2 END)
				     AND F.CD_CL IS NULL
			) AS A
		   WHERE 1=(CASE WHEN @P_DPS_YN = '' THEN 1 WHEN @P_DPS_YN != '' AND DPS_GB = @P_DPS_YN THEN 1 ELSE 2 END)

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

