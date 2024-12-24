/*
-- 생성자 :	강세미
-- 등록일 :	2023.05.17
-- 설 명  : 수입발주등록 > 파일 리스트 조회
-- 수정자 :
-- 수정일 :
-- 설 명  :	
-- 실행문 : 
EXEC PR_IM_FILE_LIST 'PO240521'
*/
CREATE PROCEDURE [dbo].[PR_IM_FILE_LIST]
( 
	@P_PO_NO		NVARCHAR(15) = ''			-- PO번호
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY 
	 
	 WITH CTE AS (
		SELECT 
			A.SEQ,
			A.PO_NO,
			A.DOC_DIV,
			A.DOC_NAME,
			A.REAL_DOC_NAME,
			A.REMARKS,
			CONVERT(NVARCHAR(8), A.IDATE, 112) AS IDATE,
			A.IEMP_ID,
			B.USER_NM AS IEMP_NM,
			CONVERT(NVARCHAR(8), A.UDATE, 112) AS UDATE,
			A.UEMP_ID,
			C.USER_NM AS UEMP_NM,
			ROW_NUMBER() OVER (PARTITION BY CASE 
											 WHEN A.DOC_DIV IN ('1', '2') THEN DOC_DIV 
											 ELSE '3' 
										 END ORDER BY A.SEQ ASC) AS ROW_NUM
		FROM IM_ORDER_UPLOAD AS A
			INNER JOIN TBL_USER_MST AS B ON A.IEMP_ID = B.[USER_ID]
			LEFT OUTER JOIN TBL_USER_MST AS C ON A.UEMP_ID = C.[USER_ID]
		WHERE PO_NO = @P_PO_NO
	)
	SELECT 
		ROW_NUM,
		SEQ,
		PO_NO,
		DOC_DIV,
		(CASE 
			WHEN DOC_DIV = '1' THEN 'L/C'
			WHEN DOC_DIV = '2' THEN 'B/L'
			ELSE CONCAT('기타파일', ROW_NUM) END) AS DOC_DIV_NM,
		DOC_NAME,
		REAL_DOC_NAME,
		REMARKS,
		IDATE,
		IEMP_ID,
		IEMP_NM,
		UDATE,
		UEMP_ID,
		UEMP_NM
	FROM CTE
	ORDER BY SEQ;


		--SELECT 
		--	ROW_NUMBER() OVER(ORDER BY SEQ ASC) AS ROW_NUM,
		--	SEQ,
		--	PO_NO,
		--	DOC_DIV,
		--	(CASE DOC_DIV WHEN '1' THEN 'L/C'
		--				  WHEN '2' THEN 'B/L'
		--				  ELSE CONCAT('기타파일',@FILE_SEQ) END) AS DOC_DIV_NM,
		--	DOC_NAME,
		--	REAL_DOC_NAME,
		--	REMARKS,
		--	CONVERT(NVARCHAR(8), IDATE, 112)AS IDATE,
		--	IEMP_ID,
		--	CONVERT(NVARCHAR(8), UDATE, 112)AS UDATE,
		--	UEMP_ID
		--	FROM IM_ORDER_UPLOAD
		--WHERE PO_NO = @P_PO_NO
					
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

