/*

Un gest capturat de catre Kinect reprezinta o multime de posturi ale corpului utilizatorului, unde fiecare postura este reprezentata prin 20 de puncte (joint-uri plasate in pozitii fixe pe corp).
Deci, un gest poate fi scris astfel:

G = {(P1,t1), (P2,t2), .... (Pn,tn)} unde n este numarul de posturi, iar perechea (Pi,ti) reprezinta postura Pi capturata de Kinect la momentul de timp ti.
Mai departe, o postura Pi este alcatuita din cele 20 de puncte 3-D, astfel:

Pi = {pi1,pi2,...pij,...pi20}, unde pij reprezinta punctul (sau joint-ul de index j (=1..20) aferent posturii i). Fiecare punct pij are 3 coordonate, exprimate in metri, 
reprezentand pozitia punctului respectiv fata de locatia Kinect-ului (care este 0,0,0). 
Deci: pij = (xij, yij, zij), fiecare coordonata in metri.

Deasemenea, un gest G mai poate avea asociate informatii suplimentare, cum ar fi:
- Id-ul gestului (de ex., IDG_536), un id care identifica unic un anumit gest inregistrat
- Id-ul tipului gestului (IDT_373) care identifica unic un anumit tip de gest. Putem aveam mai multe gesturi in baza de date care sunt de tipul
IDT_373. De exemplu,  IDG_536,  IDG_537,  IDG_538 si  IDG_539 pot fi exemple diferite de gesturi avand acelasi tip (IDT_373)
- O descriere a tipului gestului (de ex. "ridica bratele in sus"), cate o descriere unica pentru fiecare IDT
- O descriere mai larga asociata fiecarui tip de gest IDT (de ex., "utilizatorul ridica bratele in sus pentru 2 secunde, apoi le coboara...")
- Id-ul unei comenzi asociata gestului (IDC_734)
- O descriere a comenzii pentru fiecare IDC (de ex., "porneste lumina")

Alte informatii pe care le putem memora:
- Id-ul utilizatorului (de ex., IDU_123) de la care a fost colectat gestul
- Informatii despre utilizator (Gen, Varsta, Experienta, etc.)

Acestea sunt datele cu care lucram.

*/

-- Creare tabel joint-uri[tipuri]

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  where TABLE_NAME = 'Joint' AND TABLE_SCHEMA = 'dbo')
	drop table dbo.Joint;

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].Joint(
	[JOINT_ID] [int] IDENTITY(1,1) NOT NULL,
	[JOINT_CODE] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_Joint] PRIMARY KEY CLUSTERED 
(
	[JOINT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

-- Populare tabel joint-uri
USE [GestureDb]
GO

INSERT INTO [dbo].[Joint]
           ([JOINT_Code])
     VALUES
		   ('SpineBase'),
           ('SpineMid'),
		   ('Neck'),
		   ('Head'),
		   ('ShoulderLeft'),
		   ('ElbowLeft'),
		   ('WristLeft'),
		   ('HandLeft'),
		   ('ShoulderRight'),
		   ('ElbowRight'),
		   ('WristRight'),
		   ('HandRight'),
		   ('HipLeft'),
		   ('KneeLeft'),
		   ('AnkleLeft'),
		   ('FootLeft'),
		   ('HipRight'),
		   ('KneeRight'),
		   ('AnkleRight'),
		   ('FootRight'),
		   ('SpineShoulder'),
		   ('HandTipLeft'),
		   ('ThumbLeft'),
		   ('HandTipRight'),
		   ('ThumbRight')
GO


-- Creare tabel comenzi

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  where TABLE_NAME = 'Command' AND TABLE_SCHEMA = 'dbo')
	drop table dbo.Command;

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].Command(
	[COMM_ID] [int] IDENTITY(1,1) NOT NULL,
	[COMM_CODE] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_Command] PRIMARY KEY CLUSTERED 
