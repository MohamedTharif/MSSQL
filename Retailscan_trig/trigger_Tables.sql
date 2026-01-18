USE [dbadb]
GO

/****** Object:  Table [dbo].[WebVasLoginAudit]    Script Date: 12-01-2026 19:50:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE dbadb.[dbo].[RSLoginAudit](
	[AuditID] [int] IDENTITY(1,1) NOT NULL,
	[LoginName] [nvarchar](100) NULL,
	[IPAddress] [nvarchar](50) NULL,
	[LoginTime] [datetime] NULL,
	[AlertMessage] [nvarchar](4000) NULL,
PRIMARY KEY CLUSTERED 
(
	[AuditID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RSLoginAudit] ADD  DEFAULT (getdate()) FOR [LoginTime]
GO


CREATE TABLE dbadb.dbo.ValidIPAddress
(
    IPAddress NVARCHAR(50) PRIMARY KEY
);

--Temp values
--INSERT INTO dbo.ValidIPAddress (IPAddress)
--VALUES
--('172.31.5.171'),
--('13.234.211.64'),
--('172.31.45.251'),
--('13.203.183.57'),
--('23.226.124.197');