/*
-- 생성자 :	윤현빈
-- 등록일 :	2024.07.30
-- 수정자 : -
-- 수정일 : - 
-- 설 명  : 상품별 LOT 생산 및 재고 정보
-- 실행문 : EXEC PR_PROD_LOT_LIST '120010'
*/
CREATE PROCEDURE [dbo].[PR_PROD_LOT_LIST]
( 
	@P_SCAN_CODE	NVARCHAR(14) = ''	
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY 	
        DECLARE @V_SCAN_CODE NVARCHAR(14);

        SELECT @V_SCAN_CODE = CASE WHEN A.ITM_FORM = '2' THEN C.SCAN_CODE ELSE A.SCAN_CODE END
            FROM CD_PRODUCT_CMN AS A 
            LEFT OUTER JOIN CD_BOX_MST AS B ON A.ITM_CODE = B.BOX_CODE
            LEFT OUTER JOIN CD_PRODUCT_CMN AS C ON B.ITM_CODE = C.ITM_CODE
           WHERE A.SCAN_CODE = @P_SCAN_CODE
		
		SELECT ROW_NUMBER() OVER(ORDER BY A.LOT_NO) AS ROW_NUM
		     , A.LOT_NO
			 , B.PROD_DT
			 --, LEFT(A.LOT_NO, 8) AS EXPIRY_DT
			 , B.EXPIRATION_DT AS EXPIRY_DT
			 , A.CUR_INV_QTY
			 , C.WEIGHT_GB
			FROM IV_LOT_STAT AS A
			INNER JOIN CD_LOT_MST AS B ON A.SCAN_CODE = B.SCAN_CODE AND A.LOT_NO = B.LOT_NO
			INNER JOIN CD_PRODUCT_CMN AS C ON A.SCAN_CODE = C.SCAN_CODE
		   WHERE A.SCAN_CODE = @V_SCAN_CODE
			 --AND A.CUR_INV_QTY != 0
			 AND C.ITM_FORM != '3'

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
