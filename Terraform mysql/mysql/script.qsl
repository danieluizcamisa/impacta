CREATE USER IF NOT EXISTS 'mbas02'@'%' IDENTIFIED BY 'mbas02p1$sw4rd';

GRANT ALL PRIVILEGES ON mbas02.* TO 'mbas02'@'%' IDENTIFIED BY 'mbas02p1$sw4rd';

CREATE DATABASE IF NOT EXISTS mbas02;
ALTER DATABASE mbas02 DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

USE mbas02;
CREATE TABLE infra_and_cloud (id INT NOT NULL, name VARCHAR(50) NOT NULL, course VARCHAR(100) NOT NULL, discipline VARCHAR(100) NOT NULL,PRIMARY KEY (id));
INSERT INTO infra_and_cloud (id,name,course,discipline) VALUES(1,'Alexandre Martins','AS02','Infrastructure and Cloud Architecture');
