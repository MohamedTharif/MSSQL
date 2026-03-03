USE DBADB;
GO

-- 1️⃣ Tracker Table
IF OBJECT_ID('dbo.ErrorLogUploadTracker') IS NULL
BEGIN
    CREATE TABLE dbo.ErrorLogUploadTracker
    (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        LastUploadedDateTime DATETIME NOT NULL,
        ModifiedDate DATETIME DEFAULT GETDATE()
    );

    INSERT INTO dbo.ErrorLogUploadTracker (LastUploadedDateTime)
    VALUES ('1900-01-01');
END
GO;

---

IF OBJECT_ID('dbo.ErrorLogMailAudit') IS NOT NULL
DROP TABLE dbo.ErrorLogMailAudit;
GO

CREATE TABLE dbo.ErrorLogMailAudit
(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutionID BIGINT,
    SerialNumber INT,
    FromDateTime DATETIME,
    ToDateTime DATETIME,
    LogCount INT,
    EstimatedSizeMB DECIMAL(10,2),
    MailSentDate DATETIME DEFAULT GETDATE(),
    MailStatus VARCHAR(50),
    ErrorMessage VARCHAR(MAX)
);
GO

---
IF OBJECT_ID('dbo.ErrorLogExecutionTracker') IS NULL
BEGIN
    CREATE TABLE dbo.ErrorLogExecutionTracker
    (
        ExecutionID BIGINT IDENTITY(1,1) PRIMARY KEY,
        ExecutionStartTime DATETIME DEFAULT GETDATE()
    );
END
GO

---
IF OBJECT_ID('dbo.ErrorLogStaging') IS NOT NULL
DROP TABLE dbo.ErrorLogStaging;
GO

CREATE TABLE dbo.ErrorLogStaging
(
    StagingID INT IDENTITY(1,1),
    ExecutionID BIGINT,
    RowNum INT,
    LogDate DATETIME,
    ProcessInfo VARCHAR(50),
    Text NVARCHAR(MAX)
);
GO




--Truncate table dbo.ErrorLogStaging
--Truncate table dbo.ErrorLogMailAudit
--Truncate table dbo.ErrorLogUploadTracker
--Truncate table dbo.ErrorLogExecutionTracker