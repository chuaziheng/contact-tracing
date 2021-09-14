# contact-tracing-database

Contact Tracing is a database coursework project that serves to record users' temperature and location data, as well as the scheduling of swab test slots for those who
are in high risks. This project includes database design (ER Diagram and Database Normalisations) and implementation of queries using ``` SQL Server ``` . The database is populated using dummy data to preserve confidentiality.

The following are the queries to be implemented:

1. Find the locations that receive at least 5 ratings of “5” in Dec 2020, and order them by
their average ratings.
2. Find the companies whose posts have received the most number of comments for each
week of the past month.
3. Find the users who have checked in more than 10 locations every day in the last week.
4. Find all the couples such that each couple has checked in at least 2 common locations
on 1 Jan 2021.
5. Find 5 locations ids and their names that are checked in by the most number of users in
the last 10 days.
6. Given a user, find the list of uses that checked in the same locations with the user within 1
hour in the last week

And the following are the interesting additional queries that my team constructed and implemented using Triggers:
1. Automatically schedule a covid test when a user's temperature record goes above 37.5 and update test result. If test result positive, automatically schedule test timeslots for family members
2. When a user check-in, call trigger to check if Location has reached maxCapacity for its respective location category (specifed in the maxLocCapacity table).
	Query and record contact_email and contact_person of the Company of these locations that have violated the max capacity limit
	and subsequently give them a warning. 
