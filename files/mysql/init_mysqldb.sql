--  Delete ALL users who are not root
delete from mysql.user where not (host="localhost" and user="root");

-- Change root database admin password: (note: once this step is complete you’ll need to login with: mysql -p -u root) 
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('mypass');

-- Change root username to something less guessable for higher security.
update mysql.user set user="mydbadmin" where user="root";

-- Remove anonymous access to the database(s):
DELETE FROM mysql.user WHERE User = '';

-- Add a new user with database admin privs for all databases:
GRANT ALL PRIVILEGES ON *.* TO 'warren'@'localhost' IDENTIFIED BY 'mypass' WITH GRANT OPTION;

FLUSH PRIVILEGES;
