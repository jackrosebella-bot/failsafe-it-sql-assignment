/*
    FailSafe IT – SQL Server database assignment
    Run the whole file in SQL Server LocalDB or SQL Server Management Studio.
    The sample records are fictitious.
*/

IF DB_ID(N'FailSafeIT') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [FailSafeIT]');
END;
GO

USE [FailSafeIT];
GO

/* DDL: core tables */
CREATE TABLE dbo.Customers
(
    CustomerId         int IDENTITY(1,1) NOT NULL,
    OrganizationNumber nvarchar(30) NOT NULL,
    CompanyName        nvarchar(150) NOT NULL,
    Email              nvarchar(254) NOT NULL,
    Phone              nvarchar(30) NOT NULL,

    CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (CustomerId)
);
GO

CREATE TABLE dbo.Consultants
(
    ConsultantId  int IDENTITY(1,1) NOT NULL,
    PersonalNumber nvarchar(30) NOT NULL,
    FullName      nvarchar(120) NOT NULL,
    HourlyRate    decimal(10,2) NOT NULL,
    Specialty     nvarchar(100) NOT NULL,

    CONSTRAINT PK_Consultants PRIMARY KEY CLUSTERED (ConsultantId),
    CONSTRAINT UQ_Consultants_PersonalNumber UNIQUE (PersonalNumber),
    CONSTRAINT CK_Consultants_HourlyRate CHECK (HourlyRate >= 0)
);
GO

CREATE TABLE dbo.Assignments
(
    AssignmentId   int IDENTITY(1,1) NOT NULL,
    CustomerId     int NOT NULL,
    ConsultantId   int NOT NULL,
    StartDate      date NOT NULL,
    EndDate        date NOT NULL,
    RoleDescription nvarchar(250) NOT NULL,

    CONSTRAINT PK_Assignments PRIMARY KEY CLUSTERED (AssignmentId),
    CONSTRAINT FK_Assignments_Customers
        FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(CustomerId),
    CONSTRAINT FK_Assignments_Consultants
        FOREIGN KEY (ConsultantId) REFERENCES dbo.Consultants(ConsultantId),
    CONSTRAINT CK_Assignments_DateRange CHECK (EndDate >= StartDate)
);
GO

/*
    Ops: a unique nonclustered index speeds up exact searches by organization
    number and also prevents duplicate organization numbers.
*/
CREATE UNIQUE NONCLUSTERED INDEX UX_Customers_OrganizationNumber
    ON dbo.Customers(OrganizationNumber);
GO

/* Supporting indexes for the foreign-key joins used by assignment queries. */
CREATE NONCLUSTERED INDEX IX_Assignments_CustomerId
    ON dbo.Assignments(CustomerId);

CREATE NONCLUSTERED INDEX IX_Assignments_ConsultantId
    ON dbo.Assignments(ConsultantId);
GO

/* DML: fictitious sample customers. */
INSERT INTO dbo.Customers (OrganizationNumber, CompanyName, Email, Phone)
VALUES
    (N'ORG-TEST-001', N'Nordic Shield AB', N'kontakt@nordicshield.example', N'TEST-TELEFON-001'),
    (N'ORG-TEST-002', N'Green Transit AB', N'info@greentransit.example', N'TEST-TELEFON-002'),
    (N'ORG-TEST-003', N'Blue Harbor AB', N'hello@blueharbor.example', N'TEST-TELEFON-003');

/* Fictitious person-number placeholders; identifiers are stored as text. */
INSERT INTO dbo.Consultants (PersonalNumber, FullName, HourlyRate, Specialty)
VALUES
    (N'PERSON-TEST-001', N'Alex Andersson', 1700.00, N'Cybersecurity'),
    (N'PERSON-TEST-002', N'Samira Lind', 1250.00, N'DevOps'),
    (N'PERSON-TEST-003', N'Robin Ek', 1100.00, N'C# Developer');

/*
    Five assignments. An assignment is active today when today's date is
    between StartDate and EndDate, including both boundary dates.
    Customer 3 intentionally has no assignments so Query E can delete it
    without deleting assignment history or violating a foreign key.
*/
INSERT INTO dbo.Assignments
    (CustomerId, ConsultantId, StartDate, EndDate, RoleDescription)
VALUES
    (1, 1, DATEADD(day, -30, CONVERT(date, GETDATE())), DATEADD(day, 30, CONVERT(date, GETDATE())), N'Säkerhetsgranskning av API-miljö'),
    (1, 2, DATEADD(day, -20, CONVERT(date, GETDATE())), DATEADD(day, 20, CONVERT(date, GETDATE())), N'Automatisering av säker CI/CD-process'),
    (1, 3, DATEADD(day, -120, CONVERT(date, GETDATE())), DATEADD(day, -60, CONVERT(date, GETDATE())), N'Utveckling av intern C#-tjänst'),
    (2, 1, DATEADD(day, -10, CONVERT(date, GETDATE())), DATEADD(day, 50, CONVERT(date, GETDATE())), N'Granskning av molnkonfiguration'),
    (2, 2, DATEADD(day, -90, CONVERT(date, GETDATE())), DATEADD(day, -20, CONVERT(date, GETDATE())), N'Förbättring av driftsättning');
GO

/* Query A: consultants whose hourly rate is greater than 1,200 kr. */
SELECT FullName, HourlyRate
FROM dbo.Consultants
WHERE HourlyRate > 1200
ORDER BY HourlyRate DESC;
GO

/* Query B: every assignment with the customer and consultant names. */
SELECT
    c.CompanyName,
    co.FullName AS ConsultantName,
    a.StartDate,
    a.EndDate,
    a.RoleDescription
FROM dbo.Assignments AS a
INNER JOIN dbo.Customers AS c
    ON c.CustomerId = a.CustomerId
INNER JOIN dbo.Consultants AS co
    ON co.ConsultantId = a.ConsultantId
ORDER BY a.AssignmentId;
GO

/*
    Query C: count assignments currently in progress.
    LEFT JOIN keeps customers with zero active assignments in the result.
*/
SELECT
    c.CustomerId,
    c.CompanyName,
    COUNT(a.AssignmentId) AS ActiveAssignmentCount
FROM dbo.Customers AS c
LEFT JOIN dbo.Assignments AS a
    ON a.CustomerId = c.CustomerId
    AND a.StartDate <= CONVERT(date, GETDATE())
    AND a.EndDate >= CONVERT(date, GETDATE())
GROUP BY c.CustomerId, c.CompanyName
ORDER BY c.CompanyName;
GO

/* Query D: update one consultant's hourly rate, then display the new value. */
UPDATE dbo.Consultants
SET HourlyRate = 1325.00
WHERE ConsultantId = 3;

SELECT ConsultantId, FullName, HourlyRate
FROM dbo.Consultants
WHERE ConsultantId = 3;
GO

/*
    Query E: delete customer 3 only if it has no active assignments.
    In this sample customer 3 has no assignment rows at all. The foreign key
    also protects any customer that still has historical/future assignments.
*/
DELETE c
FROM dbo.Customers AS c
WHERE c.CustomerId = 3
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Assignments AS a
      WHERE a.CustomerId = c.CustomerId
        AND a.StartDate <= CONVERT(date, GETDATE())
        AND a.EndDate >= CONVERT(date, GETDATE())
  );

/* Verify that customer 3 was removed. */
SELECT CustomerId, OrganizationNumber, CompanyName
FROM dbo.Customers
ORDER BY CustomerId;
GO
