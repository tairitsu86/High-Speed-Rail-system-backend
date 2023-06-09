USE [master]
GO
/****** Object:  Database [HighSpeedRail]    Script Date: 2023/5/2 下午 03:47:40 ******/
CREATE DATABASE [HighSpeedRail]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'HighSpeedRail_mdf', FILENAME = N'C:\HSRData\HighSpeedRail_mdf.mdf' , SIZE = 20480KB , MAXSIZE = 1048576KB , FILEGROWTH = 100%), 
 FILEGROUP [HSRBasicData] 
( NAME = N'HighSpeedRail_ndf', FILENAME = N'C:\HSRData\HighSpeedRail_ndf.ndf' , SIZE = 20480KB , MAXSIZE = 1048576KB , FILEGROWTH = 100%)
 LOG ON 
( NAME = N'HighSpeedRail_ldf', FILENAME = N'C:\HSRData\HighSpeedRail_ldf.ldf' , SIZE = 81920KB , MAXSIZE = 1048576KB , FILEGROWTH = 100%)
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [HighSpeedRail] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [HighSpeedRail].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [HighSpeedRail] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [HighSpeedRail] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [HighSpeedRail] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [HighSpeedRail] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [HighSpeedRail] SET ARITHABORT OFF 
GO
ALTER DATABASE [HighSpeedRail] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [HighSpeedRail] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [HighSpeedRail] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [HighSpeedRail] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [HighSpeedRail] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [HighSpeedRail] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [HighSpeedRail] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [HighSpeedRail] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [HighSpeedRail] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [HighSpeedRail] SET  ENABLE_BROKER 
GO
ALTER DATABASE [HighSpeedRail] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [HighSpeedRail] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [HighSpeedRail] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [HighSpeedRail] SET ALLOW_SNAPSHOT_ISOLATION ON 
GO
ALTER DATABASE [HighSpeedRail] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [HighSpeedRail] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [HighSpeedRail] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [HighSpeedRail] SET RECOVERY FULL 
GO
ALTER DATABASE [HighSpeedRail] SET  MULTI_USER 
GO
ALTER DATABASE [HighSpeedRail] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [HighSpeedRail] SET DB_CHAINING OFF 
GO
ALTER DATABASE [HighSpeedRail] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [HighSpeedRail] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [HighSpeedRail] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'HighSpeedRail', N'ON'
GO
ALTER DATABASE [HighSpeedRail] SET QUERY_STORE = ON
GO
ALTER DATABASE [HighSpeedRail] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [HighSpeedRail]
GO
/****** Object:  User [HRSConnect]    Script Date: 2023/5/2 下午 03:47:40 ******/
CREATE USER [HRSConnect] FOR LOGIN [HRSConnect] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  UserDefinedFunction [dbo].[CheckHSRWork]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CheckHSRWork](@HSR NVARCHAR(20),@Date DATETIME) RETURNS INT
AS
  BEGIN
	DECLARE @Return INT
	SELECT @Return = POWER(2,DATEPART(DW,@Date)-1) 
	SELECT @Return = @Return&[dbo].[HSR].HSR_depDayBin
	FROM [dbo].[HSR]
	WHERE @HSR = [dbo].[HSR].HSR_id
	RETURN @Return
  END
