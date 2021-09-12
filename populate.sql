-- Users
INSERT INTO Users VALUES (1, 'adam@gmail.com', 'adam123', 'M', '20120618','SG', 91234567, 100);
INSERT INTO Users VALUES (2, 'betty@gmail.com', 'betty123', 'F', '20000118','SG', 91345748, 100);
INSERT INTO Users VALUES (3, 'carol@gmail.com', 'carol123', 'F', '19970618','MY', 91038493, 101);
INSERT INTO Users VALUES (4, 'derek@gmail.com', 'derek123', 'M', '19960618','ID', 91018493, 102);
INSERT INTO Users VALUES (5, 'admin@gmail.com', 'iamadmin', 'M', '19900618','ID', 91018493, 103);
INSERT INTO Users VALUES (6, 'ester@gmail.com', 'ester123', 'F', '19930618','ID', 91018433, 103);


--ContactPerson
INSERT INTO ContactPerson VALUES (2);
INSERT INTO ContactPerson VALUES (3);
INSERT INTO ContactPerson VALUES (4);
INSERT INTO ContactPerson VALUES (6);

--Admin 
INSERT INTO Admins VALUES (5);

-- Company
INSERT INTO Company VALUES (100, 'Orchard Ave', 'google@gmail.com', 2);
INSERT INTO Company VALUES (101, 'Changi Ave', 'facebook@gmail.com', 3);
INSERT INTO Company VALUES (102, 'Woodlands Ave', 'apple@gmail.com', 4);
INSERT INTO Company VALUES (103, 'Sentosa Ave', 'govtech@gmail.com', 5);

--ALTER TABLE TO ADD CONSTRAINT
ALTER TABLE Users
ADD CONSTRAINT FK__users__company
FOREIGN KEY(id_company)
REFERENCES Company(id_company)
ON DELETE SET NULL;

--Locations
INSERT INTO Locations VALUES (600000,'Nanyang Ave','NTU','Sg best university',1.000001,100.000001);
INSERT INTO Locations VALUES (600001,'Jurong Ave','Jurong Point','Sg best mall',1.000002,100.000002);
INSERT INTO Locations VALUES (600002,'Orchard Ave','Ion','x',1.000003,100.000003);
INSERT INTO Locations VALUES (600003,'Orchard Ave','Google','x',1.000003,100.000003);
INSERT INTO Locations VALUES (600004,'Changi Ave','Facebook','x',1.000004,100.000004);
INSERT INTO Locations VALUES (600005,'Woodlands Ave','Apple','x',1.000005,100.000005);


-- Associate
INSERT INTO Associate VALUES (100, 600005); 
INSERT INTO Associate VALUES (101, 600003); 
INSERT INTO Associate VALUES (102, 600004); 

-- BeFamily


--DELETE FROM Users WHERE id_users = 10;



