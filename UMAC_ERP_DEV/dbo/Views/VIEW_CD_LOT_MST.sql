





/*
-- 생성자 :	최수민
-- 등록일 :	2024.10.02
-- 설 명  : CD_LOT_MST와 CD_LOT_MST에 없는 재고실사(IV_LOT_STAT) LOT 데이터
-- 수정자 :
-- 수정일 :
-- 수정내용 :

*/
CREATE VIEW [dbo].[VIEW_CD_LOT_MST]
AS
	SELECT *
	FROM (VALUES
		('20240806', '8801047302674', '20240806-SB-DW-210016', '20260205', '2024-10-02 20:40:13.150'),
		('20250418', '8807596110005', '20250418-CO-UM-210002', '20260217', '2024-10-02 20:40:13.150'),
		--('20240824', '8807596210002', '20240824-CA-OEM-210011', '20260223', '2024-10-02 20:40:13.150'),
		('20240224', '8807596212006', '20240224-CA-UM-210137', '20260223', '2024-10-02 20:40:13.150'),
		('20240919', '8807596340006', '20240919-SB-KN-210136', '20260318', '2024-10-02 20:40:13.150'),
		('20250131', '8807596340006', '20250131-SB-KN-210136', '20260730', '2024-10-02 20:40:13.150')
	) AS TempLotData (PROD_DT, SCAN_CODE, LOT_NO, EXPIRATION_DT, IDATE)

	UNION ALL

	SELECT PROD_DT, SCAN_CODE, LOT_NO, EXPIRATION_DT, MAX(IDATE) AS IDATE
	  FROM CD_LOT_MST WITH(NOLOCK)
	 GROUP BY PROD_DT, SCAN_CODE, LOT_NO, EXPIRATION_DT

GO

