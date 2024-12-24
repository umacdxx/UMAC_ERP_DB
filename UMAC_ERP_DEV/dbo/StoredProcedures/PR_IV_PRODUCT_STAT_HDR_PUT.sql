/*
-- 생성자 :	윤현빈
-- 등록일 :	2024.04.12
-- 수정자 : 이동호
-- 수정일 : 2024.05.02
-- 설 명  : (공통)상품 재고 업데이트 처리
			2024.11.12 최수민 : 반품일 때 재고는 + 처리되어야 함
-- 실행문 : 


DECLARE @R_RETURN_CODE 		INT
DECLARE @R_RETURN_MESSAGE 	NVARCHAR(10)
EXEC PR_IV_PRODUCT_STAT_HDR_PUT '8807596310009',10, 'TEST1', 0, '20260513-CA-DW-210110', @R_RETURN_CODE OUT, @R_RETURN_MESSAGE OUT
SELECT @R_RETURN_CODE, @R_RETURN_MESSAGE
*/
CREATE PROCEDURE [dbo].[PR_IV_PRODUCT_STAT_HDR_PUT]	
	@P_SCAN_CODE		NVARCHAR(14),			-- #(필수)상품코드
	@P_CHG_QTY			NUMERIC(15,2),			-- #(필수)변경수량
	@P_PROCEDUAL_NM		VARCHAR(30),			-- #(필수)프로시저 or 실행 히스토리 이름
	@P_PRE_PROD_QTY		NUMERIC(15,2),			-- 변경이전수량 CD_LOT_MST.PROD_QTY
	@P_LOT_NO			VARCHAR(500),			-- #LOT 번호(,쉼표구분으로 해당 상품의 LOT 번호를 가저옴)
	@P_ORD_NO			NVARCHAR(11),			-- 주문번호
	@P_BOX_SCAN_CODE	NVARCHAR(14),			-- 박스이면 박스코드(SCAN_CODE), 박스 아니면 '' 값
	@R_RETURN_CODE 		INT 			OUTPUT,	-- 리턴코드
	@R_RETURN_MESSAGE 	NVARCHAR(10) 	OUTPUT 	-- 리턴메시지
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	DECLARE @MAX_SEQ INT = 0
	DECLARE @ITM_CODE NVARCHAR(6)				--상품 아이템코드
	DECLARE @SCAN_CODE NVARCHAR(14) = ''		--신규 재고 등록 상품 인지 판단 여부	
	DECLARE @CUR_INV_QTY NUMERIC(15,2) = 0		--업데이트 재고수량		
	DECLARE @LAST_PUR_DT NVARCHAR(8) = ''		--최종 매입일자
	DECLARE @LAST_SALE_DT NVARCHAR(8) = ''		--최종 매출일자	
	DECLARE @V_PICKING_QTY NUMERIC(15,2) = 0
	DECLARE @V_PRE_PROD_QTY NUMERIC(15,2) = 0	--LOT 변경전 수량
	DECLARE @TMP_LOT_NO NVARCHAR(30) = ''

	SET @P_LOT_NO = ISNULL(@P_LOT_NO, '');
	SET @TMP_LOT_NO = @P_LOT_NO;

	BEGIN TRAN
	BEGIN TRY 
		--ERR 테스트
		--DECLARE @P INT = 0
		--SET @P = 1/0
		--ERR 테스트//
			
		--# 상품의 LOT별 재고 업데이트
		IF @P_LOT_NO <> ''
		BEGIN		
			DECLARE @DELIMITER VARCHAR(1) = ','
			DECLARE @R_LOT_NO VARCHAR(30) = ''			
			SET @P_LOT_NO = REPLACE(@P_LOT_NO,', ',',')  
			SET @P_LOT_NO = @P_LOT_NO + @DELIMITER

			WHILE CHARINDEX(@DELIMITER, @P_LOT_NO) > 0  
			BEGIN  	
				SET @R_LOT_NO = LEFT(@P_LOT_NO,CHARINDEX(@DELIMITER, @P_LOT_NO)-1)      		
				SET @P_LOT_NO = SUBSTRING(@P_LOT_NO,CHARINDEX(@DELIMITER, @P_LOT_NO) + 1, LEN(@P_LOT_NO))    
				IF (@R_LOT_NO <> '')  
				BEGIN  					
					-------------- lot별 수량 처리하기 위해 추가
					IF @P_ORD_NO != '' AND @P_ORD_NO IS NOT NULL
					BEGIN
					
						DECLARE @IO_GB NVARCHAR(1)
						SET @IO_GB = SUBSTRING(@P_ORD_NO, 1, 1);


						IF @P_BOX_SCAN_CODE != ''
						BEGIN
							WITH W_BOX_DATA AS (
								SELECT B.SCAN_CODE AS BOX_CODE
								     , C.SCAN_CODE AS COMP_CODE
									 , A.IPSU_QTY
									FROM CD_BOX_MST AS A
								    INNER JOIN CD_PRODUCT_CMN AS B ON A.BOX_CODE = B.ITM_CODE
								    INNER JOIN CD_PRODUCT_CMN AS C ON A.ITM_CODE = C.ITM_CODE
								   WHERE B.SCAN_CODE = @P_BOX_SCAN_CODE
							)
							SELECT @V_PICKING_QTY = A.PICKING_QTY * B.IPSU_QTY,
								   @V_PRE_PROD_QTY = A.TEMP_QTY * B.IPSU_QTY
								FROM PO_ORDER_LOT AS A
								INNER JOIN W_BOX_DATA AS B ON A.SCAN_CODE = B.BOX_CODE
							   WHERE A.ORD_NO = @P_ORD_NO 
								 AND A.SCAN_CODE = @P_BOX_SCAN_CODE 
								 AND A.LOT_NO = @R_LOT_NO
								 ;
						END
						ELSE
						BEGIN
							SELECT @V_PICKING_QTY = PICKING_QTY, 
								   @V_PRE_PROD_QTY = TEMP_QTY
								FROM PO_ORDER_LOT 
							   WHERE ORD_NO = @P_ORD_NO 
								 AND SCAN_CODE = @P_SCAN_CODE 
								 AND LOT_NO = @R_LOT_NO
								 ;
						END

						/* 2024.11.12 최수민 반품일 때 재고는 + 처리되어야 함 */
						IF @IO_GB = '2' AND (SELECT ORD_GB FROM PO_ORDER_HDR WHERE ORD_NO = @P_ORD_NO) = 1
						BEGIN
							SET @V_PICKING_QTY = @V_PICKING_QTY * (-1)
							SET @V_PRE_PROD_QTY = @V_PRE_PROD_QTY * (-1)
						END
					END
					ELSE 
					BEGIN
						SET @V_PICKING_QTY = @P_CHG_QTY;
					END
					-------------- lot별 수량 처리하기 위해 추가

					--EXEC PR_IV_LOT_STAT_HDR_PUT @P_SCAN_CODE, @R_LOT_NO, @P_CHG_QTY, @P_PROCEDUAL_NM, @P_PRE_PROD_QTY, @R_RETURN_CODE OUT, @R_RETURN_MESSAGE OUT
					--EXEC PR_IV_LOT_STAT_HDR_PUT @P_SCAN_CODE, @R_LOT_NO, @V_PICKING_QTY, @P_PROCEDUAL_NM, @P_PRE_PROD_QTY, @R_RETURN_CODE OUT, @R_RETURN_MESSAGE OUT

					-- 2024.09.25 윤현빈 추가, BOM은 LOT별 재고 처리 x
					IF @P_PROCEDUAL_NM != 'PR_PROD_STOCK_REGISTER_PUT'
					BEGIN
						EXEC PR_IV_LOT_STAT_HDR_PUT @P_SCAN_CODE, @R_LOT_NO, @V_PICKING_QTY, @P_PROCEDUAL_NM, @V_PRE_PROD_QTY, @R_RETURN_CODE OUT, @R_RETURN_MESSAGE OUT

						--- TEMP_QTY 업데이트
						UPDATE PO_ORDER_LOT
						   SET TEMP_QTY = 0
						 WHERE ORD_NO = @P_ORD_NO AND SCAN_CODE = @P_SCAN_CODE AND LOT_NO = @R_LOT_NO
					END
					ELSE
					BEGIN
						IF EXISTS (
							SELECT 1 FROM CD_PRODUCT_CMN WHERE SCAN_CODE = @P_SCAN_CODE AND ITM_FORM = '1'
						)
						BEGIN
							EXEC PR_IV_LOT_STAT_HDR_PUT @P_SCAN_CODE, @TMP_LOT_NO, @P_CHG_QTY, @P_PROCEDUAL_NM, @P_PRE_PROD_QTY, @R_RETURN_CODE OUT, @R_RETURN_MESSAGE OUT
						END
					END
				END  
			END  
		END
		--# 상품의 LOT별 재고 업데이트 //
		
	

		--상품 정보
		SELECT @ITM_CODE = ITM_CODE FROM CD_PRODUCT_CMN WHERE SCAN_CODE = @P_SCAN_CODE;
				
		--현재고수량
		SELECT @CUR_INV_QTY = CUR_INV_QTY, @SCAN_CODE = SCAN_CODE FROM IV_PRODUCT_STAT WHERE SCAN_CODE = @P_SCAN_CODE
		
		IF @P_PRE_PROD_QTY <> 0
		BEGIN					
			--생산관리 에서 생산 수량 변경시 재고 업데이트			
			SET @CUR_INV_QTY = @CUR_INV_QTY - (@P_PRE_PROD_QTY - @P_CHG_QTY)
		END
		ELSE
		BEGIN
			--주문/발주 재고 업데이트
			SET @CUR_INV_QTY = @CUR_INV_QTY + @P_CHG_QTY					
		END 
		
		IF @SCAN_CODE = ''
		BEGIN		
		
			--#재고 신규등록
			INSERT IV_PRODUCT_STAT (
				ITM_CODE, 
				SCAN_CODE, 
				LAST_PUR_DT, 
				LAST_SALE_DT, 
				CUR_INV_QTY, 
				UDATE 
			)
			VALUES(
				@ITM_CODE, 
				@P_SCAN_CODE, 
				@LAST_PUR_DT, 
				@LAST_SALE_DT, 
				@P_CHG_QTY, 
				GETDATE()
			)

		END
		ELSE
		BEGIN							
			--#재고 업데이트
			UPDATE IV_PRODUCT_STAT SET 
						CUR_INV_QTY = @CUR_INV_QTY, 
						LAST_PUR_DT = @LAST_PUR_DT,
						LAST_SALE_DT = @LAST_SALE_DT,
						UDATE = GETDATE() 
				WHERE SCAN_CODE = @P_SCAN_CODE
		END
	

		SELECT @MAX_SEQ = ISNULL(MAX(LOG_SEQ) + 1, 1) FROM IV_PRODUCT_STAT_LOG
		INSERT INTO IV_PRODUCT_STAT_LOG
		(
			LOG_SEQ
		  , SYS_NAME
		  , SCAN_CODE
		  , BEFO_QTY
		  , CHG_QTY
		  , AFT_QTY
		  , IDATE
		)
		VALUES
		(
		    @MAX_SEQ
		  , @P_PROCEDUAL_NM
		  , @P_SCAN_CODE
		  , @CUR_INV_QTY - @P_CHG_QTY
		  , @P_CHG_QTY
		  , @CUR_INV_QTY
		  , GETDATE()
		)
			
		SET @R_RETURN_CODE = 0 -- 저장완료
		SET @R_RETURN_MESSAGE = DBO.GET_ERR_MSG('0')	
		
		COMMIT;

	END TRY
	BEGIN CATCH	
				
		IF @@TRANCOUNT > 0
		BEGIN 
			ROLLBACK TRAN
			
			--에러 로그 테이블 저장
			INSERT INTO TBL_ERROR_LOG 
			SELECT ERROR_PROCEDURE()			-- 프로시저명
					, ERROR_MESSAGE()			-- 에러메시지
					, ERROR_LINE()				-- 에러라인
					, GETDATE()	

			SET @R_RETURN_CODE = -91 -- 재고 실패
			SET @R_RETURN_MESSAGE = DBO.GET_ERR_MSG('-91')

		END 
	END CATCH
	

END

GO

