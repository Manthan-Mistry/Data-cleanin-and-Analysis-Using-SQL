--** Task 1:  Convet The Saledate column to date type only**--

select SaleDate, CONVERT(date,SaleDate) from NashvilleHousing

update NashvilleHousing
Set SaleDate = CONVERT(date,SaleDate)

alter table NashvilleHousing
add Saledateconverted Date;

update NashvilleHousing
set Saledateconverted = CONVERT(date,SaleDate)

-----------------------------------------------------------------------------------------------------------

--** Task 2 :Populate PropertyAddress data**-- 

-- STEP 1 : Noticed that some of the propertyaddresses are blank valuse.
-- STEP 2 : After searching the data found that some of the parcelIDs are same having some propertyaddress blank and some are given.
-- STEP 3 : So decided to fill thode null values having same parcelID to that of the some given valus by selfjoining where parceID is
		--  same but uniqueID is not same thus ensuring not to self-join on duplicate rows.
-- STEP 4 : After that just using the isnull function to get the given values and fiiling some of the blank values.		

select * from NashvilleHousing
--where PropertyAddress is null
order by ParcelID

select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
from NashvilleHousing a
JOIN NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

--------------------------------------------------------------------------------------------------------------------
--** Task 3 :Breaking the propertyaddress into individual columns (Address, City, Sate)

select SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress) -1 ) AS Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, len(PropertyAddress)) AS City from NashvilleHousing

alter table NashvilleHousing
add Propertysplitaddress varchar(255);

update NashvilleHousing
set Propertysplitaddress =  SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress) -1 )

alter table NashvilleHousing
add PropertysplitCity varchar(250);

update NashvilleHousing
set PropertysplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress) +1, len(PropertyAddress))

select * from NashvilleHousing

---------------------------------------------------------------------------------------------------------------------

--** Task 4 :Breaking the OwnerAddress into appropriate columns**--

select OwnerAddress from NashvilleHousing

select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City 
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
from NashvilleHousing

alter table NashvilleHousing
add Ownersplitaddress varchar(255);

update NashvilleHousing
set Ownersplitaddress =  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

alter table NashvilleHousing
add OwnersplitCity varchar(250);

update NashvilleHousing
set OwnersplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

alter table NashvilleHousing
add Ownersplitstate varchar(255);

update NashvilleHousing
set Ownersplitstate =  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

---------------------------------------------------------------------------------------------------------------------

--** Task 5 :Change Y and N to Yes and No in 'Sold as vacant' field**--

select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end 
from NashvilleHousing 

update NashvilleHousing
set SoldAsVacant =  
case when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end 
from NashvilleHousing

select distinct SoldAsVacant,count(SoldAsVacant)
from NashvilleHousing
group by SoldAsVacant
order by 2

---------------------------------------------------------------------------------------------------------------------

--** Task 6 :Remove Duplicates**--

WITH RownumCTE AS (
select *, 
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 Saleprice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
from [Portfolio Project].dbo.NashvilleHousing
--order by ParcelID
)
Select * 
from RownumCTE
where row_num> 1
order by PropertyAddress

--------------------------------------------------------------------------------------------------------------------

--** Task 7 :Delete unwanted columns**--

select * from NashvilleHousing

alter table NashvilleHousing
drop column PropertyAddress, OwnerAddress, TaxDistrict

alter table NashvilleHousing
drop column SaleDate

--------------------------------------------------- ANALYSING THE DATA --------------------------------------------

--** Q1. Find out percent of blak owners?
select 100-(count(OwnerName)*1.0/count([UniqueID ])*1.0)*100 as Percent_of_blank_owners
from NashvilleHousing

--** Q2. Find out distribution of sales over LandUse

select LandUse, sum(SalePrice) total_sale
from NashvilleHousing
group by LandUse
order by total_sale desc

--** Q3. Find out total sale over the years?

select distinct year(Saledateconverted) AS Yearofsale, sum(SalePrice) Price_USD
from NashvilleHousing
group by year(Saledateconverted)
order by Price_USD desc

--** Q4. Find Out Percent of proprties currently vacant?

select (sum(No_of_Vacant_Properties)*1.0/ 56373)*100 AS Percent_of_vacant_land from

	(select  LandUse ,count(*) AS No_of_Vacant_Properties
	from NashvilleHousing
	where LandUse like '%VACANT%'
	group  by  LandUse) a


--** Q5.  Find out change in key values of property by LandUse?

select LandUse
	   ,round(AVG(Acreage),2) avg_acrege
	   ,round(AVG(LandValue),2) avg_LandValue
	   ,round(AVG(BuildingValue),2) avg_BuildingValue
	   ,round(AVG(TotalValue),2) avg_TotalValue
	   ,round(AVG(Bedrooms),2) avg_Bedrooms
from NashvilleHousing
group by LandUse
order by AVG(LandValue) desc

--** Q6. find out Most profit making LandUse types and find out total profit by LandUse?

select top 5 LandUse, sum(SalePrice-TotalValue) AS Profit
from NashvilleHousing
group by LandUse
order by Profit desc

--** Q7. Distribution of bedrooms over years.

select YearBuilt,
case when YearBuilt < 1800 then '1700' 
	 when YearBuilt >=1800 AND  YearBuilt <1900 then '1800'
	 when YearBuilt >=1900 AND  YearBuilt <2000 then '1900' 
	 when YearBuilt >=2000 AND  YearBuilt <2100 then '2000' 
		end as Year_binns
	 ,round(AVG(Bedrooms),2) Avg_Bedrooms
from NashvilleHousing
where YearBuilt is not null
group by  YearBuilt
order by YearBuilt

--** Q.8 Show the total profit over the years.  !!! Note: not taking year 2019 because there are only 2 records !!! 

select YEAR(Saledateconverted) AS Year, sum(SalePrice - TotalValue) AS Total_Profit
from NashvilleHousing
where (SalePrice - TotalValue) > 0 and YEAR(Saledateconverted) <> 2019
group by YEAR(Saledateconverted) 
order by Total_Profit desc