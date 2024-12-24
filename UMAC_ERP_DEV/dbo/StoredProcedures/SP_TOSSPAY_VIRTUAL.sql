

/*
-- 생성자 :	이동호
-- 등록일 :	2024.07.24
-- 수정자 : -
-- 수정일 : - 
-- 설 명 : 
-- 실행문 : 가상계좌 입금시 입금 기록 관리
*/
CREATE PROCEDURE [dbo].[SP_TOSSPAY_VIRTUAL]
	@P_PAYMENTKEY NVARCHAR(200),		
	@P_ORDERID NVARCHAR(64),
	@P_STATUS NVARCHAR(15),
	@P_APPROVEDAT NVARCHAR(35),
	@P_METHOD NVARCHAR(25),
	@P_TOTALAMOUNT INT,
	@P_ACCOUNTNUMBER NVARCHAR(20),
	@P_ACCOUNTTYPE NVARCHAR(25),
	@P_BANKCODE NVARCHAR(3),
	@P_REFUNDSTATUS NVARCHAR(15)	
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @RETURN_CODE INT = 0				-- 리턴코드
	DECLARE @RETURN_MESSAGE NVARCHAR(10) = ''	-- 리턴메시지
	

	BEGIN TRAN
	BEGIN TRY 	
		
		--가상계좌 훅에서 중복으로 보낼 경우를 대비하여 기존 등로된 정보가 있으면 삭제 후 다시 등록
		DELETE TBL_TOSSPAY_VIRTUAL WHERE ORDERID = @P_ORDERID AND [STATUS] = @P_STATUS
		
		INSERT INTO TBL_TOSSPAY_VIRTUAL (PAYMENTKEY, ORDERID, [STATUS], APPROVEDAT, METHOD, TOTALAMOUNT, ACCOUNTNUMBER, ACCOUNTTYPE, BANKCODE, REFUNDSTATUS) 
			SELECT @P_PAYMENTKEY, @P_ORDERID, @P_STATUS, @P_APPROVEDAT, @P_METHOD, @P_TOTALAMOUNT, @P_ACCOUNTNUMBER, @P_ACCOUNTTYPE, @P_BANKCODE, @P_REFUNDSTATUS
	
			
		COMMIT;

	END TRY
	BEGIN CATCH	
				
		IF @@TRANCOUNT > 0
		BEGIN 		  			
			--에러 로그 테이블 저장
			INSERT INTO TBL_ERROR_LOG 
			SELECT ERROR_PROCEDURE()	-- 프로시저명
			, ERROR_MESSAGE()			-- 에러메시지
			, ERROR_LINE()				-- 에러라인
			, GETDATE()	

			SET @RETURN_CODE = -1
			SET @RETURN_MESSAGE = ERROR_MESSAGE() 

		END 
		
	END CATCH

	SELECT @RETURN_CODE AS RETURN_CODE, @RETURN_MESSAGE AS RETURN_MESSAGE
END

GO

