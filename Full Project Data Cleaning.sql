-- Full Project Data Cleaning !!
SELECT *
FROM layoffs;
-- Data cleainng steps :

-- 1. Remove Duplicates 
-- 2. Standraize the data 
-- 3. NULL values or blank values 
-- 4. Remove any columns or rows that is unnussary

-- First will create another data set that is the same as the original\row data 
-- to protect the row data
-- this will take the columns names 
CREATE TABLE layoffs_staging
LIKE layoffs;
-- check it out 
SELECT *
FROM layoffs_staging;
-- Now copy the columns
INSERT layoffs_staging
SELECT *
FROM layoffs;
-- now check it out 

# 1. Remove duplicates 

WITH duplicate_CTE AS (
SELECT * , 
ROW_NUMBER() OVER(
partition by company,location, industry, total_laid_off, percentage_laid_off,'date', stage,country, funds_raised_millions
) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_CTE
WHERE row_num >1 ;
-- to make sure we took the duplicates lets search a company of the duplicates 
SELECT *
FROM layoffs_staging
WHERE company= 'Akerna';
-- Now delet the duplicates 
-- create table by send to sql editer --> creat statment
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL, 
  `row_num` INT -- this one is new the other created auto
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- now will insert evey duplicate here 
-- copy all the info , here we added row num on the data 
INSERT INTO layoffs_staging2
SELECT * , 
ROW_NUMBER() OVER( -- HERE will go ater each row_num
partition by company,location, industry, total_laid_off, percentage_laid_off,'date', stage,country, funds_raised_millions
) AS row_num
FROM layoffs_staging;

-- Delet now 
DELETE -- INSTAID OF SELECT
FROM layoffs_staging2
WHERE row_num> 1;

-- now make sure it works - put conditions here 
SELECT *
FROM layoffs_staging2
WHERE row_num>1;
-- WHERE row_num> 1; -- WILL BE EMPTY 
-- DONE WITH REMOVING DUPLICATES


# 2. Standrdizing Data
-- find & fix any problem 
-- this is a problen that we find its better trimed(TAKE OFF THE WHITE SPACE)
-- Company row
SELECT company, TRIM(company)
FROM layoffs_staging2;
-- fix it by updating 
UPDATE layoffs_staging2
SET company = TRIM(company);

-- industry row 
-- on the next column we found a problem 
-- we have crypto , crypto currency,  crypto currency--> make them the same lable (i want them to be the same)
SELECT distinct industry -- i want to have uniq values 
FROM layoffs_staging2
ORDER BY 1; -- order by a to z 
-- Now chech where its place 
SELECT distinct industry -- i want to have uniq values 
FROM layoffs_staging2
where industry like 'Crypto%';-- any thing befor the world must show (cryoto currency) 
-- run the code to chech 
SELECT *
FROM layoffs_staging2
where industry like 'Crypto%';
-- now update 
UPDATE layoffs_staging2
SET industry = 'Crypto'
where industry LIKE 'Crypto%';
-- check it out __> it worked 

-- location row - IT SEEMS NICE
SELECT distinct location
FROM layoffs_staging2
ORDER BY 1 ; 
-- country row , we have two united state 
SELECT distinct country
FROM layoffs_staging2
ORDER BY 1 ; 
-- chang it -- THIS IS TESTING
SELECT distinct country, TRIM(TRAILING '.' FROM country) -- This specifies that you want to remove any occurrences of . 
FROM layoffs_staging2
ORDER BY 1;
-- NOW UPDATE 
UPDATE layoffs_staging2
SET country =  TRIM(TRAILING '.' FROM country) 
WHERE country LIKE 'United States%';
-- if we want to later work with the date it has to be changed 
-- look in the schema and then to columns and select it u well see that its text 
-- i want it to be date column 
SELECT `date`,STR_TO_DATE(`date`,'%m/%d/%Y') -- THIS IS BUILD IN FUNCTION THAT WILL CHANGE TEXT TO DATE 
-- BASS THE DATA COLUMN , then this '%m/%d/%Y'  format string that tells MySQL how the date is currently represented in the text column:
FROM layoffs_staging2;
-- i can look on data formating my SQL 
-- now update 
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y')
;
-- it still a text CHNAGE IT TO DATE 
ALTER TABLE layoffs_staging2
modify column `date` DATE; 
-- ITS DATE NOW !!

-- check where are we now + seems nice so will move to next stage 
select *
from layoffs_staging2;

# 3. NULL values or blank values 
-- look for the NULL - THESE TWO ROWS HAVE MANY NULL BY LOOKING 
select *
from layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL ; 

-- LOOK FOR A EMPTY OR NULL VALUES IN INDESTRY	
-- make it null instaid of '' so it will work with us later 
UPDATE layoffs_staging2
set industry= NULL 
WHERE industry='';

SELECT *
from layoffs_staging2
where industry IS NULL 
or industry= ''; 
-- so will look at the companis that are in the null --  where they belong 
SELECT *
from layoffs_staging2
where company = 'Airbnb' ; -- its Travel 
-- will do the join within the tabel
-- this will make the work easier to find the names for the industry 
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company=t2.company
    AND t1.location= t2.location
WHERE (t1.industry IS NULL OR t1.industry='')
AND t2.industry IS NOT NULL; -- will give us two diff answers within the table
-- check each place 
-- Airbnb = Travel
-- 'Bally''s Interactive' = non
-- 'Carvana' = 'Transportation'
-- 'Juul' = 'Consumer'

-- now update 
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company=t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- check now -- bally is still having the null problem because its not having the industry name 
SELECT *
from layoffs_staging2
where industry IS NULL 
or industry= ''; 
-- check the overall results
SELECT *
FROM layoffs_staging2;
-- delete the NULLS that are not important 
-- you HAVE TO BE SURE THAT U WANT TO DELETE THEM
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 
-- now run the table again to check 
# 4. Remove any columns or rows that is unnussary
-- here its the row_num coloum that we created it later 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
-- run it for finall check 
SELECT *
FROM layoffs_staging2;
-- THIS IS IT !! 
