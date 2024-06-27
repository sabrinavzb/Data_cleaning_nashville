-- Cleaning Data Project

SELECT *
FROM data_cleaning_portfolio.nashville_housing_data;

----------------------------------------------------------------------------

--Populate Property Address Data

--Some property address were null
--Parcel Id has an address. If the parcel Ids are the same, address is the same

SELECT *
FROM data_cleaning_portfolio.nashville_housing_data
--WHERE propertyaddress IS NULL
order by parcelid;

--Step 1. Join the table with itself and show where a.propertyaddress is null. UniqueId need to be different

SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress
FROM data_cleaning_portfolio.nashville_housing_data a
JOIN data_cleaning_portfolio.nashville_housing_data b
    ON a.parcelid = b.parcelid
    AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress is NULL;

--Step 2. Use COALESCE

SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, COALESCE(a.propertyaddress, b.propertyaddress)
FROM data_cleaning_portfolio.nashville_housing_data a
JOIN data_cleaning_portfolio.nashville_housing_data b
 ON a.parcelid = b.parcelid
 AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS NULL;

--UPDATE IT
UPDATE data_cleaning_portfolio.nashville_housing_data a
SET propertyaddress = COALESCE(a.propertyaddress, b.propertyaddress)
FROM data_cleaning_portfolio.nashville_housing_data b
WHERE a.parcelid = b.parcelid
 AND a.uniqueid <> b.uniqueid
 AND a.propertyaddress IS NULL;

----------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT propertyaddress
FROM data_cleaning_portfolio.nashville_housing_data;


SELECT
SUBSTRING(Propertyaddress, 1, POSITION(',' IN propertyaddress)-1) as Address   -- -1 TO REMOVE COMA
, SUBSTRING(Propertyaddress, POSITION(',' IN propertyaddress)+1, length(propertyaddress)) as City
FROM data_cleaning_portfolio.nashville_housing_data;


ALTER TABLE data_cleaning_portfolio.nashville_housing_data
ADD PropertySplitAddress varchar;

BEGIN;

UPDATE data_cleaning_portfolio.nashville_housing_data
SET PropertySplitAddress = SUBSTRING(Propertyaddress, 1, POSITION(',' IN propertyaddress)-1);

--SELECT propertysplitaddress
--FROM data_cleaning_portfolio.nashville_housing_data;

COMMIT;

begin;

ALTER TABLE data_cleaning_portfolio.nashville_housing_data
ADD PropertySplitCity varchar;

UPDATE data_cleaning_portfolio.nashville_housing_data
SET PropertySplitCity = SUBSTRING(Propertyaddress, POSITION(',' IN propertyaddress)+1, length(propertyaddress));

--SELECT PropertySplitCity
--FROM data_cleaning_portfolio.nashville_housing_data;

commit;

SELECT *
FROM data_cleaning_portfolio.nashville_housing_data;

--Separate owner address without substring

SELECT owneraddress
FROM data_cleaning_portfolio.nashville_housing_data;

SELECT
SPLIT_PART(owneraddress, ',', 1),
SPLIT_PART(owneraddress, ',', 2),
SPLIT_PART(owneraddress, ',', 3)
FROM data_cleaning_portfolio.nashville_housing_data;

begin;

ALTER TABLE data_cleaning_portfolio.nashville_housing_data
ADD ownersplitaddress varchar;

UPDATE data_cleaning_portfolio.nashville_housing_data
SET ownersplitaddress = SPLIT_PART(owneraddress, ',', 1);

SELECT nashville_housing_data.ownersplitaddress
FROM data_cleaning_portfolio.nashville_housing_data;

commit;

begin;

ALTER TABLE data_cleaning_portfolio.nashville_housing_data
ADD ownersplitcity varchar;

UPDATE data_cleaning_portfolio.nashville_housing_data
SET ownersplitcity = SPLIT_PART(owneraddress, ',', 2);

SELECT nashville_housing_data.ownersplitcity
FROM data_cleaning_portfolio.nashville_housing_data;

commit;

begin;

ALTER TABLE data_cleaning_portfolio.nashville_housing_data
ADD ownersplitstate varchar;

UPDATE data_cleaning_portfolio.nashville_housing_data
SET ownersplitstate = SPLIT_PART(owneraddress, ',', 3);

SELECT nashville_housing_data.ownersplitstate
FROM data_cleaning_portfolio.nashville_housing_data;

commit;

----------------------------------------------------------------------------

-- Change Y and N to Yes and No in 'Sold as Vacant' field

SELECT DISTINCT soldasvacant, count(soldasvacant)
FROM data_cleaning_portfolio.nashville_housing_data
GROUP BY soldasvacant ;

SELECT soldasvacant,
 CASE
    WHEN soldasvacant = 'Y' THEN 'Yes'
    WHEN soldasvacant = 'N' THEN 'No'
    ELSE soldasvacant
    END
FROM data_cleaning_portfolio.nashville_housing_data;

begin;

UPDATE data_cleaning_portfolio.nashville_housing_data
SET soldasvacant = CASE
    WHEN soldasvacant = 'Y' THEN 'Yes'
    WHEN soldasvacant = 'N' THEN 'No'
    ELSE soldasvacant
    END;

SELECT DISTINCT soldasvacant, count(soldasvacant)
FROM data_cleaning_portfolio.nashville_housing_data
GROUP BY soldasvacant ;

COMMIT;

----------------------------------------------------------------------------

--Remove Duplicates (NOTE: would be better not to delete any data from the original table. Create temp table and remove dups in there)
---Some rows are exactly the same (have same info) except for UniqueID
SELECT *
FROM data_cleaning_portfolio.nashville_housing_data;

WITH RowNumCTE AS (SELECT *,
                          ctid,
                          ROW_NUMBER() over (PARTITION BY parcelid,
                              propertyaddress,
                              saleprice,
                              saledate,
                              legalreference
                              ORDER BY
                                  uniqueid) as row_num

                   FROM data_cleaning_portfolio.nashville_housing_data
                   ORDER BY parcelid
)
--DELETE FROM data_cleaning_portfolio.nashville_housing_data     -- To delete the duplicates
--WHERE ctid IN (
    --SELECT ctid
    --FROM RowNumCTE
    --WHERE row_num > 1
--);
SELECT *
FROM RowNumCTE
where row_num > 1
ORDER BY propertyaddress;

----------------------------------------------------------------------------
--Delete Unused columns (NOTE: Do not do this to your raw data)

SELECT *
FROM data_cleaning_portfolio.nashville_housing_data;

ALTER TABLE data_cleaning_portfolio.nashville_housing_data
DROP COLUMN  owneraddress,
DROP COLUMN taxdistrict,
DROP COLUMN propertyaddress;


