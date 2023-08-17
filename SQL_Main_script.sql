with Reasons as  (
select SalesOrderID,
        STUFF((
        SELECT '/' + Name    
        FROM (
            SELECT DISTINCT Name
            FROM (
					select  sr.SalesOrderID,  r.Name  , r.ReasonType  ReasonType
					   from sales.SalesOrderHeaderSalesReason  sr
					   left join  sales.SalesReason r   on sr.SalesReasonID  = r.SalesReasonID ) e
            WHERE e.SalesOrderID = d.SalesOrderID
        ) AS DistinctEmployees
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS reason_name,

	STUFF((
        SELECT '/' + ReasonType    
        FROM (
            SELECT DISTINCT  ReasonType
            FROM (
					select  sr.SalesOrderID,  r.Name  , r.ReasonType  ReasonType
					   from sales.SalesOrderHeaderSalesReason  sr
					   left join  sales.SalesReason r   on sr.SalesReasonID  = r.SalesReasonID ) e
            WHERE e.SalesOrderID = d.SalesOrderID
        ) AS DistinctEmployees
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')   ReasonType

from (
	select  sr.SalesOrderID,  r.Name  , r.ReasonType  ReasonType
	   from sales.SalesOrderHeaderSalesReason  sr
	   left join  sales.SalesReason r   on sr.SalesReasonID  = r.SalesReasonID )  d
GROUP BY	   SalesOrderID


)
,SalesOrderHeader  as (
select  ss.SalesOrderID,
		ss.OrderDate,
		ss.ShipDate,
		cus.Name Customer_segment,
		t.name  territory_name,
		t."Group"  territory_group,
		t.CountryRegionCode,
		sm.Name  ship_method_name,
		sm.ShipBase,
		sm.ShipRate,
		cc.CardType,
		a.AddressLine1   BillToAddress,
		a.City			BillToAddress_city,
		aa.AddressLine1  ShipToAddress,
		aa.City      ShipToAddress_city,
		ss.Status,
		ss.SubTotal  d_SubTotal,
		ss.TaxAmt	 d_TaxAmt,
		ss.Freight   d_Freight,
		ss.TotalDue  d_TotalDue,
		rs.reason_name,
		rs.ReasonType
from [Sales].[SalesOrderHeader] ss
	 left join (
			select c.CustomerID, ct.Name from sales.Customer  c
			   left join  person.BusinessEntityContact  cb  on cb.PersonID  = c.PersonID
			   left join  person.ContactType			ct  on ct.ContactTypeID = cb.ContactTypeID
			)   cus  on cus.CustomerID = ss.CustomerID
     ------------------------------
	 left join sales.SalesTerritory t  on t.TerritoryID  = ss.TerritoryID 
	 ------------------------------
	 left join Purchasing.ShipMethod sm on sm.ShipMethodID  = ss.ShipMethodID
	 ------------------------------
	 left join sales.CreditCard cc  on  cc.CreditCardID   =  ss.CreditCardID
	 ------------------------------
	 left join person.Address   a   on a.AddressID  = ss.BillToAddressID
	 ------------------------------
	 left join person.Address   aa  on aa.AddressID  = ss.ShipToAddressID
	 ------------------------------
	 left join Reasons   rs   on rs.SalesOrderID  = ss.SalesOrderID

	 )

, products  as (

select p.ProductID, p.Name product_name,
	   --p.SafetyStockLevel  product_SafetyStockLevel ,
	   p.StandardCost      product_StandardCost,
	   ps.Name  product_Subcategory_name,
	   pc.Name  product_Category_name
from Production.Product   p
left join Production.ProductSubcategory ps  on p.ProductSubcategoryID  = ps.ProductSubcategoryID
left join Production.ProductCategory     pc  on  pc.ProductCategoryID  = ps.ProductCategoryID


)
select sd.SalesOrderDetailID,
       sh.*,
       sp.Name,
	   sp.Color,
	   sp.Size,
	   sp.SizeUnitMeasureCode,
	   sp.Weight,
	   sp.SizeUnitMeasureCode,
	   sp.SafetyStockLevel,
	   ts.*,
	   sd.OrderQty,
	   sd.UnitPrice,
	   sd.UnitPriceDiscount,
	   sd.LineTotal,
	   sd.TotalPrice
from [Sales].[SalesOrderDetail]  sd

left  join  dbo.SALE_PRODUCTION  sp   on  sp.SalesOrderDetailID   =  sd.SalesOrderDetailID

left join SalesOrderHeader sh  on sh.SalesOrderID  = sd.SalesOrderID

left join products ts  on  ts.ProductID = sd.ProductID
