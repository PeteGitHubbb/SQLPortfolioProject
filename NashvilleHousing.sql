-- Dec 28th 2023
-- Nashville Housing Data for Data Cleaning
/*
cleaning data in SQL Queries
*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

-- Standardize Date Format 
-- (this step was not really usefull because it already converted to Date format when importing data using the extension)
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

--------------------------------
ALTER TABLE NashvilleHousing
SET SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)


-- Populate Property Address date
-- so if two different liunes has the same ParcelID but one has a PropertyAddress and the other does not populate the two to have
-- the same PropertyAddress.

-- these are the ones has ParcelID but null as PropertyAddress
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress is NULL
order by ParcelID
------------------------------------------

-- now try to populate the ones without a PropertyAddress
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) -- this is what will be stuck in the null column (a.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b 
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL


-- now make the modification (populate the null with values)
UPDATE a 
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a 
JOIN PortfolioProject.dbo.NashvilleHousing b 
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL


-- Breaking out Address into Individual column (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address
FROM PortfolioProject..NashvilleHousing
-- now the same thing just getting rid of the comma
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address 
FROM PortfolioProject..NashvilleHousing
-- getting everything before comma as address1 and after as address2
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address1
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address2
FROM PortfolioProject..NashvilleHousing
----------------------------------

ALTER TABLE NashvilleHousing
add PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)
--
ALTER TABLE NashvilleHousing
add PropertySplitCity NVARCHAR(225);

UPDATE NashvilleHousing
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject..NashvilleHousing -- the last two columns on the table
----------------------------------------------------------------------------

-- doing the above for OwnerAddress in a different way
-- look at the address first
SELECT OwnerAddress
from PortfolioProject..NashvilleHousing
-- now do the thing:
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as address1,  -- need to use replace because parsename only works with period (so change to comma before using it).
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as address2,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as address3
FROM PortfolioProject..NashvilleHousing
-- we can also do the same thing using substings like above for dealing with PropertyAddress. 
-------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field
SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


-- create a new column called corrected version.
SELECT SoldAsVacant,
CASE when SoldAsVacant = 'Y' then 'Yes'
     when SoldAsVacant = 'N' then 'No'
     else SoldAsVacant
     END AS CorrectedVersion -- name of the new column
FROM PortfolioProject..NashvilleHousing

-- now do the update (go back and check if it worked)
UPDATE NashvilleHousing
SET SoldAsVacant = CASE when SoldAsVacant = 'Y' then 'Yes'
                        when SoldAsVacant = 'N' then 'No'
                        else SoldAsVacant
                        END
---------------------------------------------------------



-- Dec 30th 2023 Sat
-- Remove Duplicates
WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY UniqueID
) as row_num -- all of the rows have the duplicates of row_num

FROM PortfolioProject..NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
-- ORDER BY PropertyAddress

-- now delete all the duplicates (go back and check run the above and see if there are more duplicates or not)
WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY UniqueID
) as row_num -- all of the rows have the duplicates of row_num

FROM PortfolioProject..NashvilleHousing
)
delete 
from RowNumCTE
WHERE row_num > 1
------------------------------------------------------------------


-- Delete useless columns
-- becarefull when you use delete, don't use it on the raw data. 
SELECT *
FROM PortfolioProject..NashvilleHousing

-- now delete the useless columns (run the above to check)
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN TaxDistrict, OwnerAddress, PropertyAddress
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------