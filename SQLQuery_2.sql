-- SELECT * FROM dbo.NEW_Products;

-- SELECT UniqueID FROM dbo.NEW_Products;

-- Query1: Standardized SaleDate by removing time
-- SELECT SaleDate, CONVERT(date,SaleDate) as new_SaleDate FROM dbo.NEW_Products;

-- UPDATE NEW_Products
-- Set SaleDate = CONVERT(date,SaleDate) 
-- FROM dbo.NEW_Products;


-- Populate PropertyAddress
-- Null value exists in Property Addresses

SELECT * FROM dbo.NEW_Products
WHERE PropertyAddress is NULL

-- if porperty id has an address and when the same property address doesnt have the
-- address take it from the one that have

SELECT ParcelID,PropertyAddress FROM dbo.NEW_Products
ORDER BY ParcelID

---- Checking purpose
---- Below query shows number of times parcel ID repeats itself
-- SELECT ParcelID, COUNT (*)
-- FROM dbo.NEW_Products
-- GROUP BY ParcelID
-- HAVING COUNT(*) > 3
-- --------
-- Select PropertyAddress 
-- FROM dbo.NEW_Products
-- WHERE ParcelID = '083 15 0 103.00'

-----------------------------------------------------
-- We are using ISNULL function to replace propertyaddress in table a with property address in table b where the value is null
Select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.NEW_Products a
JOIN dbo.NEW_Products b
ON a.ParcelID = b.ParcelID
AND a.UNIQUEID <> b.UNIQUEID
WHERE a.PropertyAddress is null

---UPDATE
UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.NEW_Products a
JOIN dbo.NEW_Products b
ON a.ParcelID = b.ParcelID
AND a.UNIQUEID <> b.UNIQUEID
WHERE a.PropertyAddress is null


---- Breaking out the Address into individual columns (custom spliting)
----- demiminator is comma hai 
SELECT PropertyAddress
FROM dbo.NEW_Products
--- substring looking into propertyaddress at position 1 and taking comma
----- CharIndex will look for comma in propertyaddress . -1 will get rid of the comma
-- SELECT SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)as Address
-- FROM dbo.NEW_Products

SELECT SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))as Address
FROM dbo.NEW_Products

--- make changes in the table 
--- We cant separate two values from each other without showing another two columns 

 ALTER TABLE NEW_Products
 Add PropertySplitAddress Nvarchar(255);

 UPDATE NEW_Products
 SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

 ALTER TABLE NEW_Products
 Add PropertySplitCity NVARCHAR(255);

 UPDATE NEW_Products
 SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))







------ another way to custom split
---- Parsename by default works on period, it works backward

SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
FROM dbo.NEW_Products


ALTER TABLE NEW_Products
 Add OwnerSplitAddress Nvarchar(255);

 UPDATE NEW_Products
 SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)

 ALTER TABLE NEW_Products
 Add OwnerSplitCity NVARCHAR(255);

 UPDATE NEW_Products
 SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

ALTER TABLE NEW_Products
 Add OwnerSplitState Nvarchar(255);

 UPDATE NEW_Products
 SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)

------ CHANGE Y and N in SoldVacant to Yes and No
--- view the number of Y and N
SELECT DISTINCT SoldAsVacant, Count(*)
FROM dbo.NEW_Products
GROUP BY SoldAsVacant
ORDER BY 2
--- Check the query 
Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From dbo.NEW_Products

--- Update the Table

UPDATE NEW_Products
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
--- checking the updated table

SELECT DISTINCT SoldAsVacant, Count(*)
FROM dbo.NEW_Products
GROUP BY SoldAsVacant
ORDER BY 2
--------


---- Dont want to make major changes in the original data 
---- So created a clone table to delete duplicate rows.

SELECT * INTO Nashville_Housing
FROM NEW_Products;

---- Column name displayed to check 
--- you can check under column names too in left hand side
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME ='Nashville_Housing'


SELECT * FROM Nashville_Housing

----- Delete Duplicate rows
-------The ROW_NUMBER() is a window function that assigns a sequential integer number to each row in the query’s result set.
--First, the CTE uses the ROW_NUMBER() function to find the duplicate rows specified by values in the first_name, last_name, and email columns.
----Then, the DELETE statement deletes all the duplicate rows but keeps only one occurrence of each duplicate group.
--- Following query is used to see row_num > 2
Select * FROM (SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
                PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference,
                 Acreage
				 ORDER BY
					UniqueID
					)as row_num

From dbo.Nashville_Housing 
) AS new
WHERE row_num >1

--- Another way of using it by CTE

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference,
                 Acreage
				 ORDER BY
					UniqueID
					) row_num

From dbo.Nashville_Housing
)
Select *
From RowNumCTE
Where row_num > 1
Order BY PropertyAddress


--- Delete duplicates now

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference,
                 Acreage
				 ORDER BY UniqueID
					) row_num

From dbo.Nashville_Housing
)
DELETE
From RowNumCTE
Where row_num > 1
--Order BY PropertyAddress


---- Delete unused Columns
--- owneraddress, propertyaddress, taxdistrict


ALTER TABLE dbo.Nashville_Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

-- checking column names again
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME ='Nashville_Housing'