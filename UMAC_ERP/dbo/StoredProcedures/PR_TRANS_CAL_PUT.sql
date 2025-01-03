/*
-- 생성자 :	강세미
-- 등록일 :	2024.09.03
-- 수정자 : 2024.11.29 강세미 - 배차여부(TRANS_YN) 수정 추가
			2024.12.04 강세미 - PO_PURCHASE_HDR UPDATE 추가
-- 수정일 : - 
-- 설 명  : 배차정산 저장
-- 실행문 : EXEC PR_TRANS_CAL_PUT '2241014001', 100000, 100000, '1', '화순', '1', '123가1234', 'F', 'ksm2094'
*/
CREATE PROCEDURE [dbo].[PR_TRANS_CAL_PUT]
	@P_ORD_NO			NVARCHAR(11),	-- 주문번호
	@P_TRANS_COST		INT,			-- 운송비
	@P_RENT_COST		INT,			-- 용차비
	@P_TRANS_GB			NVARCHAR(1),	-- 운송구분
	@P_TRANS_SECTION	NVARCHAR(6),	-- 운송구간
	@P_CAR_GB			NVARCHAR(1),	-- 차량구분
	@P_CAR_NO			NVARCHAR(8),	-- 차량번호
	@P_DRIVER_NAME		NVARCHAR(20),	-- 기사명
	@P_DRIVER_VEN_NAME	NVARCHAR(50),	-- 기사회사명
	@P_TRANS_YN			NVARCHAR(1),	-- 배차여부 FNR: F 일반: Y
	@P_EMP_ID			NVARCHAR(20)	-- 아이디
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	 
	DECLARE @RETURN_CODE			INT = 0								-- 리턴코드
	DECLARE @RETURN_MESSAGE			NVARCHAR(20) = '저장되었습니다.'	-- 리턴메시지
	DECLARE @DELIVERY_PRICE_SEQ	    INT		-- 운송비마스터 SEQ

	BEGIN TRAN
	BEGIN TRY 
		BEGIN
			UPDATE PO_SCALE
			   SET TRANS_COST = @P_TRANS_COST,
				   RENT_COST = @P_RENT_COST,
				   CAR_GB = @P_CAR_GB,
				   CAR_NO = @P_CAR_NO,
				   UDATE = GETDATE(),
				   UEMP_ID = @P_EMP_ID
			 WHERE ORD_NO = @P_ORD_NO

			SELECT @DELIVERY_PRICE_SEQ = SEQ 
			  FROM CD_DELIVERY_PRICE
			 WHERE TRANS_GB = @P_TRANS_GB
			   AND TRANS_SECTION = @P_TRANS_SECTION

			IF(LEFT(@P_ORD_NO,1) = '2')
			BEGIN
			UPDATE PO_ORDER_HDR
			   SET DELIVERY_PRICE_SEQ = @DELIVERY_PRICE_SEQ,
			       TRANS_YN = @P_TRANS_YN
			 WHERE ORD_NO = @P_ORD_NO
			END
			ELSE
			BEGIN
			UPDATE PO_PURCHASE_HDR
			   SET DELIVERY_PRICE_SEQ = @DELIVERY_PRICE_SEQ,
			       TRANS_YN = @P_TRANS_YN
			 WHERE ORD_NO = @P_ORD_NO
			END

			IF ISNULL(@P_CAR_NO, '') <> ''
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM PO_CAR_INFO WHERE CAR_NO = @P_CAR_NO)
				BEGIN
					INSERT INTO PO_CAR_INFO(CAR_NO, CAR_GB, DRIVER_NAME, DRIVER_VEN_NAME, IDATE, IEMP_ID)
					VALUES(@P_CAR_NO, @P_CAR_GB, @P_DRIVER_NAME, @P_DRIVER_VEN_NAME, GETDATE(), @P_EMP_ID)
				END
				ELSE 
				BEGIN
					UPDATE PO_CAR_INFO SET 
								DRIVER_NAME = @P_DRIVER_NAME,
								DRIVER_VEN_NAME = @P_DRIVER_VEN_NAME,
								UDATE = GETDATE(),
								UEMP_ID = @P_EMP_ID
					 WHERE CAR_NO = @P_CAR_NO
				END
			END
		END
		
		COMMIT
	END TRY
	BEGIN CATCH		
		IF @@TRANCOUNT > 0
		BEGIN 
			ROLLBACK TRAN
			
			--에러 로그 테이블 저장
			INSERT INTO TBL_ERROR_LOG 
			SELECT ERROR_PROCEDURE()	-- 프로시저명
			, ERROR_MESSAGE()			-- 에러메시지
			, ERROR_LINE()				-- 에러라인
			, GETDATE()	

			SET @RETURN_CODE = -1 -- 저장실패
			SET @RETURN_MESSAGE = DBO.GET_ERR_MSG('-1')
		END
	END CATCH
	
	SELECT @RETURN_CODE AS RETURN_CODE, @RETURN_MESSAGE AS RETURN_MESSAGE
END

GO

