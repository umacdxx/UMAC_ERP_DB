/*
-- 생성자 :	강세미
-- 등록일 :	2024.09.25
-- 수정자 : 2024.10.31 강세미 - 로직변경
			2024.12.03 강세미 - 담당자 조회조건 수정
-- 설 명  : 월매입마감 내역
-- 실행문 : EXEC PR_CLOSING_PURCHASE_LIST '202409','','',''
*/
CREATE PROCEDURE [dbo].[PR_CLOSING_PURCHASE_LIST]
	@P_CLOSE_DT			NVARCHAR(6),		-- 마감월
	@P_DEPT_CODE		NVARCHAR(25),		-- 조직코드
	@P_VEN_CODE			NVARCHAR(7),		-- 거래처코드
	@P_MGNT_USER_ID		NVARCHAR(300)		-- 담당자ID (',' 구분)
AS 
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY 
		
		WITH PURCHASE_TBL AS (
			SELECT  LEFT(A.CLOSE_DT, 6) AS CLOSE_MM,
					A.VEN_CODE,
					A.DOUZONE_FLAG,
					A.CLOSE_EMP_ID,
					A.CLOSE_STAT,
					ROUND((SUM(A.PUR_TOTAL_AMT) / 1.1), 0) AS PUR_TOTAL_WPRC,
					ROUND(SUM(A.PUR_TOTAL_AMT) - (SUM(A.PUR_TOTAL_AMT) / 1.1), 0) AS PUR_TOTAL_WVAT,
					SUM(A.PUR_TOTAL_AMT) AS PUR_TOTAL_WAMT
			FROM PO_PURCHASE_HDR AS A
			WHERE A.CLOSE_DT LIKE @P_CLOSE_DT + '%' 
				AND A.CLOSE_STAT = 'Y'
			GROUP BY A.VEN_CODE, LEFT(A.CLOSE_DT, 6), A.CLOSE_EMP_ID, A.CLOSE_STAT, A.DOUZONE_FLAG
		)
		SELECT A.CLOSE_MM,
			   A.VEN_CODE,
			   B.VEN_NAME,
			   C.USER_NM AS MGNT_USER_NM,
			   D.DEPT_NAME,
			   A.PUR_TOTAL_WPRC,	-- 실마감금액(공급가)
			   A.PUR_TOTAL_WVAT,	-- 실마감금액(부가세)
			   A.PUR_TOTAL_WAMT,		--실마감금액(합계)
			   ISNULL(A.CLOSE_STAT, 'N') AS CLOSE_STAT,
			   F.USER_NM AS CLOSE_EMP_NM,
			   ISNULL(A.DOUZONE_FLAG, 'N') AS DOUZONE_FLAG
		  FROM PURCHASE_TBL AS A
		  INNER JOIN CD_PARTNER_MST AS B
			ON A.VEN_CODE = B.VEN_CODE
		  LEFT OUTER JOIN TBL_USER_MST AS C
			ON B.MGNT_USER_ID = C.[USER_ID]
		  LEFT OUTER JOIN TBL_DEPT_MST AS D
			ON C.DEPT_CODE = D.DEPT_CODE
		  LEFT OUTER JOIN TBL_USER_MST AS F
			ON A.CLOSE_EMP_ID = F.[USER_ID]
		  WHERE A.CLOSE_MM LIKE @P_CLOSE_DT + '%' 
				AND 1 = (CASE WHEN @P_DEPT_CODE = '' THEN 1 WHEN @P_DEPT_CODE <> '' AND D.DEPT_CODE LIKE @P_DEPT_CODE + '%' THEN 1 ELSE 0 END)
				AND (
						@P_MGNT_USER_ID = ''
						OR
						( B.MGNT_USER_ID IN (SELECT VALUE FROM STRING_SPLIT(@P_MGNT_USER_ID, ','))
							OR ( 'ETC' IN (SELECT VALUE FROM STRING_SPLIT(@P_MGNT_USER_ID, ','))
								 AND (B.MGNT_USER_ID IS NULL OR B.MGNT_USER_ID = ''))
						)
					)
				AND 1 = (CASE WHEN @P_VEN_CODE = '' THEN 1 WHEN @P_VEN_CODE <> '' AND B.VEN_CODE = @P_VEN_CODE THEN 1 ELSE 0 END)
		  ORDER BY A.VEN_CODE

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

