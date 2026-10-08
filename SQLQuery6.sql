-- 1. Ñîçäàåì áàçó äàííûõ
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ShopDB')
BEGIN
    CREATE DATABASE ShopDB;
END
GO

USE ShopDB;
GO

-- Óäàëÿåì òàáëèöû â ïðàâèëüíîì ïîðÿäêå, åñëè îíè óæå åñòü
IF OBJECT_ID('dbo.GameGenres', 'U') IS NOT NULL DROP TABLE dbo.GameGenres;
IF OBJECT_ID('dbo.GameTags', 'U') IS NOT NULL DROP TABLE dbo.GameTags;
IF OBJECT_ID('dbo.UserLibrary', 'U') IS NOT NULL DROP TABLE dbo.UserLibrary;
IF OBJECT_ID('dbo.Reviews', 'U') IS NOT NULL DROP TABLE dbo.Reviews;
IF OBJECT_ID('dbo.UserFriends', 'U') IS NOT NULL DROP TABLE dbo.UserFriends;
IF OBJECT_ID('dbo.UserProfiles', 'U') IS NOT NULL DROP TABLE dbo.UserProfiles;
IF OBJECT_ID('dbo.Purchases', 'U') IS NOT NULL DROP TABLE dbo.Purchases;
IF OBJECT_ID('dbo.Games', 'U') IS NOT NULL DROP TABLE dbo.Games;
IF OBJECT_ID('dbo.Tags', 'U') IS NOT NULL DROP TABLE dbo.Tags;
IF OBJECT_ID('dbo.Genres', 'U') IS NOT NULL DROP TABLE dbo.Genres;
IF OBJECT_ID('dbo.Developers', 'U') IS NOT NULL DROP TABLE dbo.Developers;
IF OBJECT_ID('dbo.Publishers', 'U') IS NOT NULL DROP TABLE dbo.Publishers;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

-- ==========================================
-- 2. ÑÎÇÄÀÍÈÅ ÒÀÁËÈÖ (10+ ñóùíîñòåé)
-- ==========================================

-- 1. Users (Ïîëüçîâàòåëè)
CREATE TABLE dbo.Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Email VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    RegistrationDate DATETIME DEFAULT GETDATE(), -- DEFAULT
    WalletBalance DECIMAL(10,2) DEFAULT 0.00 CHECK (WalletBalance >= 0) -- CHECK
);
GO

-- 2. UserProfiles (Ïðîôèëè ïîëüçîâàòåëåé) - Ñâÿçü 1:1 ñ Users
CREATE TABLE dbo.UserProfiles (
    ProfileID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL UNIQUE, -- UNIQUE îáåñïå÷èâàåò ñâÿçü 1:1
    AvatarURL VARCHAR(255),
    Bio TEXT,
    Country VARCHAR(50) DEFAULT 'Unknown', -- DEFAULT
    CONSTRAINT FK_UserProfiles_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID) ON DELETE CASCADE
);
GO

-- 3. Developers (Ðàçðàáîò÷èêè)
CREATE TABLE dbo.Developers (
    DeveloperID INT IDENTITY(1,1) PRIMARY KEY,
    DeveloperName VARCHAR(100) NOT NULL,
    FoundedYear INT CHECK (FoundedYear > 1900 AND FoundedYear <= 2026) -- CHECK
);
GO

-- 4. Publishers (Èçäàòåëè)
CREATE TABLE dbo.Publishers (
    PublisherID INT IDENTITY(1,1) PRIMARY KEY,
    PublisherName VARCHAR(100) NOT NULL,
    Headquarters VARCHAR(100)
);
GO

-- 5. Genres (Æàíðû)
CREATE TABLE dbo.Genres (
    GenreID INT IDENTITY(1,1) PRIMARY KEY,
    GenreName VARCHAR(50) NOT NULL UNIQUE
);
GO

-- 6. Tags (Òåãè)
CREATE TABLE dbo.Tags (
    TagID INT IDENTITY(1,1) PRIMARY KEY,
    TagName VARCHAR(50) NOT NULL UNIQUE
);
GO

-- 7. Games (Èãðû)
CREATE TABLE dbo.Games (
    GameID INT IDENTITY(1,1) PRIMARY KEY,
    Title VARCHAR(150) NOT NULL,
    Price DECIMAL(10,2) DEFAULT 0.00 CHECK (Price >= 0), -- DEFAULT è CHECK
    ReleaseDate DATE,
    DeveloperID INT NOT NULL,
    PublisherID INT NOT NULL,
    CONSTRAINT FK_Games_Developers FOREIGN KEY (DeveloperID) REFERENCES dbo.Developers(DeveloperID),
    CONSTRAINT FK_Games_Publishers FOREIGN KEY (PublisherID) REFERENCES dbo.Publishers(PublisherID)
);
GO

