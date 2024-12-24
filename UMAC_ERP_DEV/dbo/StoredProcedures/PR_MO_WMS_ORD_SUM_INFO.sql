
/*
-- 생성자 :	이동호
-- 등록일 :	2024.04.22
-- 설 명  : 모바일(앱) 지시서 상세 SUMMARY 정보
			
-- 수정자 : -
-- 수정일 : - 
-- 실행문 : 

EXEC PR_MO_WMS_ORD_SUM_INFO '2240717001'
EXEC PR_MO_WMS_ORD_SUM_INFO '1240719001'
EXEC PR_MO_WMS_ORD_SUM_INFO '2240911010'



*/
CREATE PROCEDURE [dbo].[PR_MO_WMS_ORD_SUM_INFO]
( 	
	@P_ORD_NO			NVARCHAR(11) = ''		-- 주문번호	
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY 
				
		DECLARE @IO_GB INT = LEFT(@P_ORD_NO, 1) -- 1 : 입고, 2 : 출고

		DECLARE @PLT_KPP_QTY11 INT = 0, 
				@PLT_KPP_QTY12 INT = 0, 
				@PLT_AJ_QTY11 INT = 0, 
				@PLT_AJ_QTY12 INT = 0	
		SELECT 
				@PLT_KPP_QTY11 = PLT_KPP_QTY11, 
				@PLT_KPP_QTY12 = PLT_KPP_QTY12, 
				@PLT_AJ_QTY11 = PLT_AJ_QTY11, 
				@PLT_AJ_QTY12 = PLT_AJ_QTY12 
			FROM PO_ORDER_PLT WHERE ORD_NO = @P_ORD_NO

		--REGION 출고
		IF @IO_GB = 2 
		BEGIN			
				SELECT 
					@P_ORD_NO AS ORD_NO,																					--주문번호
					COUNT(SCAN_CODE) AS SCAN_CODE_CNT,																		--상품수량
					SUM(PICKING_QTY_SS) AS PICKING_QTY_CNT,																	--상품 검수완료 수량	
					CAST(SUM(ORD_QTY) AS INT) AS ORD_QTY_CNT,																--지시서 총수량
					CAST(SUM(PICKING_QTY_CNT) AS INT) AS PICKING_QTY_CNT_CNT,												--검수총수량
					WEIGHT_GB,
					CASE WHEN WEIGHT_GB = 'QTY' THEN 'EA' ELSE 'WT' END AS WEIGHT_GB_NM,

					--CAST(SUM(CASE WHEN WEIGHT_GB = 'QTY' THEN ORD_QTY ELSE 0 END) AS INT) AS QTY_ORD_QTY,					--지시서 총수량(수량)					
					--CAST(SUM(CASE WHEN WEIGHT_GB = 'QTY' THEN PICKING_QTY_CNT ELSE 0 END) AS INT) AS QTY_PICKING_QTY_CNT,	--검수 총수량(수량)					
					--CAST(SUM(CASE WHEN WEIGHT_GB = 'WT' THEN ORD_QTY ELSE 0 END) AS INT) AS WT_ORD_QTY,						--지시서 총수량(중량)					
					--CAST(SUM(CASE WHEN WEIGHT_GB = 'WT' THEN PICKING_QTY_CNT ELSE 0 END) AS INT) AS WT_PICKING_QTY_CNT,		--검수 총수량(중량)					
					@PLT_KPP_QTY11 AS PLT_KPP_QTY11,																		--PLT KPP-11형 수량
					@PLT_KPP_QTY12 AS PLT_KPP_QTY12,																		--PLT KPP-12형 수량
					@PLT_AJ_QTY11 AS PLT_AJ_QTY11,																			--PLT AJ-11형 수량
					@PLT_AJ_QTY12 AS PLT_AJ_QTY12																			--PLT AJ-12형 수량
				FROM (
					SELECT 
						ORD_NO,													--주문번호
						ITM_NAME,												--상품명
						SCAN_CODE,												--상품코드
						ORD_QTY,												--주문수량(지시서 수량)
						LOT_NO_CNT,												--LOT수량
						PICKING_QTY_CNT,										--검수수량(피킹수량)
						(CASE WHEN PICKING_QTY_CNT > 0 AND ORD_QTY = PICKING_QTY_CNT THEN 1 ELSE 0 END) AS PICKING_QTY_SS,
						WEIGHT_GB
					FROM (
						SELECT
							OHDR.ORD_NO,											
							CMN.ITM_NAME,											
							ODTL.SCAN_CODE,											
							ISNULL(ODTL.ORD_QTY,0) AS ORD_QTY,						
							ISNULL(OLOT.LOT_NO_CNT, 0) AS LOT_NO_CNT,				
							ISNULL(OLOT.PICKING_QTY_CNT,0) AS PICKING_QTY_CNT,
							CMN.WEIGHT_GB
						FROM PO_ORDER_HDR AS OHDR 	
							INNER JOIN VIEW_ORDER_DTL_SAMPLE_SUM AS ODTL ON ODTL.ORD_NO = OHDR.ORD_NO
							INNER JOIN CD_PRODUCT_CMN AS CMN ON CMN.SCAN_CODE = ODTL.SCAN_CODE	
							LEFT OUTER JOIN (
								SELECT ORD_NO, SCAN_CODE, SUM(CASE WHEN LOT_NO = '' THEN 0 ELSE 1 END) AS LOT_NO_CNT, SUM(PICKING_QTY) AS PICKING_QTY_CNT FROM PO_ORDER_LOT GROUP BY ORD_NO, SCAN_CODE
							) AS OLOT ON OLOT.ORD_NO = OHDR.ORD_NO AND OLOT.SCAN_CODE = ODTL.SCAN_CODE						
					) AS TBL

					WHERE TBL.ORD_NO = @P_ORD_NO

				) AS TBL2
				GROUP BY WEIGHT_GB
			

		END
		--ENDREGION 출고

		--REGION 입고
		ELSE IF @IO_GB = 1
		BEGIN

			SELECT 
				@P_ORD_NO AS ORD_NO,							--주문번호
				COUNT(SCAN_CODE) AS SCAN_CODE_CNT,				--상품수량
				SUM(PICKING_QTY_SS) AS PICKING_QTY_CNT,			--검수완료 수량
				CAST(SUM(ORD_QTY) AS INT) AS ORD_QTY_CNT,																	--지시서 총수량
				CAST(SUM(PICKING_QTY_CNT) AS INT) AS PICKING_QTY_CNT_CNT,													--검수총수량
				WEIGHT_GB,
				CASE WHEN WEIGHT_GB = 'QTY' THEN 'EA' ELSE 'WT' END AS WEIGHT_GB_NM,
				--CAST(SUM(CASE WHEN WEIGHT_GB = 'QTY' THEN ORD_QTY ELSE 0 END) AS INT) AS QTY_ORD_QTY,					--지시서 총수량(수량)
				--CAST(SUM(CASE WHEN WEIGHT_GB = 'QTY' THEN PICKING_QTY_CNT ELSE 0 END) AS INT) AS QTY_PICKING_QTY_CNT,	--검수 총수량(수량)
				--CAST(SUM(CASE WHEN WEIGHT_GB = 'WT' THEN ORD_QTY ELSE 0 END) AS INT) AS WT_ORD_QTY,						--지시서 총수량(중량)
				--CAST(SUM(CASE WHEN WEIGHT_GB = 'WT' THEN PICKING_QTY_CNT ELSE 0 END) AS INT) AS WT_PICKING_QTY_CNT,		--검수 총수량(중량)
				@PLT_KPP_QTY11 AS PLT_KPP_QTY11,				--PLT KPP-11형 수량
				@PLT_KPP_QTY12 AS PLT_KPP_QTY12,				--PLT KPP-12형 수량
				@PLT_AJ_QTY11 AS PLT_AJ_QTY11,					--PLT AJ-11형 수량
				@PLT_AJ_QTY12 AS PLT_AJ_QTY12					--PLT AJ-12형 수량
			FROM (
				SELECT 
					ORD_NO,													--주문번호
					ITM_NAME,												--상품명
					SCAN_CODE,												--상품코드
					ORD_QTY,												--주문수량(지시서 수량)
					LOT_NO_CNT,												--LOT수량
					PICKING_QTY_CNT,										--검수수량(피킹수량)
					(CASE WHEN PICKING_QTY_CNT > 0 AND ORD_QTY = PICKING_QTY_CNT THEN 1 ELSE 0 END) AS PICKING_QTY_SS,
					WEIGHT_GB
				FROM (
					SELECT
						OHDR.ORD_NO,											
						CMN.ITM_NAME,											
						ODTL.SCAN_CODE,											
						ISNULL(ODTL.ORD_QTY,0) AS ORD_QTY,
						0 AS LOT_NO_CNT,
						ISNULL(ODTL.PUR_QTY,0) AS PICKING_QTY_CNT,
						CMN.WEIGHT_GB
					FROM PO_PURCHASE_HDR AS OHDR 	
						INNER JOIN PO_PURCHASE_DTL AS ODTL ON ODTL.ORD_NO = OHDR.ORD_NO
						INNER JOIN CD_PRODUCT_CMN AS CMN ON CMN.SCAN_CODE = ODTL.SCAN_CODE
						
				) AS TBL

				WHERE TBL.ORD_NO = @P_ORD_NO

			) AS TBL2
			GROUP BY WEIGHT_GB

		END
		--ENDREGION 입고
			
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

