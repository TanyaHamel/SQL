--DATA CLEANING EXERCISE
--AlexTheAnalyst on YouTube
--Things added myself: 
-- Matching Property State to Owner State where known (Obviously all TN as this is date from Nashville, but good practice nonetheless)
-- Renaming columns if required too

--Standardize Sale Date Format

Select SaleDate, CONVERT(Date, SaleDate)
From NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

Select SaleDate
FROM NashvilleHousing

--SQL not updating correctly so will alter table to force the update

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted
FROM NashvilleHousing


--Populate Property Address data

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress is null

--There are null property addresses.  We can use the parcel ID to determine if the address is known

SELECT NH1.ParcelID, NH1.PropertyAddress, NH2.ParcelID, NH2.PropertyAddress, ISNULL(NH1.PropertyAddress, NH2.PropertyAddress)
FROM NashvilleHousing AS NH1
JOIN NashvilleHousing AS NH2
on NH1.ParcelID = NH2.ParcelID
AND NH1.[UniqueID] <> NH2.[UniqueID]
WHERE NH1.PropertyAddress is null

Update NH1
SET PropertyAddress = ISNULL(NH1.PropertyAddress, NH2.PropertyAddress)
FROM NashvilleHousing AS NH1
JOIN NashvilleHousing AS NH2
on NH1.ParcelID = NH2.ParcelID
AND NH1.[UniqueID] <> NH2.[UniqueID]
WHERE NH1.PropertyAddress is null

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress is null

--no nullproperty addresses left!

--Breaking outAddress into individual columns (Address, City, State)

--Deliminer separates the street address and the city
--Two different methods to use

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255),
	PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

WHERE NH1.PropertyAddress is null

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255),
	OwnerSplitCity Nvarchar(255),
	OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)


--Populate State for Property Addresses where known
ALTER TABLE NashvilleHousing
Add PropertySplitState Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitState = CASE 
	 WHEN PropertySplitAddress = OwnerSplitAddress AND PropertySplitCity = OwnerSplitCity
	   THEN OwnerSplitState
	   ELSE NULL
       END

SELECT PropertySplitState
FROM NashvilleHousing


SELECT *
FROM NashvilleHousing

-- Change Y and N to Yes and No in 'Sold as Vacant" field

SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
	 WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END


--Remove duplicates
--Generally, we wouldn't delete the raw data and instead delete duplicates in temp tables, or create a copy if space is not an issue. 
--However, in this case, we will delete the duplicate data by confirming that multiple columns are the same across different rows

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 LegalReference
				 ORDER BY ParcelID
				 ) AS row_num
FROM NashvilleHousing)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--Delete unused columns

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


--Rename altered columns
--Depending on what software you use, you could rename the columns in future visulizations using the below script


EXEC sp_RENAME 'NashvilleHousing.SaleDateConverted', 'SaleDate', 'COLUMN'
EXEC sp_RENAME 'NashvilleHousing.PropertySplitAddress', 'PropertyAddress', 'COLUMN'
EXEC sp_RENAME 'NashvilleHousing.PropertySplitCity', 'PropertyCity', 'COLUMN'
EXEC sp_RENAME 'NashvilleHousing.PropertySplitState', 'PropertyState', 'COLUMN'
EXEC sp_RENAME 'NashvilleHousing.OwnerSplitAddress', 'OwnerAddress', 'COLUMN'
EXEC sp_RENAME 'NashvilleHousing.OwnerSplitCity', 'OwnerSplitAddress', 'COLUMN'
EXEC sp_RENAME 'NashvilleHousing.OwnerSplitState', 'OwnerSplitState', 'COLUMN'