-- 8. GameGenres (Ñâÿçü M:N ìåæäó Games è Genres)
CREATE TABLE dbo.GameGenres (
    GameID INT NOT NULL,
    GenreID INT NOT NULL,
    PRIMARY KEY (GameID, GenreID),
    CONSTRAINT FK_GameGenres_Games FOREIGN KEY (GameID) REFERENCES dbo.Games(GameID) ON DELETE CASCADE,
    CONSTRAINT FK_GameGenres_Genres FOREIGN KEY (GenreID) REFERENCES dbo.Genres(GenreID) ON DELETE CASCADE
);
GO

-- 9. GameTags (Ñâÿçü M:N ìåæäó Games è Tags)
CREATE TABLE dbo.GameTags (
    GameID INT NOT NULL,
    TagID INT NOT NULL,
    PRIMARY KEY (GameID, TagID),
    CONSTRAINT FK_GameTags_Games FOREIGN KEY (GameID) REFERENCES dbo.Games(GameID) ON DELETE CASCADE,
    CONSTRAINT FK_GameTags_Tags FOREIGN KEY (TagID) REFERENCES dbo.Tags(TagID) ON DELETE CASCADE
);
GO

-- 10. Purchases (Ïîêóïêè)
CREATE TABLE dbo.Purchases (
    PurchaseID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    GameID INT NOT NULL,
    PurchaseDate DATETIME DEFAULT GETDATE(), -- DEFAULT
    AmountPaid DECIMAL(10,2) NOT NULL CHECK (AmountPaid >= 0),
    CONSTRAINT FK_Purchases_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_Purchases_Games FOREIGN KEY (GameID) REFERENCES dbo.Games(GameID)
);
GO

-- 11. UserLibrary (Áèáëèîòåêà èãð ïîëüçîâàòåëÿ - Ñâÿçü M:N)
CREATE TABLE dbo.UserLibrary (
    UserID INT NOT NULL,
    GameID INT NOT NULL,
    HoursPlayed INT DEFAULT 0 CHECK (HoursPlayed >= 0), -- DEFAULT è CHECK
    AddedDate DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (UserID, GameID),
    CONSTRAINT FK_UserLibrary_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_UserLibrary_Games FOREIGN KEY (GameID) REFERENCES dbo.Games(GameID)
);
GO

-- 12. Reviews (Îáçîðû) - Ñâÿçü M:N (Ïîëüçîâàòåëü-Èãðà) ñ äîï. àòðèáóòàìè
CREATE TABLE dbo.Reviews (
    ReviewID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    GameID INT NOT NULL,
    IsRecommended BIT DEFAULT 1, -- DEFAULT
    ReviewText TEXT,
    ReviewDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Reviews_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_Reviews_Games FOREIGN KEY (GameID) REFERENCES dbo.Games(GameID)
);
GO

-- 13. UserFriends (Äðóçüÿ) - Ñâÿçü M:N (Ïîëüçîâàòåëü-Ïîëüçîâàòåëü)
CREATE TABLE dbo.UserFriends (
    UserID INT NOT NULL,
    FriendID INT NOT NULL,
    Status VARCHAR(20) DEFAULT 'Accepted' CHECK (Status IN ('Pending', 'Accepted', 'Blocked')), -- DEFAULT è CHECK
    PRIMARY KEY (UserID, FriendID),
    CONSTRAINT FK_UserFriends_User FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_UserFriends_Friend FOREIGN KEY (FriendID) REFERENCES dbo.Users(UserID),
    CONSTRAINT CHK_NotSelfFriend CHECK (UserID <> FriendID) -- CHECK: íåëüçÿ äîáàâèòü ñåáÿ â äðóçüÿ
);
GO

-- ==========================================
-- 3. ÍÀÏÎËÍÅÍÈÅ ÄÀÍÍÛÌÈ (INSERT)
-- ==========================================

-- Users (5 ñòðîê)
INSERT INTO dbo.Users (Username, Email, PasswordHash, WalletBalance) VALUES
('GamerX', 'gamerx@mail.com', 'hash123', 1500.00),
('ProPlayer', 'pro@mail.com', 'hash456', 500.00),
('NoobMaster', 'noob@mail.com', 'hash789', 0.00),
('SniperKing', 'sniper@mail.com', 'hash101', 250.00),
('RPG_Lover', 'rpg@mail.com', 'hash102', 1000.00);
GO

-- UserProfiles (5 ñòðîê)
INSERT INTO dbo.UserProfiles (UserID, AvatarURL, Bio, Country) VALUES
(1, 'avatar1.jpg', 'Ëþáëþ øóòåðû', 'Russia'),
(2, 'avatar2.jpg', 'Ïðî-èãðîê â Dota 2', 'Ukraine'),
(3, 'avatar3.jpg', 'Íîâè÷îê', 'Belarus'),
(4, 'avatar4.jpg', 'Ñíàéïåð', 'Kazakhstan'),
(5, 'avatar5.jpg', 'Îáîæàþ RPG', 'Russia');
GO

-- Developers (5 ñòðîê)
INSERT INTO dbo.Developers (DeveloperName, FoundedYear) VALUES
('Valve', 1996),
('CD Projekt Red', 2002),
('Rockstar Games', 1998),
('Bethesda', 1986),
('Ubisoft', 1986);
GO

