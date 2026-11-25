--*************************************************************************--
-- Title: Assignment07
-- Desc: This file demonstrates how to use Functions
-- Change Log: When,Who,What
-- 2026-11-24, Kyle Levering, Modified File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_KLevering')
	 Begin 
	  Alter Database [Assignment07DB_KLevering] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_KLevering;
	 End
	Create Database Assignment07DB_KLevering;
End Try
Begin Catch
	Print Error_Number();
End Catch
Go
Use Assignment07DB_KLevering;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
Go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
Go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
Go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
Go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
Go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
Go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
Go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
Go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
Go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
Go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
Go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count], [ReorderLevel]) -- New column added this week
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock, ReorderLevel
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10, ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, abs(UnitsInStock - 10), ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
Go


-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
Go
Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
Go
Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
Go
Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
Go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
Go
Select * From vProducts;
Go
Select * From vEmployees;
Go
Select * From vInventories;
Go

/********************************* Questions and Answers *********************************/
Print
'NOTES------------------------------------------------------------------------------------ 
 1) You must use the BASIC views for each table.
 2) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'
-- Question 1 (5% of pts):
-- Show a list of Product names and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the product name.

Select ProductName, 
Format (UnitPrice, 'C', 'en-US') As PriceUSD
-- Selecting ProductName and formatting UnitPrice as currency using the built-in Format function.
-- Using 'en-US' to specify US English currency formatting (US dollars).
From vProducts
Order By ProductName;
Go

-- Question 2 (10% of pts): 
-- Show a list of Category and Product names, and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the Category and Product.

Select CategoryName, 
ProductName, 
Format (UnitPrice, 'C', 'en-US') As PriceUSD
--Needing to add the CategoryName to the desired query now. I use an Inner Join between the Categories and Products table
--to accomplish this. I also gave them aliases for easier typing. I can reuse my UnitPrice formatting from the previous question.
From vProducts As P
Inner Join vCategories As C
  On P.CategoryID = C.CategoryID
Order By CategoryName, ProductName;
Go

-- Question 3 (10% of pts): 
-- Use functions to show a list of Product names, each Inventory Date, and the Inventory Count.
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

Select ProductName, 
Format (InventoryDate, 'MMMM, yyyy' )As InventoryDate, [Count]
--Using similar logic to Q2, but here needing to format the InventoryDate column differently. 
--Since the column name goes into the parameter for the format, I need to use an alias, otherwise it will pull the dates into an unnamed column.
From vInventories As I
Inner Join vProducts As P
  On P.ProductID = I.ProductID
Order By ProductName, I.InventoryDate;
-- Sorting by I.InventoryDate uses the original date from the table proper.
-- When I tried to Order By InventoryDate, it referred to my Select line alias. That gave me alphabetized dates: February, January, March.
Go

-- Question 4 (10% of pts): 
-- CREATE A VIEW called vProductInventories. 
-- Shows a list of Product names, each Inventory Date, and the Inventory Count. 
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

Create View dbo.vProductInventories -- Using the full databaseobject.viewname format for SchemaBinding is required
With SchemaBinding 
As
  Select ProductName, 
  Format (InventoryDate, 'MMMM, yyyy' )As InventoryDate, 
  [Count] -- Reused from Question 3
  From dbo.vInventories As I
    Inner Join dbo.vProducts As P
    On P.ProductID = I.ProductID;
Go
-- Check that it works: 
Select * From vProductInventories
Order By ProductName, Cast(InventoryDate As Date); -- Needing to use the Cast built-in function because Format in my View turns
-- InventoryDate into text. Ordering by InventoryDate alone gives me the Feb-Jan-Mar alphabetical problem again.
-- Cast converts it to a Date value for chronological sorting, while the displayed dates keep their month-year formatting specified in the Question.
Go

-- Question 5 (10% of pts): 
-- CREATE A VIEW called vCategoryInventories. 
-- Shows a list of Category names, Inventory Dates, and a TOTAL Inventory Count BY CATEGORY
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

Create View dbo.vCategoryInventories
With SchemaBinding
As
  Select CategoryName, 
  Format (InventoryDate, 'MMMM, yyyy' )As InventoryDate, 
  Sum([Count]) As InventoryCountByCategory --   -- Using Sum to add the inventory quantities for each category and date