GO
/****** Object:  UserDefinedFunction [dbo].[GetNewRecordID]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetNewRecordID]() RETURNS NVARCHAR(20)
AS
	BEGIN
		DECLARE @i INT
		DECLARE @Datepart NVARCHAR(20) = CONCAT(RIGHT('0' + cast(DATEPART(YEAR,GETDATE())%10 AS VARCHAR(1)), 1),RIGHT('000' + cast(DATEPART(DAYOFYEAR,GETDATE()) AS VARCHAR(3)), 3))
		SELECT @i = COUNT(Record_id) FROM [dbo].[Record] WHERE Record_id LIKE CONCAT(@Datepart,'___')		
		DECLARE @RecordID NVARCHAR(20) = CONCAT(@Datepart,RIGHT('0000' + cast(@i AS VARCHAR(4)), 4))
		WHILE(EXISTS (SELECT Record_id FROM [dbo].[Record] WHERE Record_id = @RecordID))
			BEGIN
				SET @i = @i+1
				SET @RecordID = CONCAT(@Datepart,RIGHT('0000' + cast(@i AS VARCHAR(4)), 4))
			END
		RETURN @RecordID
	END
GO
/****** Object:  UserDefinedFunction [dbo].[SeatCount]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[SeatCount] (@PreferData NVARCHAR(10),@Type NVARCHAR(10),@DepartDate DATETIME,@HSR NVARCHAR(10),@DepartTime TIME,@ArriveTime TIME) RETURNS INT
AS
	BEGIN
		DECLARE @Prefer CHAR
		DECLARE @CarType CHAR
		DECLARE @Return INT
		SELECT @CarType = [Value] FROM [dbo].[DataTransform] WHERE [StoredProcedure] = 'GetTrains' AND [Key] = @Type
		SELECT @Prefer = [Value] FROM [dbo].[DataTransform] WHERE [StoredProcedure] = 'GetTrains' AND [Key] = @PreferData
		SELECT @Return = COUNT(*) FROM
			(
				SELECT Seat_id FROM [dbo].[Seat] WHERE Prefer LIKE @Prefer AND CarType = @CarType
				EXCEPT
				SELECT Seat_id FROM [dbo].[RecordDetail]
				JOIN [dbo].[Timetable] ON [dbo].[RecordDetail].Timetable_id = [dbo].[Timetable].Timetable_id
				WHERE [dbo].[RecordDetail].Reservation_time >= @DepartDate AND [dbo].[RecordDetail].Reservation_time<DATEADD(DAY,1,@DepartDate) AND[dbo].[Timetable].HSR_id = @HSR 
					AND ([dbo].[Timetable].Arrive_time > @DepartTime OR [dbo].[Timetable].Depart_time < @ArriveTime)
			) AS Seats
		RETURN @Return
	END
GO
/****** Object:  UserDefinedFunction [dbo].[Seats]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Seats] (@PreferData NVARCHAR(10),@Type NVARCHAR(10),@DepartDate DATETIME,@HSR NVARCHAR(10),@DepartTime TIME,@ArriveTime TIME) 
RETURNS @Return TABLE(
			Seat_id NVARCHAR(10)
		)
AS
	BEGIN
		DECLARE @Prefer CHAR
		DECLARE @CarType CHAR
		SELECT @CarType = [Value] FROM [dbo].[DataTransform] WHERE [StoredProcedure] = 'GetTrains' AND [Key] = @Type
		SELECT @Prefer = [Value] FROM [dbo].[DataTransform] WHERE [StoredProcedure] = 'GetTrains' AND [Key] = @PreferData
		INSERT INTO @Return(Seat_id) 
		(SELECT Seat_id FROM [dbo].[Seat] WHERE Prefer LIKE @Prefer AND CarType = @CarType
		EXCEPT
		SELECT Seat_id FROM [dbo].[RecordDetail]
			JOIN [dbo].[Timetable] ON [dbo].[RecordDetail].Timetable_id = [dbo].[Timetable].Timetable_id
		WHERE [dbo].[RecordDetail].Reservation_time >= @DepartDate AND [dbo].[RecordDetail].Reservation_time<DATEADD(DAY,1,@DepartDate) AND[dbo].[Timetable].HSR_id = @HSR 
			AND ([dbo].[Timetable].Arrive_time > @DepartTime OR [dbo].[Timetable].Depart_time < @ArriveTime))
		RETURN
	END
GO
/****** Object:  UserDefinedFunction [dbo].[StationsBy]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[StationsBy] (@HSR NVARCHAR(10)) RETURNS NVARCHAR(MAX)
AS
	BEGIN
		DECLARE @Return NVARCHAR(MAX)
		SELECT @Return = STRING_AGG(ISNULL(Depart_time, ''),',') WITHIN GROUP ( ORDER BY CONVERT(INT,SUBSTRING(Station_id,2,2)) ASC)
		FROM [dbo].[Station]
		LEFT JOIN (
			SELECT DISTINCT SubQuery.Depart_station,SubQuery.Depart_time
			FROM(
				SELECT DISTINCT Depart_station, Depart_time FROM [dbo].[Timetable] AS SubTimetable
				WHERE SubTimetable.HSR_id = @HSR
				UNION
				SELECT DISTINCT Arrive_station, Arrive_time FROM [dbo].[Timetable] AS SubTimetable 
				WHERE SubTimetable.HSR_id = @HSR) AS SubQuery
			)AS TimeQuery 
		ON [dbo].[Station].Station_id = TimeQuery.Depart_station
		RETURN @Return
	END
GO
/****** Object:  Table [dbo].[ConnectMessageRecord]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConnectMessageRecord](
	[InsertTime] [datetime2](7) NULL,
	[RequestType] [nvarchar](max) NULL,
	[Request] [nvarchar](max) NULL,
	[Response] [nvarchar](max) NULL,
	[ClientIP] [nvarchar](30) NULL
) ON [HSRBasicData] TEXTIMAGE_ON [HSRBasicData]
GO
/****** Object:  Table [dbo].[DataTransform]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DataTransform](
	[StoredProcedure] [nvarchar](30) NOT NULL,
	[Key] [nvarchar](100) NOT NULL,
	[Value] [nvarchar](100) NULL,
 CONSTRAINT [Table_Key_PK] PRIMARY KEY CLUSTERED 
(
	[StoredProcedure] ASC,
	[Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HSR]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HSR](
	[HSR_id] [nvarchar](20) NOT NULL,
	[HSR_depDay] [nvarchar](10) NULL,
	[HSR_depDayBin] [int] NULL,
	[HSR_directionNorth] [bit] NULL,
 CONSTRAINT [HSRPK] PRIMARY KEY CLUSTERED 
(
	[HSR_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [HSRBasicData]
) ON [HSRBasicData]
GO
/****** Object:  Table [dbo].[Member]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Member](
	[Member_id] [nvarchar](20) NOT NULL,
	[Member_name] [nvarchar](10) NULL,
	[Member_point] [int] NULL,
	[Member_gender] [bit] NULL,
	[Member_address] [nvarchar](40) NULL,
	[Member_password] [nvarchar](40) NULL,
	[Passenger_id] [nvarchar](20) NULL,
 CONSTRAINT [MemberPK] PRIMARY KEY CLUSTERED 
(
	[Member_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [HSRBasicData]
) ON [HSRBasicData]
GO
/****** Object:  Table [dbo].[Passenger]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Passenger](
	[Passenger_id] [nvarchar](20) NOT NULL,
	[Passenger_email] [nvarchar](40) NOT NULL,
	[Passenger_phone] [nvarchar](20) NOT NULL,
 CONSTRAINT [PassengerPK] PRIMARY KEY CLUSTERED 
(
	[Passenger_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [HSRBasicData]
) ON [HSRBasicData]
GO
/****** Object:  Table [dbo].[Record]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Record](
	[Record_id] [nvarchar](60) NOT NULL,
	[Passenger_id] [nvarchar](20) NOT NULL,
	[TicketCount] [int] NOT NULL,
	[Pay] [bit] NULL,
 CONSTRAINT [RecordPK] PRIMARY KEY CLUSTERED 
(
	[Record_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [HSRBasicData]
) ON [HSRBasicData]
GO
/****** Object:  Table [dbo].[RecordDetail]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RecordDetail](
	[Record_id] [nvarchar](60) NOT NULL,
	[Timetable_id] [nvarchar](20) NOT NULL,
	[Seat_id] [nvarchar](20) NOT NULL,
	[Reservation_time] [datetime2](7) NOT NULL,
	[TicketTypeID] [int] NOT NULL,
	[USE] [bit] NULL,
	[Take] [bit] NULL
) ON [HSRBasicData]
GO
/****** Object:  Table [dbo].[Seat]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Seat](
	[Seat_id] [nvarchar](20) NOT NULL,
	[Seat_cabin] [nvarchar](10) NULL,
	[Seat_position] [nvarchar](10) NULL,
	[Prefer] [char](1) NULL,
	[CarType] [char](1) NULL,
 CONSTRAINT [SeatPK] PRIMARY KEY CLUSTERED 
(
	[Seat_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [HSRBasicData]
) ON [HSRBasicData]
GO
/****** Object:  Table [dbo].[Station]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Station](
	[Station_id] [nvarchar](20) NOT NULL,
	[Station_name] [nvarchar](10) NULL,
 CONSTRAINT [StationPK] PRIMARY KEY CLUSTERED 
(
	[Station_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [HSRBasicData]
) ON [HSRBasicData]
GO
/****** Object:  Table [dbo].[TicketPrice]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TicketPrice](
	[Station1] [nvarchar](20) NULL,
	[Station2] [nvarchar](20) NULL,
	[Ticket_type] [nvarchar](50) NULL,
	[Ticket_typeid] [tinyint] NULL,
	[Travel_cost] [money] NULL,
	[CarType] [char](1) NULL
) ON [HSRBasicData]
GO
/****** Object:  Table [dbo].[Timetable]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Timetable](
	[Timetable_id] [nvarchar](20) NOT NULL,
	[HSR_id] [nvarchar](20) NULL,
	[Depart_station] [nvarchar](20) NULL,
	[Depart_time] [time](0) NULL,
	[Arrive_station] [nvarchar](20) NULL,
	[Arrive_time] [time](0) NULL,
 CONSTRAINT [TimetablePK] PRIMARY KEY CLUSTERED 
(
	[Timetable_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [HSRBasicData]
) ON [HSRBasicData]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [NCL_Timetable]    Script Date: 2023/5/2 下午 03:47:40 ******/
CREATE NONCLUSTERED INDEX [NCL_Timetable] ON [dbo].[Timetable]
(
	[HSR_id] ASC,
	[Depart_station] ASC,
	[Depart_time] ASC,
	[Arrive_station] ASC,
	[Arrive_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ConnectMessageRecord] ADD  CONSTRAINT [InsertTimeDefault]  DEFAULT (sysdatetime()) FOR [InsertTime]
GO
ALTER TABLE [dbo].[Record] ADD  CONSTRAINT [PayDEFAULT]  DEFAULT ((0)) FOR [Pay]
GO
ALTER TABLE [dbo].[RecordDetail] ADD  CONSTRAINT [UseDEFAULT]  DEFAULT ((0)) FOR [USE]
GO
ALTER TABLE [dbo].[RecordDetail] ADD  CONSTRAINT [TakeDefault]  DEFAULT ((0)) FOR [Take]
GO
ALTER TABLE [dbo].[Record]  WITH CHECK ADD  CONSTRAINT [Passenger_idFK] FOREIGN KEY([Passenger_id])
REFERENCES [dbo].[Passenger] ([Passenger_id])
GO
ALTER TABLE [dbo].[Record] CHECK CONSTRAINT [Passenger_idFK]
GO
ALTER TABLE [dbo].[RecordDetail]  WITH CHECK ADD  CONSTRAINT [Record_idFK] FOREIGN KEY([Record_id])
REFERENCES [dbo].[Record] ([Record_id])
GO
ALTER TABLE [dbo].[RecordDetail] CHECK CONSTRAINT [Record_idFK]
GO
ALTER TABLE [dbo].[RecordDetail]  WITH CHECK ADD  CONSTRAINT [Seat_idFK] FOREIGN KEY([Seat_id])
REFERENCES [dbo].[Seat] ([Seat_id])
GO
ALTER TABLE [dbo].[RecordDetail] CHECK CONSTRAINT [Seat_idFK]
GO
ALTER TABLE [dbo].[RecordDetail]  WITH CHECK ADD  CONSTRAINT [Timetable_idFK] FOREIGN KEY([Timetable_id])
REFERENCES [dbo].[Timetable] ([Timetable_id])
GO
ALTER TABLE [dbo].[RecordDetail] CHECK CONSTRAINT [Timetable_idFK]
GO
ALTER TABLE [dbo].[TicketPrice]  WITH CHECK ADD  CONSTRAINT [Station1FK] FOREIGN KEY([Station1])
REFERENCES [dbo].[Station] ([Station_id])
GO
ALTER TABLE [dbo].[TicketPrice] CHECK CONSTRAINT [Station1FK]
GO
ALTER TABLE [dbo].[TicketPrice]  WITH CHECK ADD  CONSTRAINT [Station2FK] FOREIGN KEY([Station2])
REFERENCES [dbo].[Station] ([Station_id])
GO
ALTER TABLE [dbo].[TicketPrice] CHECK CONSTRAINT [Station2FK]
GO
ALTER TABLE [dbo].[Timetable]  WITH CHECK ADD  CONSTRAINT [Arrive_stationFK] FOREIGN KEY([Arrive_station])
REFERENCES [dbo].[Station] ([Station_id])
GO
ALTER TABLE [dbo].[Timetable] CHECK CONSTRAINT [Arrive_stationFK]
GO
ALTER TABLE [dbo].[Timetable]  WITH CHECK ADD  CONSTRAINT [Depart_stationFK] FOREIGN KEY([Depart_station])
REFERENCES [dbo].[Station] ([Station_id])
GO
ALTER TABLE [dbo].[Timetable] CHECK CONSTRAINT [Depart_stationFK]
GO
ALTER TABLE [dbo].[Timetable]  WITH CHECK ADD  CONSTRAINT [HSR_idFK] FOREIGN KEY([HSR_id])
REFERENCES [dbo].[HSR] ([HSR_id])
GO
ALTER TABLE [dbo].[Timetable] CHECK CONSTRAINT [HSR_idFK]
GO
/****** Object:  StoredProcedure [dbo].[Book]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Book] @RecordID NVARCHAR(60),@StartDate DATETIME,@Ticket1 INT,@Ticket2 INT,@Ticket3 INT,@Ticket4 INT,@Ticket5 INT,@Order NVARCHAR(10),@Type NVARCHAR(10),@Prefer NVARCHAR(10),@TimetableID NVARCHAR(20),@TicketNumber INT,@DepartTime TIME(0),@ArriveTime TIME(0)
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @SeatCount INT
	DECLARE @Index INT
	DECLARE @Seat1 NVARCHAR(MAX)
	DECLARE @Seat2 NVARCHAR(MAX)
	DECLARE @Seat3 NVARCHAR(MAX)
	DECLARE @Seat4 NVARCHAR(MAX)
	DECLARE @Seat5 NVARCHAR(MAX)
	DECLARE @Seats TABLE(
		SeatID NVARCHAR(10)
	)
	DECLARE @Return TABLE(
		SeatID NVARCHAR(10)
	)
	DECLARE @Seat NVARCHAR(20)
	BEGIN TRAN
	SELECT @SeatCount = [dbo].[SeatCount](@Prefer,@Type,@StartDate,@Order,@DepartTime,@ArriveTime)
	IF(@SeatCount<@TicketNumber)
		BEGIN
			SET @Seat1 = NULL
			COMMIT
		END
	ELSE
		BEGIN
			INSERT INTO @Seats(SeatID) SELECT [dbo].[Seats].Seat_id FROM [dbo].[Seats](@Prefer,@Type,@StartDate,@Order,@DepartTime,@ArriveTime)
			SET @Index=0
			WHILE @Index<@Ticket1
				BEGIN
					SELECT TOP(1) @Seat = SeatID FROM @Seats
					INSERT INTO [dbo].[RecordDetail]([Record_id],[Timetable_id],[Seat_id],[Reservation_time],[TicketTypeID]) VALUES(@RecordID,@TimetableID,@Seat,@StartDate,1)
					INSERT INTO @Return VALUES(@Seat)
					DELETE @Seats WHERE SeatID = @Seat
					SET @Index = @Index+1
				END
			SELECT @Seat1=ISNULL(STRING_AGG(SeatID,','),'')FROM @Return
			DELETE FROM @Return

			SET @Index=0
			WHILE @Index<@Ticket2
				BEGIN
					SELECT TOP(1) @Seat = SeatID FROM @Seats
					INSERT INTO [dbo].[RecordDetail]([Record_id],[Timetable_id],[Seat_id],[Reservation_time],[TicketTypeID]) VALUES(@RecordID,@TimetableID,@Seat,@StartDate,2)
					INSERT INTO @Return VALUES(@Seat)
					DELETE @Seats WHERE SeatID = @Seat
					SET @Index = @Index+1
				END
			SELECT @Seat2=ISNULL(STRING_AGG(SeatID,','),'')FROM @Return
			DELETE FROM @Return

			SET @Index=0
			WHILE @Index<@Ticket3
				BEGIN
					SELECT TOP(1) @Seat = SeatID FROM @Seats
					INSERT INTO [dbo].[RecordDetail]([Record_id],[Timetable_id],[Seat_id],[Reservation_time],[TicketTypeID]) VALUES(@RecordID,@TimetableID,@Seat,@StartDate,3)
					INSERT INTO @Return VALUES(@Seat)
					DELETE @Seats WHERE SeatID = @Seat
					SET @Index = @Index+1
				END
			SELECT @Seat3=ISNULL(STRING_AGG(SeatID,','),'')FROM @Return
			DELETE FROM @Return

			SET @Index=0
			WHILE @Index<@Ticket4
				BEGIN
					SELECT TOP(1) @Seat = SeatID FROM @Seats
					INSERT INTO [dbo].[RecordDetail]([Record_id],[Timetable_id],[Seat_id],[Reservation_time],[TicketTypeID]) VALUES(@RecordID,@TimetableID,@Seat,@StartDate,4)
					INSERT INTO @Return VALUES(@Seat)
					DELETE @Seats WHERE SeatID = @Seat
					SET @Index = @Index+1
				END
			SELECT @Seat4=ISNULL(STRING_AGG(SeatID,','),'')FROM @Return
			DELETE FROM @Return

			SET @Index=0
			WHILE @Index<@Ticket5
				BEGIN
					SELECT TOP(1) @Seat = SeatID FROM @Seats
					INSERT INTO [dbo].[RecordDetail]([Record_id],[Timetable_id],[Seat_id],[Reservation_time],[TicketTypeID]) VALUES(@RecordID,@TimetableID,@Seat,@StartDate,5)
					INSERT INTO @Return VALUES(@Seat)
					DELETE @Seats WHERE SeatID = @Seat
					SET @Index = @Index+1
				END
			SELECT @Seat5=ISNULL(STRING_AGG(SeatID,','),'')FROM @Return
			DELETE FROM @Return
			COMMIT
			SELECT @Seat1 AS Seat1,@Seat2 AS Seat2,@Seat3 AS Seat3,@Seat4 AS Seat4,@Seat5 AS Seat5
		END
GO
/****** Object:  StoredProcedure [dbo].[BookOneWay]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[BookOneWay] @ID NVARCHAR(20),@StartDate DATETIME,@StartStation NVARCHAR(10),@ArriveStation NVARCHAR(10),@Ticket1 INT,@Ticket2 INT,@Ticket3 INT,@Ticket4 INT,@Ticket5 INT,@Order NVARCHAR(10),@Type NVARCHAR(10),@Prefer NVARCHAR(10)
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @Count1 INT
	DECLARE @TicketNumber INT
	DECLARE @DepartTime1 TIME(0)
	DECLARE @ArriveTime1 TIME(0)
	DECLARE @TimetableID1 NVARCHAR(20)
	DECLARE @RecordID NVARCHAR(60)
	DECLARE @RESULT1 TABLE(
		Seat1 NVARCHAR(MAX),
		Seat2 NVARCHAR(MAX),
		Seat3 NVARCHAR(MAX),
		Seat4 NVARCHAR(MAX),
		Seat5 NVARCHAR(MAX)
	)
	SET @TicketNumber = @Ticket1+@Ticket2+@Ticket3+@Ticket4+@Ticket5
	SELECT @DepartTime1 = [dbo].[Timetable].Depart_time,@ArriveTime1 = [dbo].[Timetable].Arrive_time,
		@TimetableID1 = [dbo].[Timetable].Timetable_id
	FROM [dbo].[Timetable] 
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Station1.Station_name = @StartStation AND Station2.Station_name = @ArriveStation
		AND [Timetable].HSR_id = @Order
	BEGIN TRAN
		SET @RecordID = [dbo].[GetNewRecordID]()
		INSERT INTO [dbo].[Record]([Record_id],[Passenger_id],[TicketCount]) VALUES(@RecordID,@ID,@TicketNumber)
		INSERT INTO @RESULT1(Seat1,Seat2,Seat3,Seat4,Seat5)
			EXEC Book @RecordID,@StartDate,@Ticket1,@Ticket2,@Ticket3,@Ticket4,@Ticket5,@Order,@Type,@Prefer,@TimetableID1,@TicketNumber,@DepartTime1,@ArriveTime1
		SELECT @Count1 = COUNT(*) FROM @RESULT1
		IF(@Count1 = 0)
			BEGIN
				SET @RecordID = 'NoSeat'
				DELETE FROM @RESULT1
				INSERT INTO @RESULT1(Seat1,Seat2,Seat3,Seat4,Seat5) VALUES ('','','','','');
				ROLLBACK
			END
		ELSE
			COMMIT
	SELECT @RecordID AS RecordID, G.Seat1 AS GoSeat1, G.Seat2 AS GoSeat2, G.Seat3 AS GoSeat3, G.Seat4 AS GoSeat4, G.Seat5 AS GoSeat5
	FROM @RESULT1 AS G
GO
/****** Object:  StoredProcedure [dbo].[BookOneWayWithRecordID]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[BookOneWayWithRecordID] @ID NVARCHAR(20),@StartDate DATETIME,@StartStation NVARCHAR(10),@ArriveStation NVARCHAR(10),@Ticket1 INT,@Ticket2 INT,@Ticket3 INT,@Ticket4 INT,@Ticket5 INT,@Order NVARCHAR(10),@Type NVARCHAR(10),@Prefer NVARCHAR(10),@RecordID NVARCHAR(60),@Return NVARCHAR(60) OUTPUT
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @Count1 INT
	DECLARE @TicketNumber INT
	DECLARE @DepartTime1 TIME(0)
	DECLARE @ArriveTime1 TIME(0)
	DECLARE @TimetableID1 NVARCHAR(20)
	DECLARE @RESULT1 TABLE(
		Seat1 NVARCHAR(MAX),
		Seat2 NVARCHAR(MAX),
		Seat3 NVARCHAR(MAX),
		Seat4 NVARCHAR(MAX),
		Seat5 NVARCHAR(MAX)
	)
	SET @TicketNumber = @Ticket1+@Ticket2+@Ticket3+@Ticket4+@Ticket5
	SELECT @DepartTime1 = [dbo].[Timetable].Depart_time,@ArriveTime1 = [dbo].[Timetable].Arrive_time,
		@TimetableID1 = [dbo].[Timetable].Timetable_id
	FROM [dbo].[Timetable] 
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Station1.Station_name = @StartStation AND Station2.Station_name = @ArriveStation
		AND [Timetable].HSR_id = @Order
	BEGIN TRAN
		INSERT INTO @RESULT1(Seat1,Seat2,Seat3,Seat4,Seat5)
			EXEC Book @RecordID,@StartDate,@Ticket1,@Ticket2,@Ticket3,@Ticket4,@Ticket5,@Order,@Type,@Prefer,@TimetableID1,@TicketNumber,@DepartTime1,@ArriveTime1
		SELECT @Count1 = COUNT(*) FROM @RESULT1
		IF(@Count1 = 0)
			BEGIN
				SET @RecordID = 'NoSeat'
				DELETE FROM @RESULT1
				INSERT INTO @RESULT1(Seat1,Seat2,Seat3,Seat4,Seat5) VALUES ('','','','','');
			END
		COMMIT
	SET @Return = @RecordID
	SELECT @RecordID AS RecordID, G.Seat1 AS GoSeat1, G.Seat2 AS GoSeat2, G.Seat3 AS GoSeat3, G.Seat4 AS GoSeat4, G.Seat5 AS GoSeat5
	FROM @RESULT1 AS G
GO
/****** Object:  StoredProcedure [dbo].[BookReturn]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[BookReturn] @ID NVARCHAR(20),@StartDate DATETIME,@BackDate DATETIME,@StartStation NVARCHAR(10),@ArriveStation NVARCHAR(10),@Ticket1 INT,@Ticket2 INT,@Ticket3 INT,@Ticket4 INT,@Ticket5 INT,@Order NVARCHAR(10),@BackOrder NVARCHAR(10),@Type NVARCHAR(10),@Prefer NVARCHAR(10)
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @Count1 INT
	DECLARE @Count2 INT
	DECLARE @TicketNumber INT
	DECLARE @DepartTime1 TIME(0)
	DECLARE @ArriveTime1 TIME(0)
	DECLARE @TimetableID1 NVARCHAR(20)
	DECLARE @DepartTime2 TIME(0)
	DECLARE @ArriveTime2 TIME(0)
	DECLARE @TimetableID2 NVARCHAR(20)
	DECLARE @RecordID NVARCHAR(60)
	DECLARE @RESULT1 TABLE(
		Seat1 NVARCHAR(MAX),
		Seat2 NVARCHAR(MAX),
		Seat3 NVARCHAR(MAX),
		Seat4 NVARCHAR(MAX),
		Seat5 NVARCHAR(MAX)
	)
	DECLARE @RESULT2 TABLE(
		Seat1 NVARCHAR(MAX),
		Seat2 NVARCHAR(MAX),
		Seat3 NVARCHAR(MAX),
		Seat4 NVARCHAR(MAX),
		Seat5 NVARCHAR(MAX)
	)
	SET @TicketNumber = @Ticket1+@Ticket2+@Ticket3+@Ticket4+@Ticket5
	SELECT @DepartTime1 = [dbo].[Timetable].Depart_time,@ArriveTime1 = [dbo].[Timetable].Arrive_time,
		@TimetableID1 = [dbo].[Timetable].Timetable_id
	FROM [dbo].[Timetable] 
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Station1.Station_name = @StartStation AND Station2.Station_name = @ArriveStation
		AND [Timetable].HSR_id = @Order
	SELECT @DepartTime2 = [dbo].[Timetable].Depart_time,@ArriveTime2 = [dbo].[Timetable].Arrive_time,
		@TimetableID2 = [dbo].[Timetable].Timetable_id
	FROM [dbo].[Timetable] 
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Station1.Station_name = @ArriveStation AND Station2.Station_name = @StartStation
		AND [Timetable].HSR_id = @BackOrder
	BEGIN TRAN
		SET @RecordID = [dbo].[GetNewRecordID]()
		INSERT INTO [dbo].[Record]([Record_id],[Passenger_id],[TicketCount]) VALUES(@RecordID,@ID,@TicketNumber*2)
		INSERT INTO @RESULT1(Seat1,Seat2,Seat3,Seat4,Seat5)
			EXEC Book @RecordID,@StartDate,@Ticket1,@Ticket2,@Ticket3,@Ticket4,@Ticket5,@Order,@Type,@Prefer,@TimetableID1,@TicketNumber,@DepartTime1,@ArriveTime1
		INSERT INTO @RESULT2(Seat1,Seat2,Seat3,Seat4,Seat5)
			EXEC Book @RecordID,@BackDate,@Ticket1,@Ticket2,@Ticket3,@Ticket4,@Ticket5,@BackOrder,@Type,@Prefer,@TimetableID2,@TicketNumber,@DepartTime2,@ArriveTime2
		SELECT @Count1 = COUNT(*) FROM @RESULT1
		SELECT @Count2 = COUNT(*) FROM @RESULT2
		IF(@Count1 = 0 OR @Count2 = 0)
			BEGIN
				SET @RecordID = 'NoSeat'
				DELETE FROM @RESULT1
				DELETE FROM @RESULT2
				INSERT INTO @RESULT1(Seat1,Seat2,Seat3,Seat4,Seat5) VALUES ('','','','','');
				INSERT INTO @RESULT2(Seat1,Seat2,Seat3,Seat4,Seat5) VALUES ('','','','','');
				ROLLBACK
			END
		ELSE
			COMMIT
	SELECT @RecordID AS RecordID, G.Seat1 AS GoSeat1, G.Seat2 AS GoSeat2, G.Seat3 AS GoSeat3, G.Seat4 AS GoSeat4, G.Seat5 AS GoSeat5
								, B.Seat1 AS BackSeat1, B.Seat2 AS BackSeat2, B.Seat3 AS BackSeat3, B.Seat4 AS BackSeat4, B.Seat5 AS BackSeat5
	FROM @RESULT1 AS G,@RESULT2 AS B

--EXEC BookReturn 'Test1','2022/11/1','2022/11/1','南港','台北',1,2,3,4,5,'F809','D684','商務車廂','無偏好'
GO
/****** Object:  StoredProcedure [dbo].[BookReturnWithRecordID]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[BookReturnWithRecordID] @ID NVARCHAR(20),@StartDate DATETIME,@BackDate DATETIME,@StartStation NVARCHAR(10),@ArriveStation NVARCHAR(10),@Ticket1 INT,@Ticket2 INT,@Ticket3 INT,@Ticket4 INT,@Ticket5 INT,@Order NVARCHAR(10),@BackOrder NVARCHAR(10),@Type NVARCHAR(10),@Prefer NVARCHAR(10),@RecordID NVARCHAR(60),@Return NVARCHAR(60) OUTPUT
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @Count1 INT
	DECLARE @Count2 INT
	DECLARE @TicketNumber INT
	DECLARE @DepartTime1 TIME(0)
	DECLARE @ArriveTime1 TIME(0)
	DECLARE @TimetableID1 NVARCHAR(20)
	DECLARE @DepartTime2 TIME(0)
	DECLARE @ArriveTime2 TIME(0)
	DECLARE @TimetableID2 NVARCHAR(20)
	DECLARE @RESULT1 TABLE(
		Seat1 NVARCHAR(MAX),
		Seat2 NVARCHAR(MAX),
		Seat3 NVARCHAR(MAX),
		Seat4 NVARCHAR(MAX),
		Seat5 NVARCHAR(MAX)
	)
	DECLARE @RESULT2 TABLE(
		Seat1 NVARCHAR(MAX),
		Seat2 NVARCHAR(MAX),
		Seat3 NVARCHAR(MAX),
		Seat4 NVARCHAR(MAX),
		Seat5 NVARCHAR(MAX)
	)
	SET @TicketNumber = @Ticket1+@Ticket2+@Ticket3+@Ticket4+@Ticket5
	IF(NOT EXISTS(SELECT *
		FROM [dbo].[Timetable] 
		JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
		JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
		WHERE Station1.Station_name = @StartStation AND Station2.Station_name = @ArriveStation
			AND [Timetable].HSR_id = @Order))
		BEGIN 
			DECLARE @TEMP NVARCHAR(10) = @StartStation
			SET @StartStation = @ArriveStation
			SET @ArriveStation = @TEMP
		END
	SELECT @DepartTime1 = [dbo].[Timetable].Depart_time,@ArriveTime1 = [dbo].[Timetable].Arrive_time,
		@TimetableID1 = [dbo].[Timetable].Timetable_id
	FROM [dbo].[Timetable] 
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Station1.Station_name = @StartStation AND Station2.Station_name = @ArriveStation
		AND [Timetable].HSR_id = @Order
	SELECT @DepartTime2 = [dbo].[Timetable].Depart_time,@ArriveTime2 = [dbo].[Timetable].Arrive_time,
		@TimetableID2 = [dbo].[Timetable].Timetable_id
	FROM [dbo].[Timetable] 
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Station1.Station_name = @ArriveStation AND Station2.Station_name = @StartStation
		AND [Timetable].HSR_id = @BackOrder
	BEGIN TRAN
		INSERT INTO @RESULT1(Seat1,Seat2,Seat3,Seat4,Seat5)
			EXEC Book @RecordID,@StartDate,@Ticket1,@Ticket2,@Ticket3,@Ticket4,@Ticket5,@Order,@Type,@Prefer,@TimetableID1,@TicketNumber,@DepartTime1,@ArriveTime1
		INSERT INTO @RESULT2(Seat1,Seat2,Seat3,Seat4,Seat5)
			EXEC Book @RecordID,@BackDate,@Ticket1,@Ticket2,@Ticket3,@Ticket4,@Ticket5,@BackOrder,@Type,@Prefer,@TimetableID2,@TicketNumber,@DepartTime2,@ArriveTime2
		SELECT @Count1 = COUNT(*) FROM @RESULT1
		SELECT @Count2 = COUNT(*) FROM @RESULT2
		IF(@Count1 = 0 OR @Count2 = 0)
			BEGIN
				SET @RecordID = 'NoSeat'
				DELETE FROM @RESULT1
				DELETE FROM @RESULT2
				INSERT INTO @RESULT1(Seat1,Seat2,Seat3,Seat4,Seat5) VALUES ('','','','','');
				INSERT INTO @RESULT2(Seat1,Seat2,Seat3,Seat4,Seat5) VALUES ('','','','','');
			END
		COMMIT
	SET @Return = @RecordID
	SELECT @RecordID AS RecordID, G.Seat1 AS GoSeat1, G.Seat2 AS GoSeat2, G.Seat3 AS GoSeat3, G.Seat4 AS GoSeat4, G.Seat5 AS GoSeat5
								, B.Seat1 AS BackSeat1, B.Seat2 AS BackSeat2, B.Seat3 AS BackSeat3, B.Seat4 AS BackSeat4, B.Seat5 AS BackSeat5
	FROM @RESULT1 AS G,@RESULT2 AS B
GO
/****** Object:  StoredProcedure [dbo].[CheckID]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CheckID] @ID NVARCHAR(20),@Phone NVARCHAR(20),@Email NVARCHAR(40)
AS
DECLARE @PhoneData NVARCHAR(20)
DECLARE @EmailData NVARCHAR(40)
DECLARE @Update NVARCHAR(10)
DECLARE @New NVARCHAR(10)

SELECT @PhoneData = Passenger_phone,@EmailData = Passenger_email
FROM [dbo].[Passenger]
WHERE Passenger_id = @ID

IF @PhoneData IS NULL AND @EmailData IS NULL
	BEGIN
		SET @New = 'True'
		SET @Update = 'False'
		INSERT INTO [dbo].[Passenger]([Passenger_id],[Passenger_email],[Passenger_phone]) VALUES(@ID,@Email,@Phone)
	END
ELSE
	BEGIN
		SET @New = 'False'
		IF @Phone = @PhoneData AND @Email = @EmailData
			SET @Update = 'False'
		ELSE
			BEGIN
				SET @Update = 'True'
				UPDATE [dbo].[Passenger] SET [Passenger_email] = @Email WHERE Passenger_id = @ID
				UPDATE [dbo].[Passenger] SET [Passenger_phone] = @Phone WHERE Passenger_id = @ID
			END
	END
SELECT @New  AS New,@Update AS [Update]
GO
/****** Object:  StoredProcedure [dbo].[CMRecorder]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CMRecorder] @RequestType NVARCHAR(MAX),@Request NVARCHAR(MAX),@Response NVARCHAR(MAX),@ClientIP NVARCHAR(30)
AS
INSERT INTO ConnectMessageRecord(RequestType,Request,Response,ClientIP) 
		VALUES(@RequestType,@Request,@Response,@ClientIP)
GO
/****** Object:  StoredProcedure [dbo].[EditOneWay]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[EditOneWay] @BookID NVARCHAR(60),@StartDate DATETIME,@ORDER NVARCHAR(10)
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @TicketCount1 INT
	DECLARE @TicketCount2 INT
	DECLARE @TicketCount3 INT
	DECLARE @TicketCount4 INT
	DECLARE @TicketCount5 INT
	DECLARE @DepartStation NVARCHAR(10)
	DECLARE @ArriveStation NVARCHAR(10)
	DECLARE @Type NVARCHAR(10)
	DECLARE @ID NVARCHAR(20)
	DECLARE @RefundResult NVARCHAR(10)
	DECLARE @RefundResultTemp TABLE(
		Result NVARCHAR(10)
	)
	DECLARE @Return1 NVARCHAR(60)
	SELECT	@TicketCount1 = COUNT(CASE WHEN TicketTypeID = 1 THEN 1 END) ,
			@TicketCount2 = COUNT(CASE WHEN TicketTypeID = 2 THEN 1 END) ,
			@TicketCount3 = COUNT(CASE WHEN TicketTypeID = 3 THEN 1 END) ,
			@TicketCount4 = COUNT(CASE WHEN TicketTypeID = 4 THEN 1 END) ,
			@TicketCount5 = COUNT(CASE WHEN TicketTypeID = 5 THEN 1 END) 
	FROM [dbo].[RecordDetail] WHERE Record_id = @BookID
	SELECT @DepartStation = Station1.Station_name,@ArriveStation = Station2.Station_name
	FROM [dbo].[RecordDetail] 
	JOIN [dbo].[Timetable] ON [dbo].[RecordDetail].Timetable_id = [dbo].[Timetable].Timetable_id
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Record_id = @BookID
	SELECT @Type = [dbo].[Seat].CarType
	FROM [dbo].[RecordDetail]
	JOIN [dbo].[Seat] ON [dbo].[RecordDetail].Seat_id = [dbo].[Seat].Seat_id
	SELECT @Type = [Value]
	FROM [dbo].[DataTransform]
	WHERE StoredProcedure = 'Edit' AND [Key] = @Type
	SELECT @ID = Passenger_id
	FROM [dbo].[Record]
	WHERE Record_id = @BookID
	BEGIN TRAN
		INSERT @RefundResultTemp(Result) 
		EXEC Refund @BookID
		SELECT @RefundResult = Result FROM @RefundResultTemp
		EXEC BookOneWayWithRecordID @ID,@StartDate,@DepartStation,@ArriveStation,@TicketCount1,@TicketCount2,@TicketCount3,@TicketCount4,@TicketCount5,@ORDER,@Type,'無偏好',@BookID,@Return1 OUTPUT
		IF(@Return1 = 'NoSeat' OR @RefundResult = 'False')
			ROLLBACK
		ELSE
			COMMIT
GO
/****** Object:  StoredProcedure [dbo].[EditReturn]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[EditReturn] @BookID NVARCHAR(60),@StartDate DATETIME,@Order NVARCHAR(10),@BackDate DATETIME,@BackOrder NVARCHAR(10)
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @TicketCount1 INT
	DECLARE @TicketCount2 INT
	DECLARE @TicketCount3 INT
	DECLARE @TicketCount4 INT
	DECLARE @TicketCount5 INT
	DECLARE @DepartStation NVARCHAR(10)
	DECLARE @ArriveStation NVARCHAR(10)
	DECLARE @Type NVARCHAR(10)
	DECLARE @ID NVARCHAR(20)
	DECLARE @RefundResult NVARCHAR(10)
	DECLARE @RefundResultTemp TABLE(
		Result NVARCHAR(10)
	)
	DECLARE @Return1 NVARCHAR(60)
	SELECT	@TicketCount1 = COUNT(CASE WHEN TicketTypeID = 1 THEN 1 END)/2 ,
			@TicketCount2 = COUNT(CASE WHEN TicketTypeID = 2 THEN 1 END)/2 ,
			@TicketCount3 = COUNT(CASE WHEN TicketTypeID = 3 THEN 1 END)/2 ,
			@TicketCount4 = COUNT(CASE WHEN TicketTypeID = 4 THEN 1 END)/2 ,
			@TicketCount5 = COUNT(CASE WHEN TicketTypeID = 5 THEN 1 END)/2 
	FROM [dbo].[RecordDetail] WHERE Record_id = @BookID
	SELECT @DepartStation = Station1.Station_name,@ArriveStation = Station2.Station_name
	FROM [dbo].[RecordDetail] 
	JOIN [dbo].[Timetable] ON [dbo].[RecordDetail].Timetable_id = [dbo].[Timetable].Timetable_id
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Record_id = @BookID
	SELECT @Type = [dbo].[Seat].CarType
	FROM [dbo].[RecordDetail]
	JOIN [dbo].[Seat] ON [dbo].[RecordDetail].Seat_id = [dbo].[Seat].Seat_id
	SELECT @Type = [Value]
	FROM [dbo].[DataTransform]
	WHERE StoredProcedure = 'Edit' AND [Key] = @Type
	SELECT @ID = Passenger_id
	FROM [dbo].[Record]
	WHERE Record_id = @BookID
	BEGIN TRAN
		INSERT @RefundResultTemp(Result) 
		EXEC Refund @BookID
		SELECT @RefundResult = Result FROM @RefundResultTemp
		EXEC BookReturnWithRecordID @ID,@StartDate,@BackDate,@DepartStation,@ArriveStation,@TicketCount1,@TicketCount2,@TicketCount3,@TicketCount4,@TicketCount5,@Order,@BackOrder,@Type,'無偏好',@BookID,@Return1 OUTPUT
		IF(@Return1 = 'NoSeat' OR @RefundResult = 'False')
			ROLLBACK
		ELSE
			COMMIT
GO
/****** Object:  StoredProcedure [dbo].[FindCode]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[FindCode] @StartStation NVARCHAR(10),@ArriveStation NVARCHAR(10),@StartDate DATETIME,@Order NVARCHAR(10),@ID NVARCHAR(20)
AS
	DECLARE @TimetableID NVARCHAR(30)
	SELECT @TimetableID = Timetable_id 
	FROM [dbo].[Timetable]
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Station1.Station_name = @StartStation AND Station2.Station_name = @ArriveStation
		AND HSR_id = @Order
	;WITH RecordIDs
	AS(
		SELECT DISTINCT Record_id 
		FROM [dbo].[RecordDetail]
		WHERE Record_id IN(
		SELECT Record_id
		FROM [dbo].[Record]
		WHERE Passenger_id = @ID
		)
		AND Timetable_id = @TimetableID
		AND Reservation_time = @StartDate
	)
	SELECT(
		SELECT Record_id AS Code,IIF([Pay] = 1,'True','False') AS PayResult
		FROM [dbo].[Record] 
		WHERE Record_id IN (SELECT * FROM RecordIDs)
		FOR JSON PATH
		) AS Datas
GO
/****** Object:  StoredProcedure [dbo].[FindLose]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[FindLose] @ID NVARCHAR(20),@BookID NVARCHAR(60)
AS
	DECLARE @TimetableCount INT
	DECLARE @OnewayReturn NVARCHAR(10)
	DECLARE @Type NVARCHAR(10)
	DECLARE @Tickets NVARCHAR(40)
	DECLARE @Prices NVARCHAR(40)
	IF(
	EXISTS (SELECT Record_id
	FROM [dbo].[Record]
	WHERE Record_id = @BookID AND Passenger_id = @ID)
	)
		BEGIN
			SELECT @TimetableCount=COUNT(DISTINCT Timetable_id)
			FROM [dbo].[RecordDetail] 
			WHERE Record_id = @BookID
			SELECT @Type = [dbo].[Seat].CarType
			FROM [dbo].[RecordDetail]
			JOIN [dbo].[Seat] ON [dbo].[RecordDetail].Seat_id = [dbo].[Seat].Seat_id
			WHERE Record_id = @BookID
			SELECT @Type = [Value]
			FROM [dbo].[DataTransform]
			WHERE StoredProcedure = 'Edit' AND [Key] = @Type
			SELECT	@Tickets = CONCAT( COUNT(CASE WHEN TicketTypeID = 1 THEN 1 END) ,',',
					COUNT(CASE WHEN TicketTypeID = 2 THEN 1 END) ,',',
					COUNT(CASE WHEN TicketTypeID = 3 THEN 1 END) ,',',
					COUNT(CASE WHEN TicketTypeID = 4 THEN 1 END) ,',',
					COUNT(CASE WHEN TicketTypeID = 5 THEN 1 END) )
			FROM [dbo].[RecordDetail] WHERE Record_id = @BookID
			IF(@TimetableCount=1)
				BEGIN
					SET @OnewayReturn = 'False'
					DECLARE @TimetableID NVARCHAR(20)
					DECLARE @TicketsData TABLE(
						[Date] DateTime,
						StartStation NVARCHAR(10),
						ArriveStation NVARCHAR(10),
						StartTime TIME(0),
						ArriveTime TIME(0),
						[Order] NVARCHAR(10),
						Seat1 NVARCHAR(MAX),
						Seat2 NVARCHAR(MAX),
						Seat3 NVARCHAR(MAX),
						Seat4 NVARCHAR(MAX),
						Seat5 NVARCHAR(MAX),
						StationsBy NVARCHAR(MAX)
					)
					SELECT DISTINCT @TimetableID = Timetable_id FROM [dbo].[RecordDetail] WHERE Record_id = @BookID
					INSERT INTO @TicketsData
						EXEC TicketsData @BookID,@TimetableID
					DECLARE @Station1 NVARCHAR(10)
					DECLARE @Station2 NVARCHAR(10)
					SELECT @Station1=StartStation,@Station2=ArriveStation FROM @TicketsData
					EXEC [GetTrainPrice] @Station1,@Station2,@Type,@Prices OUTPUT
					SELECT @OnewayReturn AS OnewayReturn,@Type AS [Type],@Tickets AS Tickets,@Prices AS Prices,
							(SELECT * FROM @TicketsData FOR JSON PATH) AS Data1,
							'' AS Data2
				END
			ELSE IF(@TimetableCount=2)
				BEGIN
					SET @OnewayReturn = 'True'
					DECLARE @TimetableID1 NVARCHAR(20)
					DECLARE @TimetableID2 NVARCHAR(20)
					DECLARE @TicketsData1 TABLE(
						[Date] DateTime,
						StartStation NVARCHAR(10),
						ArriveStation NVARCHAR(10),
						StartTime TIME(0),
						ArriveTime TIME(0),
						[Order] NVARCHAR(10),
						Seat1 NVARCHAR(MAX),
						Seat2 NVARCHAR(MAX),
						Seat3 NVARCHAR(MAX),
						Seat4 NVARCHAR(MAX),
						Seat5 NVARCHAR(MAX),
						StationsBy NVARCHAR(MAX)
					)
					DECLARE @TicketsData2 TABLE(
						[Date] DateTime,
						StartStation NVARCHAR(10),
						ArriveStation NVARCHAR(10),
						StartTime TIME(0),
						ArriveTime TIME(0),
						[Order] NVARCHAR(10),
						Seat1 NVARCHAR(MAX),
						Seat2 NVARCHAR(MAX),
						Seat3 NVARCHAR(MAX),
						Seat4 NVARCHAR(MAX),
						Seat5 NVARCHAR(MAX),
						StationsBy NVARCHAR(MAX)
					)
					SELECT DISTINCT @TimetableID1 = Timetable_id FROM [dbo].[RecordDetail] WHERE Record_id = @BookID
					SELECT DISTINCT @TimetableID2 = Timetable_id FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Timetable_id <> @TimetableID1
					INSERT INTO @TicketsData1
						EXEC TicketsData @BookID,@TimetableID1
					INSERT INTO @TicketsData2
						EXEC TicketsData @BookID,@TimetableID2
					DECLARE @Station3 NVARCHAR(10)
					DECLARE @Station4 NVARCHAR(10)
					SELECT @Station3=StartStation,@Station4=ArriveStation FROM @TicketsData1
					EXEC [GetTrainPrice] @Station3,@Station4,@Type,@Prices OUTPUT
					SELECT @OnewayReturn AS OnewayReturn,@Type AS [Type],@Tickets AS Tickets,@Prices AS Prices,
							(SELECT TOP 1 * FROM @TicketsData1 FOR JSON PATH) AS Data1,
							(SELECT TOP 1 * FROM @TicketsData2 FOR JSON PATH) AS Data2
				END
		END
	ELSE
		SELECT 'NoData' AS OnewayReturn,'' AS [Type],'' AS Tickets,'' AS Prices,'' AS Data1,'' AS Data2

--EXEC [FindLose] 'A111111111','20221119131825A111111111'
GO
/****** Object:  StoredProcedure [dbo].[GetTrainPrice]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetTrainPrice] @Station1 NVARCHAR(10),@Station2 NVARCHAR(10),@Type NVARCHAR(10),@TicketPrice NVARCHAR(MAX) OUTPUT
AS
DECLARE @CarType CHAR
SELECT @CarType = [Value] FROM [dbo].[DataTransform] WHERE [StoredProcedure] = 'GetTrains' AND [Key] = @Type
SELECT @TicketPrice = CONCAT(STRING_AGG(CONVERT(INT,[dbo].[TicketPrice].Travel_cost),',') WITHIN GROUP ( ORDER BY [dbo].[TicketPrice].Travel_cost DESC),',0,0,0')
FROM [dbo].[TicketPrice]
JOIN [dbo].[Station] AS Station1 ON [dbo].[TicketPrice].Station1 = Station1.Station_id
JOIN [dbo].[Station] AS Station2 ON [dbo].[TicketPrice].Station2 = Station2.Station_id
WHERE Station1.Station_name = @Station1 AND Station2.Station_name = @Station2 AND [dbo].[TicketPrice].CarType = @CarType
GO
/****** Object:  StoredProcedure [dbo].[GetTrains]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetTrains] @Station1 NVARCHAR(10),@Station2 NVARCHAR(10),@DepartDate DATETIME,@DepartTime TIME,@Type NVARCHAR(10),@PreferData NVARCHAR(10),@Json NVARCHAR(MAX) OUTPUT
AS
DECLARE @TicketType INT
DECLARE @CarType CHAR
SELECT @CarType = [Value] FROM [dbo].[DataTransform] WHERE [StoredProcedure] = 'GetTrains' AND [Key] = @Type
SELECT @TicketType = CONVERT(INT,[Value]) FROM [dbo].[DataTransform] WHERE [StoredProcedure] = 'GetTrains' AND [Key] = @CarType
SET DATEFIRST 1
SET @Json = (
SELECT [dbo].[Timetable].HSR_id AS [Order],[dbo].[Timetable].Depart_time AS StartTime,[dbo].[Timetable].Arrive_time AS ArriveTime, 
	(SELECT [dbo].[StationsBy] ([dbo].[Timetable].HSR_id))AS StationsBy,
	(SELECT [dbo].[SeatCount] (@PreferData,@Type,@DepartDate,[dbo].[Timetable].HSR_id,[dbo].[Timetable].Depart_time,[dbo].[Timetable].Arrive_time)) AS SeatCount
FROM [dbo].[Timetable]
JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
WHERE Station1.Station_name = @Station1 AND Station2.Station_name = @Station2 AND [dbo].[Timetable].Depart_time >= @DepartTime
	AND (SELECT [dbo].[CheckHSRWork]([dbo].[Timetable].HSR_id,@DepartDate) AS Work)>0
ORDER BY [dbo].[Timetable].Depart_time ASC
FOR JSON PATH
)
GO
/****** Object:  StoredProcedure [dbo].[GetTrainsOneWay]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetTrainsOneWay] @Station1 NVARCHAR(10),@Station2 NVARCHAR(10),@DepartDate DATETIME,@DepartTime TIME,@Type NVARCHAR(10),@PreferData NVARCHAR(10)
AS
	DECLARE @TicketPrice NVARCHAR(MAX)
	DECLARE @Json1 NVARCHAR(MAX)
	EXEC [GetTrainPrice] @Station1,@Station2,@Type,@TicketPrice OUTPUT
	EXEC [GetTrains] @Station1,@Station2,@DepartDate,@DepartTime,@Type,@PreferData,@Json1 OUTPUT
	SELECT @TicketPrice AS 'TicketPrice',@Json1 AS 'Datas'
GO
/****** Object:  StoredProcedure [dbo].[GetTrainsReturn]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetTrainsReturn] @Station1 NVARCHAR(10),@Station2 NVARCHAR(10),@DepartDate DATETIME,@DepartTime TIME,@BackDate DATETIME,@BackTime TIME,@Type NVARCHAR(10),@PreferData NVARCHAR(10)
AS
	DECLARE @TicketPrice NVARCHAR(MAX)
	DECLARE @Json1 NVARCHAR(MAX)
	DECLARE @Json2 NVARCHAR(MAX)
	EXEC [GetTrainPrice] @Station1,@Station2,@Type,@TicketPrice OUTPUT
	EXEC [GetTrains] @Station1,@Station2,@DepartDate,@DepartTime,@Type,@PreferData,@Json1 OUTPUT
	EXEC [GetTrains] @Station2,@Station1,@BackDate,@BackTime,@Type,@PreferData,@Json2 OUTPUT
	SELECT @TicketPrice AS 'TicketPrice',@Json1 AS 'Datas',@Json2 AS 'BackDatas'
GO
/****** Object:  StoredProcedure [dbo].[HasTake]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[HasTake] @ID NVARCHAR(60),@Order NVARCHAR(20),@SeatID NVARCHAR(20)
AS
	DECLARE @TimetableID NVARCHAR(20)
	DECLARE @HasTakeResult NVARCHAR(10) = 'False'
	SELECT @TimetableID = [dbo].[RecordDetail].Timetable_id FROM [dbo].[RecordDetail]
	JOIN [dbo].[Timetable] ON [dbo].[RecordDetail].Timetable_id = [dbo].[Timetable].Timetable_id
	WHERE Record_id = @ID AND Seat_id = @SeatID AND HSR_id = @Order
	SELECT @HasTakeResult = IIF([Take]=1,'True','False')
	FROM [dbo].[RecordDetail] 
	WHERE Record_id = @ID 
		AND Timetable_id = @TimetableID
		AND Seat_id = @SeatID
	SELECT @HasTakeResult AS HasTakeResult
GO
/****** Object:  StoredProcedure [dbo].[PaidEditOneway]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[PaidEditOneway] @BookID NVARCHAR(60),@StartDate DATETIME, @OriginOrder NVARCHAR(20), @OriginSeat NVARCHAR(20),@Order NVARCHAR(20)
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @TicketTypeID INT
	DECLARE @Take1 BIT
	DECLARE @TimetableID1 NVARCHAR(20)
	DECLARE @Seat1 NVARCHAR(20)
	DECLARE @Type NVARCHAR(10)
	DECLARE @TEMP1 INT
	SELECT @Type = CarType FROM [dbo].[Seat] WHERE Seat_id = @OriginSeat 
	SELECT @Type = [Value] FROM [dbo].[DataTransform] WHERE [StoredProcedure] = 'Edit' AND [Key] = @Type
	SELECT @TicketTypeID = TicketTypeID,@Take1 = [Take]
	FROM [dbo].[RecordDetail] 
	WHERE Record_id = @BookID AND Seat_id = @OriginSeat AND [USE] = 0
		AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail].Timetable_id) = @OriginOrder
	IF(@TicketTypeID IS NULL)
	BEGIN
		SET @Seat1='Can''tEdit'
	END
	ELSE
		BEGIN
			SELECT @TimetableID1= Timetable_id
			FROM [dbo].[Timetable]
			WHERE HSR_id = @Order
				AND Depart_station = (SELECT Depart_station FROM [dbo].[Timetable] WHERE Timetable_id = (SELECT Timetable_id FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Seat_id = @OriginSeat AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail].Timetable_id) = @OriginOrder))
				AND Arrive_station = (SELECT Arrive_station FROM [dbo].[Timetable] WHERE Timetable_id = (SELECT Timetable_id FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Seat_id = @OriginSeat AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail].Timetable_id) = @OriginOrder))
			BEGIN TRAN
				DELETE FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Seat_id = @OriginSeat
					AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail] .Timetable_id) = @OriginOrder
				SELECT @TEMP1 = [dbo].[SeatCount]('無偏好',@Type,@StartDate,@Order,(SELECT Depart_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID1),(SELECT Arrive_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID1))
				IF(@TEMP1>=1)
					BEGIN
						SELECT @Seat1 = Seat_id FROM [dbo].[Seats]('無偏好',@Type,@StartDate,@Order,(SELECT Depart_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID1),(SELECT Arrive_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID1))
						INSERT INTO [dbo].[RecordDetail]([Record_id],[Timetable_id],[Seat_id],[Reservation_time],[TicketTypeID],[Take]) VALUES(@BookID,@TimetableID1,@Seat1,@StartDate,@TicketTypeID,@Take1)
						COMMIT
					END
				ELSE
					BEGIN
						SET @Seat1='NoSeat'
						ROLLBACK
					END
		END
	
	SELECT @Seat1 AS [GoSeat]
GO
/****** Object:  StoredProcedure [dbo].[PaidEditReturn]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[PaidEditReturn] @BookID NVARCHAR(60),@StartDate DATETIME, @BackDate DATETIME, @OriginOrder NVARCHAR(20), @OriginSeat NVARCHAR(20),@OriginBackOrder NVARCHAR(20), @OriginBackSeat NVARCHAR(20),@Order NVARCHAR(20),@BackOrder NVARCHAR(20)
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @TicketTypeID INT
	DECLARE @Take1 BIT
	DECLARE @Take2 BIT
	DECLARE @TimetableID1 NVARCHAR(20)
	DECLARE @TimetableID2 NVARCHAR(20)
	DECLARE @Seat1 NVARCHAR(20)
	DECLARE @Seat2 NVARCHAR(20)
	DECLARE @Type NVARCHAR(10)
	DECLARE @TEMP1 INT
	DECLARE @TEMP2 INT
	SELECT @Type = CarType FROM [dbo].[Seat] WHERE Seat_id = @OriginSeat 
	SELECT @Type = [Value] FROM [dbo].[DataTransform] WHERE [StoredProcedure] = 'Edit' AND [Key] = @Type
	SELECT @TicketTypeID = TicketTypeID,@Take1 = [Take]
	FROM [dbo].[RecordDetail] 
	WHERE Record_id = @BookID AND Seat_id = @OriginSeat AND [USE] = 0
		AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail] .Timetable_id) = @OriginOrder
	IF(@TicketTypeID IS NULL)
	BEGIN
		SET @Seat1='Can''tEdit'
	END
	ELSE
		BEGIN
			SELECT @Take2 = [Take]
			FROM [dbo].[RecordDetail] 
			WHERE Record_id = @BookID AND Seat_id = @OriginBackSeat AND [USE] = 0
				AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail] .Timetable_id) = @OriginBackOrder
			SELECT @TimetableID1= Timetable_id
			FROM [dbo].[Timetable]
			WHERE HSR_id = @Order
				AND Depart_station = (SELECT Depart_station FROM [dbo].[Timetable] WHERE Timetable_id = (SELECT Timetable_id FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Seat_id = @OriginSeat AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail].Timetable_id) = @OriginOrder))
				AND Arrive_station = (SELECT Arrive_station FROM [dbo].[Timetable] WHERE Timetable_id = (SELECT Timetable_id FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Seat_id = @OriginSeat AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail].Timetable_id) = @OriginOrder))
			SELECT @TimetableID2= Timetable_id
			FROM [dbo].[Timetable]
			WHERE HSR_id = @BackOrder
				AND Depart_station = (SELECT Depart_station FROM [dbo].[Timetable] WHERE Timetable_id = (SELECT Timetable_id FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Seat_id = @OriginBackSeat AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail].Timetable_id) = @OriginBackOrder))
				AND Arrive_station = (SELECT Arrive_station FROM [dbo].[Timetable] WHERE Timetable_id = (SELECT Timetable_id FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Seat_id = @OriginBackSeat AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail].Timetable_id) = @OriginBackOrder))
			BEGIN TRAN
				DELETE FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Seat_id = @OriginSeat
					AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail] .Timetable_id) = @OriginOrder
				DELETE FROM [dbo].[RecordDetail] WHERE Record_id = @BookID AND Seat_id = @OriginBackSeat
					AND (SELECT HSR_id FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id = [dbo].[RecordDetail] .Timetable_id) = @OriginBackOrder
				SELECT @TEMP1 = [dbo].[SeatCount]('無偏好',@Type,@StartDate,@Order,(SELECT Depart_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID1),(SELECT Arrive_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID1))
				SELECT @TEMP2 = [dbo].[SeatCount]('無偏好',@Type,@BackDate,@BackOrder,(SELECT Depart_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID2),(SELECT Arrive_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID2))
				IF(@TEMP1>=1 AND @TEMP2>=1)
					BEGIN
						SELECT TOP(1) @Seat1 = Seat_id FROM [dbo].[Seats]('無偏好',@Type,@StartDate,@Order,(SELECT Depart_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID1),(SELECT Arrive_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID1))
						SELECT TOP(1) @Seat2 = Seat_id FROM [dbo].[Seats]('無偏好',@Type,@BackDate,@BackOrder,(SELECT Depart_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID2),(SELECT Arrive_time FROM [dbo].[Timetable] WHERE [dbo].[Timetable].Timetable_id=@TimetableID2))
						INSERT INTO [dbo].[RecordDetail]([Record_id],[Timetable_id],[Seat_id],[Reservation_time],[TicketTypeID],[Take]) VALUES(@BookID,@TimetableID1,@Seat1,@StartDate,@TicketTypeID,@Take1)
						INSERT INTO [dbo].[RecordDetail]([Record_id],[Timetable_id],[Seat_id],[Reservation_time],[TicketTypeID],[Take]) VALUES(@BookID,@TimetableID2,@Seat2,@BackDate,@TicketTypeID,@Take2)
						COMMIT
					END
				ELSE
					BEGIN
						SET @Seat1='NoSeat'
						SET @Seat2='NoSeat'
						ROLLBACK
					END
		END
	SELECT @Seat1 AS [GoSeat],@Seat2 AS [BackSeat]
		
GO
/****** Object:  StoredProcedure [dbo].[Pay]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Pay] @ID NVARCHAR(60)
AS
	DECLARE @IDCount INT
	SELECT @IDCount = COUNT(Record_id) FROM [dbo].[Record] WHERE Record_id = @ID AND [Pay] = 0
	IF(@IDCount>0)
		BEGIN
			UPDATE [dbo].[Record] SET [Pay] = 1 WHERE Record_id = @ID
			SELECT 'True' AS [PayResult]
		END
	ELSE
		BEGIN
			SELECT 'False' AS [PayResult]
		END

GO
/****** Object:  StoredProcedure [dbo].[Refund]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Refund] @ID NVARCHAR(60)
AS
	DECLARE @IDCount INT
	SELECT @IDCount = COUNT(Record_id) FROM [dbo].[Record] WHERE Record_id = @ID
	IF(@IDCount>0)
		BEGIN
			DELETE FROM [dbo].[RecordDetail] WHERE Record_id = @ID
			SELECT 'True' AS [RefundResult]
		END
	ELSE
		BEGIN
			SELECT 'False' AS [RefundResult]
		END

--EXEC Refund '20221119131736A111111111'
GO
/****** Object:  StoredProcedure [dbo].[RefundTicket]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[RefundTicket] @ID NVARCHAR(60),@Order NVARCHAR(20),@SeatID NVARCHAR(20)
AS
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	DECLARE @IDCount INT
	DECLARE @TicketCount INT
	DECLARE @TimetableID NVARCHAR(20)
	SELECT @IDCount = COUNT(Record_id) FROM [dbo].[Record] WHERE Record_id = @ID
	SELECT @TimetableID = [dbo].[RecordDetail].Timetable_id FROM [dbo].[RecordDetail]
	JOIN [dbo].[Timetable] ON [dbo].[RecordDetail].Timetable_id = [dbo].[Timetable].Timetable_id
	WHERE Record_id = @ID AND Seat_id = @SeatID AND HSR_id = @Order	
	SELECT @TicketCount = COUNT(*) FROM [dbo].[RecordDetail] WHERE Record_id = @ID AND Timetable_id = @TimetableID AND Seat_id = @SeatID
	IF(@IDCount>0 AND @TicketCount>0)
		BEGIN
			BEGIN TRAN
				DELETE FROM [dbo].[RecordDetail] WHERE Record_id = @ID AND Timetable_id = @TimetableID AND Seat_id = @SeatID
				UPDATE [dbo].[Record] SET TicketCount = TicketCount-1 WHERE Record_id = @ID
			COMMIT
			SELECT 'True' AS [RefundResult]
		END
	ELSE
		BEGIN
			SELECT 'False' AS [RefundResult]
		END
GO
/****** Object:  StoredProcedure [dbo].[Take]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Take] @ID NVARCHAR(60),@Order NVARCHAR(20),@SeatID NVARCHAR(20)
AS
	DECLARE @IDCount INT
	DECLARE @TimetableID NVARCHAR(20)
	DECLARE @Take BIT
	SELECT @IDCount = COUNT(Record_id) FROM [dbo].[Record] WHERE Record_id = @ID AND [Pay] = 1
	SELECT @TimetableID = [dbo].[RecordDetail].Timetable_id FROM [dbo].[RecordDetail]
	JOIN [dbo].[Timetable] ON [dbo].[RecordDetail].Timetable_id = [dbo].[Timetable].Timetable_id
	WHERE Record_id = @ID AND Seat_id = @SeatID AND HSR_id = @Order
	SELECT @Take = [Take] FROM [dbo].[RecordDetail] WHERE Record_id = @ID AND Timetable_id = @TimetableID
	IF(@IDCount>0 AND @Take=0)
		BEGIN
			UPDATE [dbo].[RecordDetail] SET [Take] = 1 WHERE Record_id = @ID AND Timetable_id = @TimetableID AND Seat_id = @SeatID
			SELECT 'True' AS [TakeResult]
		END
	ELSE
		BEGIN
			SELECT 'False' AS [TakeResult]
		END
GO
/****** Object:  StoredProcedure [dbo].[TicketsData]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[TicketsData] @BookID NVARCHAR(60),@TimetableID NVARCHAR(60)
AS
	DECLARE @Date DateTime
	DECLARE @StartStation NVARCHAR(10)
	DECLARE @ArriveStation NVARCHAR(10)
	DECLARE @StartTime TIME(0)
	DECLARE @ArriveTime TIME(0)
	DECLARE @Order NVARCHAR(10)
	DECLARE @Seat1 NVARCHAR(MAX)
	DECLARE @Seat2 NVARCHAR(MAX)
	DECLARE @Seat3 NVARCHAR(MAX)
	DECLARE @Seat4 NVARCHAR(MAX)
	DECLARE @Seat5 NVARCHAR(MAX)
	SELECT * INTO #TempRecordDetail FROM [dbo].[RecordDetail] 
	WHERE Record_id = @BookID AND Timetable_id = @TimetableID
	SELECT DISTINCT @Date = Reservation_time
	FROM #TempRecordDetail
	SELECT	@StartStation = Station1.Station_name,
			@ArriveStation = Station2.Station_name,
			@StartTime = [Timetable].Depart_time,
			@ArriveTime = [Timetable].Arrive_time,
			@Order = [Timetable].HSR_id
	FROM [dbo].[Timetable]
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Timetable_id = @TimetableID
	SELECT @Seat1=STRING_AGG(Seat_id,',') FROM #TempRecordDetail WHERE TicketTypeID = 1
	SELECT @Seat2=STRING_AGG(Seat_id,',') FROM #TempRecordDetail WHERE TicketTypeID = 2
	SELECT @Seat3=STRING_AGG(Seat_id,',') FROM #TempRecordDetail WHERE TicketTypeID = 3
	SELECT @Seat4=STRING_AGG(Seat_id,',') FROM #TempRecordDetail WHERE TicketTypeID = 4
	SELECT @Seat5=STRING_AGG(Seat_id,',') FROM #TempRecordDetail WHERE TicketTypeID = 5
	SELECT @Date AS [Date],@StartStation AS StartStation,@ArriveStation AS ArriveStation,
			@StartTime AS StartTime,@ArriveTime AS ArriveTime,@Order AS [Order],
			@Seat1 AS Seat1,@Seat2 AS Seat2,@Seat3 AS Seat3,@Seat4 AS Seat4,@Seat5 AS Seat5,
			[dbo].[StationsBy](@Order)
GO
/****** Object:  StoredProcedure [dbo].[TimeTableSearch]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[TimeTableSearch] @Station1 NVARCHAR(20),@Station2 NVARCHAR(20), @DepartDate DATE
AS
	SET DATEFIRST 1
	SELECT TOP(1) [dbo].[Timetable].HSR_id AS [Order],[dbo].[Timetable].Depart_time AS StartTime,[dbo].[Timetable].Arrive_time AS ArriveTime, 
		CONCAT(DATEPART(HOUR,[dbo].[Timetable].Arrive_time)-DATEPART(HOUR,[dbo].[Timetable].Depart_time),':',DATEPART(MINUTE,[dbo].[Timetable].Arrive_time)-DATEPART(MINUTE,[dbo].[Timetable].Depart_time)) AS TotalTime,
		(SELECT [dbo].[StationsBy] ([dbo].[Timetable].HSR_id))AS StationsBy
	FROM [dbo].[Timetable]
	JOIN [dbo].[Station] AS Station1 ON [dbo].[Timetable].Depart_station = Station1.Station_id
	JOIN [dbo].[Station] AS Station2 ON [dbo].[Timetable].Arrive_station = Station2.Station_id
	WHERE Station1.Station_name = @Station1 AND Station2.Station_name = @Station2
		AND (SELECT [dbo].[CheckHSRWork]([dbo].[Timetable].HSR_id,@DepartDate) AS Work)>0
	ORDER BY [dbo].[Timetable].Depart_time ASC
GO
/****** Object:  StoredProcedure [dbo].[Use]    Script Date: 2023/5/2 下午 03:47:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Use] @ID NVARCHAR(60),@Order NVARCHAR(20),@SeatID NVARCHAR(20)
AS
	DECLARE @IDCount INT
	DECLARE @TimetableID NVARCHAR(20)
	DECLARE @Use BIT
	SELECT @IDCount = COUNT(Record_id) FROM [dbo].[Record] WHERE Record_id = @ID AND [Pay] = 1
	SELECT @TimetableID = [dbo].[RecordDetail].Timetable_id FROM [dbo].[RecordDetail]
	JOIN [dbo].[Timetable] ON [dbo].[RecordDetail].Timetable_id = [dbo].[Timetable].Timetable_id
	WHERE Record_id = @ID AND Seat_id = @SeatID AND HSR_id = @Order
	SELECT @Use = [Use] FROM [dbo].[RecordDetail] WHERE Record_id = @ID AND Timetable_id = @TimetableID AND [Take] = 1
	IF(@IDCount>0 AND @Use=0)
		BEGIN
			UPDATE [dbo].[RecordDetail] SET [Use] = 1 WHERE Record_id = @ID AND Timetable_id = @TimetableID AND Seat_id = @SeatID
			SELECT 'True' AS [UseResult]
		END
	ELSE
		BEGIN
			SELECT 'False' AS [UseResult]
		END
GO
USE [master]
GO
ALTER DATABASE [HighSpeedRail] SET  READ_WRITE 
GO