-- Publishers (5 ñòðîê)
INSERT INTO dbo.Publishers (PublisherName, Headquarters) VALUES
('Valve Corporation', 'USA'),
('CD Projekt', 'Poland'),
('Take-Two Interactive', 'USA'),
('Bethesda Softworks', 'USA'),
('Ubisoft Publishing', 'France');
GO

-- Genres (5 ñòðîê)
INSERT INTO dbo.Genres (GenreName) VALUES
('Action'), ('RPG'), ('Shooter'), ('Strategy'), ('Adventure');
GO

-- Tags (5 ñòðîê)
INSERT INTO dbo.Tags (TagName) VALUES
('Multiplayer'), ('Singleplayer'), ('Open World'), ('Co-op'), ('PvP');
GO

-- Games (5 ñòðîê)
INSERT INTO dbo.Games (Title, Price, ReleaseDate, DeveloperID, PublisherID) VALUES
('Counter-Strike 2', 0.00, '2023-09-27', 1, 1),
('The Witcher 3', 1999.00, '2015-05-19', 2, 2),
('GTA V', 2999.00, '2013-09-17', 3, 3),
('Skyrim', 1500.00, '2011-11-11', 4, 4),
('Assassin''s Creed Valhalla', 2500.00, '2020-11-10', 5, 5);
GO

-- GameGenres (M:N ñâÿçè)
INSERT INTO dbo.GameGenres (GameID, GenreID) VALUES
(1, 3), (1, 1), -- CS2: Shooter, Action
(2, 2), (2, 5), -- Witcher: RPG, Adventure
(3, 1), (3, 5), -- GTA V: Action, Adventure
(4, 2),         -- Skyrim: RPG
(5, 1), (5, 2); -- AC Valhalla: Action, RPG
GO

-- GameTags (M:N ñâÿçè)
INSERT INTO dbo.GameTags (GameID, TagID) VALUES
(1, 1), (1, 5), -- CS2: Multiplayer, PvP
(2, 2), (2, 3), -- Witcher: Singleplayer, Open World
(3, 1), (3, 3), -- GTA V: Multiplayer, Open World
(4, 2), (4, 3), -- Skyrim: Singleplayer, Open World
(5, 2), (5, 4); -- AC: Singleplayer, Co-op
GO

-- Purchases (5 ñòðîê)
INSERT INTO dbo.Purchases (UserID, GameID, AmountPaid) VALUES
(1, 1, 0.00),
(1, 2, 1999.00),
(2, 3, 2999.00),
(4, 4, 1500.00),
(5, 5, 2500.00);
GO

-- UserLibrary (5 ñòðîê)
INSERT INTO dbo.UserLibrary (UserID, GameID, HoursPlayed) VALUES
(1, 1, 500),
(1, 2, 120),
(2, 3, 300),
(4, 4, 80),
(5, 5, 45);
GO

INSERT INTO dbo.Reviews (UserID, GameID, IsRecommended, ReviewText) VALUES
(1, 1, 1, 'Ëó÷øèé øóòåð!'),
(1, 2, 1, 'Øåäåâð.'),
(2, 3, 0, 'Îíëàéí ñëîìàí.'),
(4, 4, 1, 'Êëàññèêà RPG.'),
(5, 5, 1, 'Íåïëîõî, íî çàòÿíóòî.');
GO

-- UserFriends (5 ñòðîê)
INSERT INTO dbo.UserFriends (UserID, FriendID, Status) VALUES
(1, 2, 'Accepted'),
(2, 1, 'Accepted'),
(1, 3, 'Pending'),
(4, 5, 'Accepted'),
(3, 4, 'Blocked');
GO

-- ==========================================
-- 4. SELECT ÇÀÏÐÎÑÛ ÄËß ÏÐÎÑÌÎÒÐÀ
-- ==========================================

-- 1. Âñå ïîëüçîâàòåëè è èõ ïðîôèëè (JOIN 1:1)
SELECT u.Username, u.Email, p.Country, p.Bio
FROM dbo.Users u
JOIN dbo.UserProfiles p ON u.UserID = p.UserID;
GO


SELECT g.Title, d.DeveloperName, p.PublisherName, g.Price
FROM dbo.Games g
JOIN dbo.Developers d ON g.DeveloperID = d.DeveloperID
JOIN dbo.Publishers p ON g.PublisherID = p.PublisherID;
GO


SELECT g.Title, string_agg(gen.GenreName, ', ') AS Genres
FROM dbo.Games g
JOIN dbo.GameGenres gg ON g.GameID = gg.GameID
JOIN dbo.Genres gen ON gg.GenreID = gen.GenreID
GROUP BY g.Title;
GO


SELECT u.Username, g.Title, ul.HoursPlayed
FROM dbo.Users u
JOIN dbo.UserLibrary ul ON u.UserID = ul.UserID
JOIN dbo.Games g ON ul.GameID = g.GameID
WHERE u.Username = 'GamerX';
GO

-- 
SELECT u.Username, g.Title, r.IsRecommended, r.ReviewText
FROM dbo.Reviews r
JOIN dbo.Users u ON r.UserID = u.UserID
JOIN dbo.Games g ON r.GameID = g.GameID;
GO