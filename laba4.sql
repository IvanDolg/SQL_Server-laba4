USE AdventureWorks2012;
GO

/*
Создайте хранимую процедуру, которая будет возвращать сводную таблицу (оператор PIVOT), 
отображающую данные о количестве сотрудников (HumanResources.Employee) работающих в определенную смену (HumanResources.Shift). 
Вывести информацию необходимо для каждого отдела (HumanResources.Department). 
Список названий смен передайте в процедуру через входной параметр.
*/

IF OBJECT_ID (N'dbo.uspGetEmpCountByShift') IS NOT NULL  
    DROP PROCEDURE dbo.uspGetEmpCountByShift;  
GO 

CREATE PROCEDURE dbo.uspGetEmpCountByShift (@Shifts NVARCHAR(MAX))
AS
	DECLARE @sql NVARCHAR(MAX) = ''
BEGIN
		SET @sql = '
		SELECT * FROM (
			SELECT 
				Employee.BusinessEntityID, 
				Department.Name AS DepName,
				HumarResourcesShift.Name AS ShiftName
			FROM HumanResources.EmployeeDepartmentHistory AS EmployeeDepartmentHistory
				INNER JOIN HumanResources.Employee AS Employee
					ON EmployeeDepartmentHistory.BusinessEntityID = Employee.BusinessEntityID
				INNER JOIN HumanResources.Department AS Department 
					ON EmployeeDepartmentHistory.DepartmentID = Department.DepartmentID
				INNER JOIN HumanResources.Shift AS HumarResourcesShift
					ON EmployeeDepartmentHistory.ShiftID = HumarResourcesShift.ShiftID
						WHERE EmployeeDepartmentHistory.EndDate IS NULL
		) AS DepShiftTable
		PIVOT (
			COUNT(BusinessEntityID) FOR ShiftName IN ('+ @Shifts + ')
		) AS EmpCountShiftTable;
		'
	EXECUTE sp_executesql @sql;
END
GO

-- Вызов хранимой процедуры
EXECUTE dbo.uspGetEmpCountByShift '[Day],[Evening],[Night]';


-- Проверка работоспособности запроса, используемого в хранимой процедуре
SELECT 
	Employee.BusinessEntityID, 
	Department.Name AS DepName,
	HumarResourcesShift.Name AS ShiftName
FROM HumanResources.EmployeeDepartmentHistory AS EmployeeDepartmentHistory
	INNER JOIN HumanResources.Employee AS Employee
		ON EmployeeDepartmentHistory.BusinessEntityID = Employee.BusinessEntityID
	INNER JOIN HumanResources.Department AS Department 
		ON EmployeeDepartmentHistory.DepartmentID = Department.DepartmentID
	INNER JOIN HumanResources.Shift AS HumarResourcesShift
		ON EmployeeDepartmentHistory.ShiftID = HumarResourcesShift.ShiftID
			WHERE EmployeeDepartmentHistory.EndDate IS NULL;
GO



USE AdventureWorks2012;
GO


/*
Вывести значения полей [ProductID], [Name] из таблицы [Production].[Product] и полей [ProductModelID] и [Name] 
из таблицы [Production].[ProductModel] в виде xml, сохраненного в переменную
Создать временную таблицу и заполнить её данными из переменной, содержащей xml.
*/
DECLARE @XmlContent XML;

SET @XmlContent = (
	SELECT 
		Product.ProductID AS [@ID],
		Product.Name AS [Name],
		ProductModel.ProductModelID AS [Model/@ID],
		ProductModel.Name AS [Model/Name]
	FROM Production.Product AS Product
	INNER JOIN Production.ProductModel AS ProductModel
		ON Product.ProductModelID = ProductModel.ProductModelID
	FOR XML PATH('Product'),
	ROOT('Products')
);

-- Вывод содержимого переменной
SELECT @XmlContent;

-- Проверка существования временной таблицы (её удаление в случае, если она существует)
IF OBJECT_ID('tempdb..#Products') IS NOT NULL
	DROP TABLE #Products;


-- Создание временной таблицы для хранения данных из переменной
CREATE TABLE #Products(
	ProductID INT NOT NULL,
	ProductName NVARCHAR(50) NOT NULL,
	ModelID INT NOT NULL,
	ModelName NVARCHAR(50) NOT NULL
)

-- Вставка значений во временную таблицу
INSERT INTO #Products(
	ProductID,
	ProductName,
	ModelID,
	ModelName
)
SELECT 
	ProductID = node.value('(./@ID)[1]', 'INT'),
	ProductName = node.value('(./Name)[1]', 'NVARCHAR(50)'),
	ModelID = node.value('(./Model/@ID)[1]', 'INT'),
	ModelName = node.value('(./Model/Name)[1]', 'NVARCHAR(50)')
FROM @XmlContent.nodes('/Products/Product') AS XML(node);
GO

-- Вывод содержимого временной таблицы
SELECT * FROM #Products;