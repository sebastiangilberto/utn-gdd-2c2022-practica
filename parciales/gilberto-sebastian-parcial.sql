/* SQL */

SELECT
	c.clie_codigo,
	c.clie_razon_social,
	ISNULL((
	SELECT
		TOP 1 i3.item_producto
	FROM
		Item_Factura i3
	INNER JOIN Factura f3 ON
		i3.item_tipo = f3.fact_tipo
		AND i3.item_sucursal = f3.fact_sucursal
		AND i3.item_numero = f3.fact_numero
	WHERE
		YEAR(f3.fact_fecha) = 2012
		AND f3.fact_cliente = c.clie_codigo
	GROUP BY
		i3.item_producto
	ORDER BY
		SUM(i3.item_cantidad) DESC),
	'NO HAY PRODUCTO') AS codigo_producto_mas_comprado,
	ISNULL((
	SELECT
		TOP 1 p5.prod_detalle
	FROM
		Item_Factura i5
	INNER JOIN Factura f5 ON
		i5.item_tipo = f5.fact_tipo
		AND i5.item_sucursal = f5.fact_sucursal
		AND i5.item_numero = f5.fact_numero
	INNER JOIN Producto p5 ON
		i5.item_producto = p5.prod_codigo
	WHERE
		YEAR(f5.fact_fecha) = 2012
		AND f5.fact_cliente = c.clie_codigo
	GROUP BY
		i5.item_producto,
		p5.prod_detalle
	ORDER BY
		SUM(i5.item_cantidad) DESC),
	'NO HAY PRODUCTO') AS detalle_producto_mas_comprado,
	COUNT(DISTINCT i.item_producto) AS productos_distintos,
	ISNULL((
	SELECT
		COUNT(DISTINCT i4.item_producto)
	FROM
		Item_Factura i4
	INNER JOIN Factura f4 ON
		i4.item_tipo = f4.fact_tipo
		AND i4.item_sucursal = f4.fact_sucursal
		AND i4.item_numero = f4.fact_numero
	WHERE
		YEAR(f4.fact_fecha) = 2012
		AND f4.fact_cliente = c.clie_codigo
		AND i4.item_producto IN (
		SELECT
			DISTINCT comp_producto
		FROM
			Composicion c)
	GROUP BY
		f4.fact_cliente),
	0) AS cantidad_productos_compuestos
FROM
	Cliente c
INNER JOIN Factura f ON
	c.clie_codigo = f.fact_cliente
INNER JOIN Item_Factura i ON
	f.fact_tipo = i.item_tipo
	AND f.fact_sucursal = i.item_sucursal
	AND f.fact_numero = i.item_numero
WHERE
	YEAR(f.fact_fecha) = 2012
GROUP BY
	c.clie_codigo,
	c.clie_razon_social
HAVING
	(
	SELECT
		SUM(f.fact_total)
	FROM
		Factura f
	WHERE
		f.fact_cliente = c.clie_codigo
		AND YEAR(f.fact_fecha) = 2012) > (
	SELECT
		AVG(f2.fact_total)
	FROM
		Factura f2
	WHERE
		YEAR(f2.fact_fecha) = 2012 )
ORDER BY
	CASE
		WHEN COUNT(DISTINCT i.item_producto) BETWEEN 5 AND 10 THEN 1
		ELSE 2
	END ASC

/* T-SQL */

ALTER TABLE STOCK ADD CONSTRAINT const_stock_positivo CHECK (stoc_cantidad >= 0)
	
CREATE OR ALTER TRIGGER tr_descontar_stock ON dbo.Item_Factura INSTEAD OF INSERT
AS
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	
	-- Variables
	DECLARE @producto char(8), @cantidad_vendida decimal(12,2), @componente char(8), @cantidad_componente decimal(12,2)
	
	-- Cursor
	DECLARE cursor_producto CURSOR FOR
		SELECT i.item_producto, SUM(i.item_cantidad)
		FROM INSERTED i
		GROUP BY i.item_producto
		
	OPEN cursor_producto
	FETCH cursor_producto INTO @producto, @cantidad_vendida
	
	WHILE @@FETCH_STATUS = 0
		BEGIN
		
		-- Si no es compuesto, descuento sobre el producto original
		IF NOT EXISTS (SELECT 1 FROM Composicion c WHERE c.comp_producto = @producto)
			BEGIN
				UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidad_vendida WHERE stoc_deposito = '00' AND stoc_producto = @producto
				IF @@ERROR != 0   
					BEGIN
						PRINT(CONCAT('EL PRODUCTO ', @producto, 'YA NO TIENE STOCK'))
					END
				ELSE
					BEGIN
						INSERT INTO GD2C2022PRACTICA.dbo.Item_Factura
						(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
						SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio
						FROM INSERTED WHERE item_producto = @producto
					END
			END
		
		-- Si es compuesto itero y descuento sobre los componentes
		DECLARE cursor_componente CURSOR FOR
			SELECT comp_componente, comp_cantidad
			FROM Composicion
			WHERE comp_producto = @producto
		
		OPEN cursor_componente
		FETCH cursor_componente INTO @componente, @cantidad_componente
		
		WHILE @@FETCH_STATUS = 0
			BEGIN
				UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidad_vendida * @cantidad_componente WHERE stoc_deposito = '00' AND stoc_producto = @componente
				IF @@ERROR != 0   
				BEGIN
					PRINT(CONCAT('EL PRODUCTO ', @componente, 'YA NO TIENE STOCK'))
				END
				ELSE
				BEGIN
					INSERT INTO Item_Factura
					(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
					SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio
					FROM INSERTED WHERE item_producto = @componente
				END
				
				FETCH cursor_componente INTO @componente,@cantidad_componente
			END
			
		CLOSE cursor_componente
		DEALLOCATE cursor_componente
		
		FETCH cursor_producto INTO @producto,@cantidad_vendida
		END
	
	CLOSE cursor_producto
	DEALLOCATE cursor_producto
GO