(
	[COMM_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

-- Creare tabel user

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  where TABLE_NAME = 'Person' AND TABLE_SCHEMA = 'dbo')
	drop table dbo.Person;

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].Person(
	[PERS_ID] [int] IDENTITY(1,1) NOT NULL,
	[PERS_FIRSTNAME] [nvarchar](200) NOT NULL,
	[PERS_LASTNAME] [nvarchar](200) NOT NULL,
	[PERS_EMAIL] [nvarchar](200) NULL,
	[PERS_AGE] [int] NULL,
	[PERS_BIRTHDATE] [datetime] NOT NULL,
	[PERS_CREATIONDATE] [datetime] NOT NULL DEFAULT GETDATE(),
	[PERS_GENRE] [nvarchar](200) NOT NULL,
	[PERS_EXPERIENCE] [int] NOT NULL,
	[PERS_USERNAME] [nvarchar](200) NOT NULL
 CONSTRAINT [PK_Person] PRIMARY KEY CLUSTERED 
(
	[PERS_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

-- Creare trigger pentru insert varsta
IF EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[PersonInsert]'))
DROP TRIGGER [dbo].[PersonInsert]
GO

CREATE TRIGGER [dbo].[PersonInsert]
ON [dbo].[Person]
AFTER INSERT, UPDATE

AS

DECLARE @BirthDate datetime;
DECLARE @TargetDate datetime;
DECLARE @Action as char(1);
DECLARE @IdToUpdate as int;
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 --
     -- Check if this is an INSERT, UPDATE or DELETE Action.
     -- 
    SET @Action = (CASE WHEN EXISTS(SELECT * FROM INSERTED)
                         AND EXISTS(SELECT * FROM DELETED)
                        THEN 'U'  -- Set Action to Updated.
                        WHEN EXISTS(SELECT * FROM INSERTED)
                        THEN 'I'  -- Set Action to Insert.
                        WHEN EXISTS(SELECT * FROM DELETED)
                        THEN 'D'  -- Set Action to Deleted.
                        ELSE NULL -- Skip. It may have been a "failed delete".   
                    END)

     -- Insert statements for trigger here
	 -- only 2 virtual tables: inserted for insert and update and deleted for delete
	 IF @action = 'I'
	 BEGIN
		SELECT @BirthDate = PERS_BIRTHDATE FROM inserted;
		SELECT @IdToUpdate = PERS_Id FROM inserted;
	 END
	 ELSE
	 BEGIN
		SELECT @BirthDate = PERS_BIRTHDATE FROM inserted;
		SELECT @IdToUpdate = PERS_Id FROM inserted;
	 END


	set @TargetDate = GETDATE();

	UPDATE Person SET PERS_AGE = (SELECT FLOOR(DATEDIFF(DAY, @BirthDate, @TargetDate) / 365.25))  WHERE PERS_Id = @IdToUpdate;

END
GO


-- Creare tabel gesturi
-- coloana code va fi indexata deoarece din c# se va face cautare dupa cod si prin urmare, cu index pe acea coloana, search-ul va fi mai rapid
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  where TABLE_NAME = 'Gesture' AND TABLE_SCHEMA = 'dbo')
	drop table dbo.Gesture;

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].Gesture(
	[GEST_ID] [int] IDENTITY(1,1) NOT NULL,
	[GEST_CODE] [nvarchar](200) NOT NULL,
	[GEST_DESCRIPTION] [nvarchar](200) NOT NULL,
	[GEST_PERS_ID] [int] NOT NULL FOREIGN KEY REFERENCES Person(PERS_ID)
 CONSTRAINT [PK_Gesture] PRIMARY KEY CLUSTERED 
(
	[GEST_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
,
 CONSTRAINT [UQ_Code] UNIQUE NONCLUSTERED
 (
	[GEST_ID],[GEST_CODE]
 )
) ON [PRIMARY]

GO

--alter table Gesture add [GEST_PERS_ID] [int] NOT NULL FOREIGN KEY REFERENCES Person(PERS_ID)
-- creare index pentru coloana gest_Code

CREATE INDEX gest_code_index ON Gesture(GEST_CODE);

-- creare constrangere pentru cheie unica

-- Creare tabel posturi
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  where TABLE_NAME = 'Posture' AND TABLE_SCHEMA = 'dbo')
	drop table dbo.Posture;

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].Posture(
	[POST_ID] [int] IDENTITY(1,1) NOT NULL,
	[POST_GEST_ID] [int] NOT NULL FOREIGN KEY REFERENCES Gesture(GEST_ID),
 CONSTRAINT [PK_Posure] PRIMARY KEY CLUSTERED 
(
	[POST_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


-- Creare tabel puncte
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  where TABLE_NAME = 'Point' AND TABLE_SCHEMA = 'dbo')
	drop table dbo.Point;

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].Point(
	[POINT_ID] [int] IDENTITY(1,1) NOT NULL,
	[POINT_X] [float] NOT NULL,
	[POINT_Y] [float] NOT NULL,
	[POINT_Z] [float] NOT NULL,
	[POINT_POST_ID] [int] NOT NULL FOREIGN KEY REFERENCES Posture(POST_ID),
	[POINT_JOINT_ID] int NOT NULL FOREIGN KEY REFERENCES Joint(JOINT_ID),	
	[POINT_COMM_ID] int NOT NULL FOREIGN KEY REFERENCES Command(COMM_ID)
 CONSTRAINT [PK_Point] PRIMARY KEY CLUSTERED 
(
	[POINT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO