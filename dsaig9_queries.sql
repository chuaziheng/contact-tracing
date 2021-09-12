-- QUERY 1 

WITH highRatings AS
(
SELECT id_location
FROM Rating
WHERE rate = 5 AND checkout_time>= '2020-12-01 00:00:00' AND checkout_time<= '2020-12-31 23:59:59'
GROUP BY id_location
HAVING COUNT(*) >= 5
)

SELECT Rating.id_location, ROUND(AVG(CAST(rate AS FLOAT)), 2) AS avg_rate
FROM Rating
INNER JOIN highRatings
ON Rating.id_location = highRatings.id_location
GROUP BY Rating.id_location
ORDER BY avg_rate DESC;


-- QUERY 2

(select location_company
from Locations as l, MessageText as m,
(select top 1 id_message, count(*) as no_of_comment
from Comment
where time_stamp between dateadd(week, -4 , getdate()) and dateadd(week, -3 , getdate())
group by id_message
order by no_of_comment desc) as c
where c.id_message = m.id_message and m.id_location = l.id_location)

union

(select location_company
from Locations as l, MessageText as m,
(select top 1 id_message, count(*) as no_of_comment
from Comment
where time_stamp between dateadd(week, -3 , getdate()) and dateadd(week, -2 , getdate())
group by id_message
order by no_of_comment desc) as c
where c.id_message = m.id_message and m.id_location = l.id_location)

union

(select location_company
from Locations as l, MessageText as m,
(select top 1 id_message, count(*) as no_of_comment
from Comment
where time_stamp between dateadd(week, -2 , getdate()) and dateadd(week, -1 , getdate())
group by id_message
order by no_of_comment desc) as c
where c.id_message = m.id_message and m.id_location = l.id_location)

union

(select location_company
from Locations as l, MessageText as m,
(select top 1 id_message, count(*) as no_of_comment
from Comment
where time_stamp between dateadd(week, -1 , getdate()) and getdate()group by id_message
order by no_of_comment desc) as c
where c.id_message = m.id_message and m.id_location = l.id_location)



-- QUERY 3 
-- Declaration: "last week" means 7 days before current day (excluding)

CREATE FUNCTION GenerateDateRange
  (@StartDate AS DATE,
   @EndDate AS   DATE,
   @Interval AS  INT
  )
  RETURNS @Dates TABLE(DateValue DATE)
  AS
  BEGIN
    DECLARE @CUR_DATE DATE
    SET @CUR_DATE = @StartDate
    WHILE @CUR_DATE <= @EndDate BEGIN
      INSERT INTO @Dates VALUES(@CUR_DATE)
      SET @CUR_DATE = DATEADD(DAY, @Interval, @CUR_DATE)
    END
    RETURN;
  END;

  WITH userDailyLocCount AS
  (
  SELECT id_users , CONVERT(VARCHAR(10),checkin_time, 23)AS checkinDay , COUNT(DISTINCT id_location) AS dailyLocCount
  FROM CheckInOut
  WHERE checkin_time <= DATEADD(DAY,-1,GETDATE()) AND checkin_time >= DATEADD(week, -1,  DATEADD(DAY,-1,GETDATE())) 
  GROUP BY id_users,CONVERT(VARCHAR(10),checkin_time, 23)
  HAVING COUNT(DISTINCT id_location) > 10
  )

  SELECT id_users
  FROM userDailyLocCount
  GROUP BY id_users
  HAVING COUNT(DISTINCT checkinDay) = ( 
                    SELECT COUNT(*)
                    FROM GenerateDateRange(DATEADD(week, -1,  GETDATE()), DATEADD(DAY,-1,GETDATE()),1)
                    );  

-- QUERY 4 

WITH Couple AS
(   SELECT id_user1, id_user2 
    FROM BeFamily
    WHERE relationship = 'Husband' OR relationship = 'Wife'
) 
SELECT DISTINCT checkin1.id_users as User1, checkin2.id_users as User2 --, checkin1.id_location
    FROM CheckInout as checkin1 , CheckInout as checkin2
    WHERE checkin1.checkin_time BETWEEN '2021-01-01' AND '2021-01-01 23:59:59'
        AND checkin2.checkin_time BETWEEN '2021-01-01' AND '2021-01-01 23:59:59'
        AND checkin1.id_location = checkin2.id_location 
        AND EXISTS (
            SELECT Couple.id_user1, Couple.id_user2
            FROM Couple
            WHERE checkin1.id_users = Couple.id_user1 AND checkin2.id_users = Couple.id_user2
      )
    GROUP BY checkin1.id_users, checkin2.id_users
    HAVING COUNT(DISTINCT checkin1.id_location) > 1;


-- QUERY 5

select l.id_location, l.location_name
from Locations as l,
(select top 5 id_location, count(*) as no_of_users
from CheckInOut
WHERE checkin_time BETWEEN DATEADD(DAY, -10,  DATEADD(DAY,-1,GETDATE())) AND DATEADD(DAY,-1,GETDATE())
group by id_location
order by no_of_users desc) as c
where c.id_location = l.id_location

-- QUERY 6

DECLARE @USERS_ID AS INT
SET @USERS_ID = 4;
WITH userLocations AS
(
SELECT id_location, checkin_time  
FROM CheckInOut
WHERE id_users = @USERS_ID AND checkin_time BETWEEN DATEADD(week, -1, DATEADD(DAY,-1,GETDATE())) AND DATEADD(DAY,-1,GETDATE()) 
)

SELECT DISTINCT C.id_users
FROM CheckInOut as C, userLocations as U
WHERE C.id_location = U.id_location AND C.checkin_time BETWEEN DATEADD(hour, -1, U.checkin_time) AND DATEADD(hour, 1, U.checkin_time) AND C.id_users <> @USERS_ID;

------------------------------------------------ ADDITIONAL QUERIES ----------------------------------------------------

/* ADDITIONAL QUERY 1: 
    The tuples in the Temperature table are inserted when users take their temperature. 
    If the temperature of a user > 37.5, an automatic schedule (covid test) is generated for him 8 hours after his temp is taken
    After the test, his test_result is updated. If the test result is Positive, an automatic schedule is generated for his family members
    The generated schedule for the family members is returned. 
*/

-- (TRIGGER) To create schedule for 1 user if his temp > 37.5
CREATE TRIGGER Fever ON Temperature
AFTER INSERT
AS
IF (SELECT temperature FROM INSERTED) > 37.5
    BEGIN 
        -- to get random clinic id
        WITH random AS
        (
          SELECT TOP 1 id_location FROM Has
          WHERE category_name = 'Clinic'
          ORDER BY NEWID()
        )
        INSERT INTO Schedule (schedule_time, clinic_id, id_users)
        SELECT 
        DATEADD(hour, 8, i.time_stamp), random.id_location, i.id_users
        FROM inserted as i, random
END; 

-- (TRIGGER) If user above has positive test result for covid, schedule covid test for his family members
CREATE TRIGGER Positive ON Schedule 
AFTER UPDATE 
AS
IF (SELECT test_result from INSERTED) = 'Positive'
  BEGIN 
      DECLARE @FromDate DATETIME2(0)
      DECLARE @ToDate   DATETIME2(0)
      SET @FromDate = '2021-03-15 08:30:00' 
      SET @ToDate = '2021-03-20 18:30:00'
      DECLARE @Seconds INT = DATEDIFF(SECOND, @FromDate, @ToDate)
      DECLARE @Random INT = ROUND(((@Seconds-1) * RAND()), 0); 

    WITH members (member) AS (
      (SELECT B.id_user1 as member
      FROM BeFamily as B, inserted as i 
      WHERE i.id_users = B.id_user2) 
      UNION
      (SELECT B.id_user2 as member
      FROM BeFamily as B, inserted as i 
      WHERE i.id_users = B.id_user1)
      ),

      random AS
        (
          SELECT TOP 1 id_location, DATEADD(SECOND, @Random, @FromDate) as rand_time
          FROM Has
          WHERE category_name = 'Clinic'
          ORDER BY NEWID()
        )
        INSERT INTO Schedule (schedule_time, clinic_id, id_users)
        SELECT 
        random.rand_time, random.id_location, members.member
        FROM members, random; 

        SELECT * FROM Schedule
        WHERE test_result IS NULL
END; 

-- TESTING ADDITIONAL QUERY 1 --

-- To trigger FEVER 
  -- change the userid when you want to rerun this insert statement ** do not change the time
INSERT INTO Temperature VALUES ('2021-03-05 10:00:00', 37.9, 2);

SELECT * FROM Schedule
WHERE test_result IS NULL

-- To trigger POSITIVE updating user's covid test results 
  -- change the userid to same as the userid above 
UPDATE Schedule 
SET test_result = 'Positive'
WHERE id_users = 2 AND schedule_time = '2021-03-05 18:00:00'


/* ADDITIONAL QUERY 2: 
	When a user check-in, call trigger to check if Location has reached maxCapacity for its respective location category (specifed in the maxLocCapacity table).
	Query and record contact_email and contact_person of the Company of these locations that have violated the max capacity limit
	and subsequently give them a warning.  
*/

CREATE FUNCTION currentCrowd (
  @id_location integer
)
RETURNS int
AS
BEGIN
    return(SELECT COUNT(*) AS curUsers 
	FROM CheckInOut AS C
	WHERE GETDATE()  >=  C.checkin_time 
	AND C.checkout_time IS NULL 
	AND C.id_location = @id_location)
END

CREATE FUNCTION maxCapacity (
  @id_location integer
)
RETURNS int
AS
BEGIN
    return(SELECT max_capacity FROM Contain
			INNER JOIN Has
			ON Contain.child_name = Has.category_name
			INNER JOIN maxLocCapacity as M
			ON Contain.parent_name = M.category_name
			WHERE id_location = @id_location)
END


CREATE TRIGGER notify_overcapacity 
ON CheckInOut
AFTER INSERT
AS
IF [dbo].[currentCrowd]((SELECT id_location FROM inserted)) > [dbo].[maxCapacity]((SELECT id_location FROM inserted))
													
BEGIN 
        WITH CompanyContacts AS(
		SELECT Company.contact_email , Company.id_contact_person, INSERTED.id_location  FROM Locations ,Company, INSERTED 
		WHERE Locations.id_location = INSERTED.id_location AND Locations.location_company = Company.id_company )
		INSERT INTO notifyOvercapacity (id_location, CompanyContacts.contact_email , CompanyContacts.id_contact_person, checkin_time)
		SELECT i.id_location , CompanyContacts.contact_email , CompanyContacts.id_contact_person , i.checkin_time FROM INSERTED as i, CompanyContacts
	
END; 

-- TEST ADDITIONAL QUERY 2 --

-- Currently, there are 4 pax at Location 600000, which is NTU and falls under Education
SELECT * FROM CheckInOut
WHERE  checkout_time IS NULL AND id_location = 600000

-- 1 more person checks-in, total 5, which is just nice the max capacity, thus able to successfully check-in
INSERT INTO CheckInOut VALUES ('2021-04-05', NULL, 15, 600000)

--1 more person checks-in, now total is 6, which is over the capacity for Education which is 5, trigger condition satisfied
INSERT INTO CheckInOut VALUES ('2021-04-05', NULL, 16, 600000)

--Check notifyOvercapacity for the newly inserted tuple
SELECT * FROM notifyOvercapacity

between dateadd(week, -4 , getdate()) and dateadd(week, -3 , getdate()) 
between dateadd(week, -3 , getdate()) and dateadd(week, -2 , getdate()) 
between dateadd(week, -2 , getdate()) and dateadd(week, -1 , getdate()) 
between dateadd(week, -1 , getdate()) and getdate()

select dateadd(week, -4 , getdate()) , dateadd(week, -3 , getdate())

(select location_company
from Locations as l, MessageText as m,
(select top 1 id_message, count(*) as no_of_comment
from Comment
where time_stamp between dateadd(week, -4 , getdate()) and dateadd(week, -3 , getdate())
group by id_message
order by no_of_comment desc) as c
where c.id_message = m.id_message and m.id_location = l.id_location)

union

(select location_company
from Locations as l, MessageText as m,
(select top 1 id_message, count(*) as no_of_comment
from Comment
where time_stamp between dateadd(week, -3 , getdate()) and dateadd(week, -2 , getdate())
group by id_message
order by no_of_comment desc) as c
where c.id_message = m.id_message and m.id_location = l.id_location)

union

(select location_company
from Locations as l, MessageText as m,
(select top 1 id_message, count(*) as no_of_comment
from Comment
where time_stamp between dateadd(week, -2 , getdate()) and dateadd(week, -1 , getdate())
group by id_message
order by no_of_comment desc) as c
where c.id_message = m.id_message and m.id_location = l.id_location)

union

(select location_company
from Locations as l, MessageText as m,
(select top 1 id_message, count(*) as no_of_comment
from Comment
where time_stamp between dateadd(week, -1 , getdate()) and getdate()group by id_message
order by no_of_comment desc) as c
where c.id_message = m.id_message and m.id_location = l.id_location)