CREATE TABLE [dbo].[TBL_ROLE_MENU] (
    [ROLE_ID]   NVARCHAR (6)   NOT NULL,
    [MENU_CODE] NVARCHAR (100) NOT NULL,
    [IDATE]     DATETIME       NULL,
    [IEMP_ID]   NVARCHAR (20)  NULL,
    CONSTRAINT [PK_TBL_ROLE_MENU] PRIMARY KEY CLUSTERED ([ROLE_ID] ASC, [MENU_CODE] ASC)
);


GO

EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'등록일자', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TBL_ROLE_MENU', @level2type = N'COLUMN', @level2name = N'IDATE';


GO

EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'등록아이디', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TBL_ROLE_MENU', @level2type = N'COLUMN', @level2name = N'IEMP_ID';


GO

EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'메뉴코드', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TBL_ROLE_MENU', @level2type = N'COLUMN', @level2name = N'MENU_CODE';


GO

EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'권한그룹코드', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TBL_ROLE_MENU', @level2type = N'COLUMN', @level2name = N'ROLE_ID';


GO

EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'권한 별 기본메뉴', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TBL_ROLE_MENU';


GO
