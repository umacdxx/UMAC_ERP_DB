/*
-- 생성자 :	강세미
-- 등록일 :	2023.01.30
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : SET 마스터 HDR 리스트 출력
-- 실행문 : 
EXEC PR_SET_MST_HDR_LIST '카놀라유(대상,청정원카놀라유,PET,500ML)','Y','','',''
*/
CREATE PROCEDURE [dbo].[PR_SET_MST_HDR_LIST]
( 
	@P_SCAN_CODE	NVARCHAR(14) = '',   -- 상품코드
	@P_USE_YN		NVARCHAR(1) = '',		-- 사용여부
	@P_LRG_CODE		NVARCHAR(2) = '',		-- 대분류코드
	@P_MID_CODE		NVARCHAR(4) = '',		-- 중분류코드
	@P_SET_COMP_CD NVARCHAR(14) = ''		-- SET 구성품 코드
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SET @P_SET_COMP_CD = ISNULL(@P_SET_COMP_CD,'')

	BEGIN TRY 
	IF @P_SET_COMP_CD = ''
		BEGIN
			SELECT ROW_NUMBER() OVER(ORDER BY SET_CD) AS ROW_NUM
				, A.SET_CD
				, A.SET_NAME
				, A.SET_PROD_CD				
				, A.USE_YN
				, B.ITM_CODE
				, B.ITM_NAME_DETAIL AS SET_PROD_NM
				, B.UNIT_CAPACITY
				, B.UNIT
				, E.CD_NM AS UNIT_NM
			FROM CD_SET_HDR AS A
				INNER JOIN CD_PRODUCT_CMN AS B
					ON B.SCAN_CODE = A.SET_PROD_CD
				INNER JOIN CD_MID_MST AS C
					ON C.MID_CODE = B.MID_CODE
				INNER JOIN CD_LRG_MST AS D
					ON D.LRG_CODE = C.LRG_CODE
				INNER JOIN TBL_COMM_CD_MST AS E
					ON E.CD_CL = 'UNIT' AND B.UNIT = E.CD_ID
			WHERE (A.SET_PROD_CD = CASE WHEN @P_SCAN_CODE <> '' THEN @P_SCAN_CODE ELSE B.SCAN_CODE END)
					AND (A.USE_YN = CASE WHEN @P_USE_YN <> '' THEN @P_USE_YN ELSE A.USE_YN END)
					AND (D.LRG_CODE = (CASE WHEN @P_LRG_CODE <> '' THEN @P_LRG_CODE ELSE D.LRG_CODE END) AND C.MID_CODE = (CASE WHEN @P_MID_CODE <> '' THEN @P_MID_CODE ELSE C.MID_CODE END))
		
		END
	ELSE
		BEGIN
			SELECT ROW_NUMBER() OVER(ORDER BY A.SET_CD) AS ROW_NUM
				, A.SET_CD
				, A.SET_NAME
				, A.SET_PROD_CD				
				, A.USE_YN
				, B.ITM_CODE
				, B.ITM_NAME_DETAIL AS SET_PROD_NM
				, B.UNIT_CAPACITY
				, B.UNIT
				, E.CD_NM AS UNIT_NM
			FROM CD_SET_HDR AS A
				INNER JOIN CD_PRODUCT_CMN AS B
					ON B.SCAN_CODE = A.SET_PROD_CD
				INNER JOIN CD_SET_DTL AS C
					ON A.SET_CD = C.SET_CD
				INNER JOIN TBL_COMM_CD_MST AS E
					ON E.CD_CL = 'UNIT' AND B.UNIT = E.CD_ID
			WHERE C.SET_COMP_CD = @P_SET_COMP_CD
				AND  A.USE_YN = CASE WHEN @P_USE_YN <> '' THEN @P_USE_YN ELSE A.USE_YN END

		END
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

