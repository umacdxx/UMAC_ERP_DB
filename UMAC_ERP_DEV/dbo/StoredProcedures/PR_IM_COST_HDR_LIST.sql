/*
-- 생성자 :	강세미
-- 등록일 :	2024.05.21
-- 수정자 : 2024.12.04 강세미- 신규 BL_NO 추가
-- 수정일 : - 
-- 설 명  : 수입제비용 HDR 조회
-- 실행문 : 
EXEC PR_IM_COST_HDR_LIST '', '202405', ''
*/
CREATE PROCEDURE [dbo].[PR_IM_COST_HDR_LIST]
( 
	@P_PO_NO		NVARCHAR(15) = '',		-- PO번호
	@P_PO_ORD_DT	NVARCHAR(6) = '',		-- 발주월
	@P_VEN_CODE		NVARCHAR(7) = ''		-- 수입업체코드
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
	BEGIN TRY 
		SELECT A.PO_NO,
			   A.PO_NAME,
			   A.PO_ORD_DT,
			   A.LC_NO,
			   A.LC_OPEN_DT,
			   A.BL_NO,
			   A.BL_NO_2,
			   A.BL_NO_3,
			   A.CURRENCY_TYPE,
			   A.LC_EXCHANGE_RATE,
			   A.TT_EXCHANGE_RATE,
			   (CASE WHEN A.NOT_DELIVERED_SLIP = 'Y' THEN '생성' ELSE '미생성' END) AS NOT_DELIVERED_SLIP,
			   (CASE WHEN A.PUR_SLIP = 'Y' THEN '생성' ELSE '미생성' END) AS PUR_SLIP,
			   B.FRGN_WPRC_AMT_SUM,
			   B.WPRC_AMT_SUM,
			   (CASE WHEN C.ALTRN_SLIP = 'Y' THEN '생성' ELSE '미생성' END) AS ALTRN_SLIP,
			   (CASE WHEN C.COST_CFM = 'Y' THEN '확정' ELSE '미확정' END) AS COST_CFM,
			   ISNULL(D.PUR_STATUS, '미완료') AS PUR_STATUS,
			   E.VEN_NAME
		  FROM IM_ORDER_HDR AS A 
			INNER JOIN (SELECT A.PO_NO,
							   SUM(ISNULL(B.FRGN_WPRC_AMT,0)) AS FRGN_WPRC_AMT_SUM,
							   SUM(ISNULL(B.WPRC_AMT,0)) AS WPRC_AMT_SUM
						FROM IM_ORDER_HDR AS A
							LEFT OUTER JOIN IM_ORDER_DTL AS B
							ON A.PO_NO = B.PO_NO
						GROUP BY A.PO_NO) AS B ON A.PO_NO = B.PO_NO
			LEFT OUTER JOIN IM_COST_HDR AS C ON C.PO_NO = A.PO_NO
			LEFT OUTER JOIN (SELECT PO_NO,
							(CASE WHEN SUM(ISNULL(PUR_WAMT,0)) > 0 THEN '완료'
                                     ELSE '미완료' END) AS PUR_STATUS
							 FROM IM_ORDER_DTL
							 GROUP BY PO_NO) AS D ON D.PO_NO = A.PO_NO
			INNER JOIN CD_PARTNER_MST AS E ON A.VEN_CODE = E.VEN_CODE
  		 WHERE 1 = (CASE WHEN @P_PO_NO = '' THEN 1 WHEN @P_PO_NO <> '' AND A.PO_NO = @P_PO_NO THEN 1 ELSE 0 END)
			AND 1 = (CASE WHEN @P_PO_ORD_DT = '' THEN 1 WHEN @P_PO_ORD_DT <> '' AND SUBSTRING(A.PO_ORD_DT, 1, 6) = @P_PO_ORD_DT THEN 1 ELSE 0 END)
			AND 1 = (CASE WHEN @P_VEN_CODE = '' THEN 1 WHEN @P_VEN_CODE <> '' AND A.VEN_CODE = @P_VEN_CODE THEN 1 ELSE 0 END)

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

