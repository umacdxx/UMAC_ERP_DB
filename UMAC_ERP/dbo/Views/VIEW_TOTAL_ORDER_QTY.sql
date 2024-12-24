

/*
-- 생성자 :	최수민
-- 등록일 :	2024.07.08
-- 설 명  : 상품별 총 주문 수량
			박스의 경우 단품의 재고로 환산
-- 수정자 :
-- 수정일 :
-- 수정내용 :

*/
CREATE VIEW [dbo].[VIEW_TOTAL_ORDER_QTY]
AS
	SELECT 
		ISNULL(BOX.ITM_CODE, CMN.ITM_CODE) AS ITM_CODE,
		SUM(IIF(CMN.ITM_FORM = '2', ODT.ORD_QTY * ISNULL(BOX.IPSU_QTY, 0), ODT.ORD_QTY)) AS TOTAL_ORD_QTY
	FROM 
		dbo.PO_ORDER_HDR AS ODH
		INNER JOIN dbo.PO_ORDER_DTL AS ODT ON ODH.ORD_NO = ODT.ORD_NO 
		INNER JOIN dbo.CD_PRODUCT_CMN AS CMN ON ODT.SCAN_CODE = CMN.SCAN_CODE 
		LEFT OUTER JOIN dbo.CD_BOX_MST AS BOX ON CMN.ITM_CODE = IIF(CMN.ITM_FORM = '2', BOX.BOX_CODE, BOX.ITM_CODE)
	WHERE 
		ODH.ORD_STAT IN (SELECT CD_ID FROM dbo.TBL_COMM_CD_MST WHERE CD_CL = 'AVL_INV_STAT')
	GROUP BY 
		ISNULL(BOX.ITM_CODE, CMN.ITM_CODE);

GO

