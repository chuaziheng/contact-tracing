--------------------------------- MAIN TABLES ---------------------------------
-- Table 5: User 
CREATE TABLE Users (
	id_users INT,
	email VARCHAR(50), 
	users_name VARCHAR(50),
	sex CHAR(1),
	birthday date,
	hometown VARCHAR(50),
	phone_number INT,
	id_company INT,
	PRIMARY KEY (id_users)
);

-- Table 3: ContactPerson
CREATE TABLE ContactPerson (
	id_users INT,
	PRIMARY KEY (id_users),
	CONSTRAINT FK__contactPerson__users FOREIGN KEY (id_users) REFERENCES Users(id_users) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Table 4: Admin 
CREATE TABLE Admins (
	id_users INT,
	PRIMARY KEY (id_users),
	CONSTRAINT FK__admins__users FOREIGN KEY (id_users) REFERENCES Users(id_users) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Table 1: Company 
CREATE TABLE Company(
	id_company INT,
	mailing_address VARCHAR (100),
	contact_email VARCHAR (100),
	id_contact_person INT,
	PRIMARY KEY (id_company),
	CONSTRAINT FK__company__contactPerson FOREIGN KEY (id_contact_person) REFERENCES ContactPerson(id_users) ON DELETE SET NULL
);


--table 15: Location 

CREATE TABLE Locations (
	id_location INT ,
	location_address VARCHAR(100),
	location_name VARCHAR(50) NOT NULL,
	location_description VARCHAR(300),
	location_company INT,
	x DECIMAL(10,6),
	y DECIMAL(10,6),
	PRIMARY KEY (id_location)
);

-- Table 2: Associate 
CREATE TABLE Associate(
	id_company INT ,
	id_location INT , 
	PRIMARY KEY(id_company, id_location),
	CONSTRAINT FK__associate__company FOREIGN KEY (id_company) REFERENCES Company(id_company) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT FK__associate__locations FOREIGN KEY (id_location) REFERENCES Locations(id_location) ON UPDATE CASCADE ON DELETE CASCADE
);


-- Table 6: BeFamily 
CREATE TABLE BeFamily (
	id_user1 INT ,
	id_user2 INT ,
	relationship VARCHAR(50) NOT NULL,
	PRIMARY KEY (id_user1, id_user2),
	CONSTRAINT FK__beFamily__users1 FOREIGN KEY (id_user1) REFERENCES Users(id_users),
	CONSTRAINT FK__beFamily__users2 FOREIGN KEY (id_user2) REFERENCES Users(id_users),
);

-- (TRIGGER) To delete BeFamily records (cannot ON DELETE CASCADE Msg 1785 - may cause cycles or multiple cascade paths)
GO
CREATE TRIGGER del_user 
	ON Users
	INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;
	DELETE FROM BeFamily WHERE id_user1 IN (SELECT id_users FROM DELETED)
	DELETE FROM BeFamily WHERE id_user2 IN (SELECT id_users FROM DELETED)
	DELETE FROM Users WHERE id_users IN (SELECT id_users FROM DELETED)
END

--Table 7: Coordinate  
CREATE TABLE Coordinate (
	time_stamp datetime,
	x DECIMAL(10,6) NOT NULL ,
	y DECIMAL(10,6) NOT NULL ,
	id_users INT ,
	PRIMARY KEY (time_stamp, id_users),
	CONSTRAINT FK__coordinate__users FOREIGN KEY (id_users) REFERENCES Users(id_users) ON DELETE CASCADE
);

-- Table 8: Schedule
CREATE TABLE Schedule (
	schedule_time datetime,
	clinic_id INT,
	test_result VARCHAR(50),
	id_users INT ,
	PRIMARY KEY(schedule_time, id_users),
	CONSTRAINT FK__clinic__locations FOREIGN KEY (clinic_id) REFERENCES Locations(id_location) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT FK__schedule__users FOREIGN KEY (id_users) REFERENCES Users(id_users) ON DELETE CASCADE
);

-- Table 9: Temperature
CREATE TABLE Temperature (
	time_stamp datetime,
	temperature DECIMAL(6,3) NOT NULL,
	id_users INT ,
	PRIMARY KEY(time_stamp, id_users),
	CONSTRAINT FK__temperature__users FOREIGN KEY (id_users) REFERENCES Users(id_users) ON DELETE CASCADE
);

-- Table 10: Category
CREATE TABLE Category(
	category_name VARCHAR(50),
	PRIMARY KEY (category_name)
);

--Table 11: Contain 
CREATE TABLE Contain (
	parent_name VARCHAR(50),
	child_name VARCHAR(50),
	PRIMARY KEY(parent_name, child_name),
	CONSTRAINT FK__contain__category1 FOREIGN KEY (parent_name) REFERENCES Category(category_name),
	CONSTRAINT FK__contain__category2 FOREIGN KEY (child_name) REFERENCES Category(category_name),
);
-- (TRIGGER) Deletes Contain records  (cannot ON DELETE CASCADE Msg 1785 - may cause cycles or multiple cascade paths)
GO
CREATE TRIGGER del_category 
	ON Category
	INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;
	DELETE FROM Contain WHERE parent_name IN (SELECT category_name FROM DELETED)
	DELETE FROM Contain WHERE child_name IN (SELECT category_name FROM DELETED)
	DELETE FROM Category WHERE category_name IN (SELECT category_name FROM DELETED)
END

--Table 12: Has 
CREATE TABLE Has(
	id_location  INT ,
	category_name VARCHAR(50),
	PRIMARY KEY(id_location, category_name),
	CONSTRAINT FK__has__locations FOREIGN KEY (id_location) REFERENCES Locations(id_location) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT FK__has__category FOREIGN KEY (category_name) REFERENCES Category(category_name) ON UPDATE CASCADE ON DELETE CASCADE,
);
--Table 13: Check-in-out

CREATE TABLE CheckInOut (
	checkin_time datetime ,
	checkout_time datetime,
	id_users INT ,
	id_location INT ,
	PRIMARY KEY(id_location, checkin_time , id_users),
	CONSTRAINT FK__checkinout__users FOREIGN KEY (id_users) REFERENCES Users(id_users) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT FK__checkinout__location FOREIGN KEY (id_location) REFERENCES Locations(id_location)ON UPDATE CASCADE ON DELETE CASCADE
);

ALTER TABLE CheckInOut
ADD CONSTRAINT checkin_bef_checkout
CHECK ((checkout_time IS NULL) OR (checkin_time < checkout_time AND checkout_time IS NOT NULL))

--Table 14: Rating

CREATE TABLE Rating (
	checkout_time datetime ,
	id_users INT ,
	id_location INT ,
	rate INT CHECK (rate BETWEEN 1 AND 5),
	PRIMARY KEY(id_users, id_location, checkout_time),
	CONSTRAINT FK__rating__users FOREIGN KEY (id_users) REFERENCES Users(id_users)ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT FK__rating__locations FOREIGN KEY (id_location) REFERENCES Locations(id_location)ON UPDATE CASCADE ON DELETE CASCADE,
);

-- (TRIGGER)  Validate Ratings: Users can only rate during check-out at the location 
CREATE TRIGGER validateRating
	ON Rating
	INSTEAD OF INSERT
	AS
DECLARE @latest_checkout AS datetime = (SELECT TOP 1 C.checkout_time FROM CheckInOut as C, INSERTED as i
											where i.id_location = C.id_location  AND i.id_users = C.id_users 
											ORDER BY checkout_time DESC)
IF @latest_checkout IS NOT NULL
BEGIN
	SET NOCOUNT ON;
	IF (SELECT i.checkout_time FROM INSERTED AS i) = @latest_checkout
		INSERT INTO Rating (i.checkout_time, id_users, id_location, rate)
		SELECT * FROM INSERTED as i
	ELSE
		PRINT('Your rating window has expired.')
END
ELSE 
	PRINT('Not authorised to rate. Only can rate during checkout at this location.')

--table 16: Message 

CREATE TABLE MessageText (
	id_message INT ,
	time_stamp datetime,
	message_text VARCHAR(300) NOT NULL,
	id_location INT ,
	id_users INT ,
	PRIMARY KEY (id_message),
	CONSTRAINT FK__messageText__locations FOREIGN KEY (id_location) REFERENCES Locations(id_location) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT FK__messageText__users FOREIGN KEY (id_users) REFERENCES Users(id_users) ON UPDATE CASCADE ON DELETE CASCADE
);

-- (TRIGGER) Validate Message: Only contact persons of the location's company and all admins can write a message about the location
CREATE TRIGGER validateMessageAuthor
	ON MessageText
	INSTEAD OF INSERT
	AS
IF (SELECT id_users FROM INSERTED) IN ((SELECT DISTINCT id_contact_person FROM INSERTED AS i, Locations as L, Company as C
	WHERE L.id_location = i.id_location AND L.location_company = C.id_company) UNION (SELECT * FROM Admins))
BEGIN
	SET NOCOUNT ON;
	INSERT INTO MessageText (id_message, time_stamp, message_text, id_location, id_users)
	SELECT * FROM INSERTED as i
END
ELSE 
	PRINT('Not authorised to add message. You are not contact person or admin.')

--table 17: Comment 

CREATE TABLE Comment (
	id_message INT,
	id_users INT ,
	time_stamp datetime,
	comment_text VARCHAR(300) NOT NULL,
	PRIMARY KEY (id_message,id_users),
	CONSTRAINT FK__comment__messageText FOREIGN KEY (id_message) REFERENCES MessageText(id_message) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT FK__comment__users FOREIGN KEY (id_users) REFERENCES Users(id_users) ON DELETE NO ACTION
);

-- (FUNCTION) Returns respective message's timestamp given a comment
CREATE FUNCTION myFunction (
 @comment_id_message integer
)
RETURNS datetime
AS
BEGIN
    return(select time_stamp FROM MessageText as m
  where @comment_id_message = m.id_message)
END

ALTER TABLE Comment
ADD CONSTRAINT comment_after_message
CHECK (time_stamp >= [dbo].[myFunction](id_message))


----------------------------------------- ADDITIONAL QUERY TABLES ----------------------------------------

-- Store contact person details of companies of locations that violate max capacity
CREATE TABLE notifyOvercapacity(
	id_location int,
	contact_email VARCHAR(100),
	id_contact_person int,
	checkin_time datetime
)

-- Maximum location Capacity of each parent location category
CREATE TABLE maxLocCapacity(
	category_name VARCHAR(50) ,
	max_capacity INT NOT NULL,
	PRIMARY KEY (category_name),
)

INSERT INTO maxLocCapacity VALUES ('Company', 10)
INSERT INTO maxLocCapacity VALUES ('Education', 5)
INSERT INTO maxLocCapacity VALUES ('Entertainment', 8)
INSERT INTO maxLocCapacity VALUES ('Health', 9)
INSERT INTO maxLocCapacity VALUES ('Retail', 5)