-- (e.g. all Beverages inventory for January 2017). 
-- Group By creates those category-and-date buckets, then Sum gives a total for each.
-- I initially grouped only by date; needed CategoryName too to keep categories separate.
  From dbo.vCategories As C 
    Inner Join dbo.vProducts As P
    On C.CategoryID = P.CategoryID
    Inner Join dbo.vInventories as I -- 2 Inner Joins to go from Inventories > Products > Categories 
    On P.ProductID = I.ProductID
	Group By CategoryName, InventoryDate;
Go
-- Check that it works: 
Select * From vCategoryInventories
Order By CategoryName, Cast(InventoryDate As Date); -- Using the Cast function once again based on my InventoryDate Format function in the Create View.
Go

-- Question 6 (10% of pts): 
-- CREATE ANOTHER VIEW called vProductInventoriesWithPreviousMonthCounts. 
-- Show a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month Count.
-- Use functions to set any January NULL counts to zero. 
-- Order the results by the Product and Date. 
-- This new view must use your vProductInventories view.

Create View dbo.vProductInventoriesWithPreviousMonthCounts
With SchemaBinding
As
  Select ProductName, 
  InventoryDate,
  [Count] As InventoryCount,
  IsNull(
  Lag([Count], 1) Over (
    Partition By ProductName
    Order By Cast(InventoryDate As Date)
  ),
  0
) As PreviousMonthCount
  From dbo.vProductInventories; -- Using vProductInventories from Question 4
  -- because it already joins the product and inventory information and formats the date.
Go

-- Lag looks back one row to get the previous inventory count. Partition By keeps each product's counts separate.
-- Order By uses Cast to read the formatted date as a Date value, so "previous" follows chronological order rather than alphabetical order.
-- Wrapping IsNull around the Lag result replaces missing previous counts with 0, such as January when there is no earlier record for that product.

-- Check that it works: 
Select * From vProductInventoriesWithPreviousMonthCounts;
Go

-- Question 7 (15% of pts): 
-- CREATE a VIEW called vProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- Verify that the results are ordered by the Product and Date.
-- Important: This new view must use your vProductInventoriesWithPreviousMonthCounts view!

Create View dbo.vProductInventoriesWithPreviousMonthCountsWithKPIs
With SchemaBinding
As
  Select ProductName, 
  InventoryDate, 
  InventoryCount, 
  PreviousMonthCount,
  CountVsPreviousCountKPI = Case 
    When InventoryCount > PreviousMonthCount Then 1
    When InventoryCount = PreviousMonthCount Then 0
    When InventoryCount < PreviousMonthCount Then -1
	End
  From dbo.vProductInventoriesWithPreviousMonthCounts;
Go

-- Using the previous view from Question 6 because it already provides current and previous month counts.
-- Adding a KPI column with Case to compare those two values:
-- 1 means inventory increased, 0 means it stayed the same, and -1 means it decreased.
-- End closes the Case expression before the From clause.

-- Check that it works: 
Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs
Order By ProductName, Cast(InventoryDate As Date);
Go

-- Question 8 (25% of pts): 
-- CREATE a User Defined Function (UDF) called fProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, the Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- The function must use the ProductInventoriesWithPreviousMonthCountsWithKPIs view.
-- Verify that the results are ordered by the Product and Date.

Create Function dbo.fProductInventoriesWithPreviousMonthCountsWithKPIs
(@KPIValue Int)
Returns Table
As
Return (
Select ProductName, 
  InventoryDate, 
  InventoryCount, 
  PreviousMonthCount,
  CountVsPreviousCountKPI
From dbo.vProductInventoriesWithPreviousMonthCountsWithKPIs
Where CountVsPreviousCountKPI = @KPIValue
);
Go

Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
Go

-- Creating an inline table-valued function using the KPI view from Q7.
-- @KPIValue is an Int parameter that lets the caller choose
-- increased counts (1), unchanged counts (0), or decreased counts (-1).
-- The Where clause matches the existing KPI column to that input,
-- so one function can return three different filtered result sets.
-- Initially, I declared the parameter without using it in Where,
-- which caused all three calls to return every row. 

Print 'Note: You will get an error until the views and functions are created!'
/* Check that it works:
Select * From vProductInventories;
Select * From vCategoryInventories;
Select * From vProductInventoriesWithPreviousMonthCounts;
Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs;

Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);
*/
Go

/***************************************************************************************/