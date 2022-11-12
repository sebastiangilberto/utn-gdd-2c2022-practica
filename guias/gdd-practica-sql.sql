USE GD2C2022PRACTICA 
GO

/*Práctica de SQL*/

/*
 * 1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
 * igual a $ 1000 ordenado por código de cliente.
 */

SELECT
	clie_codigo,
	clie_razon_social
FROM
	dbo.Cliente
WHERE
	clie_limite_credito >= 1000
ORDER BY
	clie_codigo ASC
 
/*
 * 2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
 * cantidad vendida.
 */
	
SELECT
	p.prod_codigo,
	p.prod_detalle
FROM
	Item_Factura i
INNER JOIN Producto p ON
	i.item_producto = p.prod_codigo
INNER JOIN Factura f ON
	i.item_numero = f.fact_numero
	AND f.fact_tipo = i.item_tipo
	AND f.fact_sucursal = i.item_sucursal
WHERE
	YEAR(f.fact_fecha) = '2012'
GROUP BY
	p.prod_codigo,
	p.prod_detalle
ORDER BY
	SUM(i.item_cantidad) DESC
	

/*
 * 3. Realizar una consulta que muestre código de producto, nombre de producto y el stock
 * total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
 * nombre del artículo de menor a mayor.
 */

SELECT
	p.prod_codigo,
	p.prod_detalle,
	SUM(s.stoc_cantidad) AS stock_total
FROM
	Producto p
INNER JOIN Stock s ON
	p.prod_codigo = s.stoc_producto
GROUP BY
	p.prod_codigo,
	p.prod_detalle
ORDER BY
	p.prod_detalle ASC
	
 /*
  * 4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
  * artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
  * promedio por depósito sea mayor a 100.
  */
	
SELECT
	p.prod_codigo,
	p.prod_detalle,
	ISNULL(SUM(c.comp_cantidad), 1) AS cantidad_articulos
FROM
	Composicion c
RIGHT JOIN Producto p ON
	c.comp_producto = p.prod_codigo
INNER JOIN Stock s ON
	p.prod_codigo = s.stoc_producto
GROUP BY
	p.prod_codigo,
	p.prod_detalle
HAVING
	AVG(ISNULL(s.stoc_cantidad, 0)) > 100
ORDER BY
	3 DESC

/*
 * 5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
 * stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
 * fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.
 */

SELECT
	p.prod_codigo,
	p.prod_detalle,
	SUM(i.item_cantidad) AS egresos_stock
FROM
	Item_Factura i
INNER JOIN Producto p ON
	i.item_producto = p.prod_codigo
INNER JOIN Factura f ON
	i.item_numero = f.fact_numero
	AND f.fact_tipo = i.item_tipo
	AND f.fact_sucursal = i.item_sucursal
	AND YEAR(f.fact_fecha) = 2012
GROUP BY
	p.prod_codigo,
	p.prod_detalle
HAVING
	SUM(i.item_cantidad) > (
	SELECT
		SUM(i2.item_cantidad) as egresos_2011
	FROM
		Item_Factura i2
	INNER JOIN Factura f2 ON
		i2.item_numero = f2.fact_numero
		AND f2.fact_tipo = i2.item_tipo
		AND f2.fact_sucursal = i2.item_sucursal
		AND YEAR(f2.fact_fecha) = 2011
	WHERE
		i2.item_producto = p.prod_codigo)                          

/* 
 * 6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
 * rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
 * tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.
 */

SELECT
	r.rubr_id,
	r.rubr_detalle,
	COUNT(DISTINCT p.prod_codigo) AS cantidad_articulos,
	SUM(ISNULL(s.stoc_cantidad, 0)) AS stock_total
FROM
	Rubro r
LEFT JOIN Producto p ON
	r.rubr_id = p.prod_rubro
LEFT JOIN Stock s ON
	p.prod_codigo = s.stoc_producto
GROUP BY
	r.rubr_id,
	r.rubr_detalle
HAVING
	SUM(ISNULL(s.stoc_cantidad, 0)) > (
	SELECT
		s2.stoc_cantidad
	FROM
		Stock s2
	WHERE
		s2.stoc_producto = '00000000'
		AND s2.stoc_deposito = '00')
/*
 * 7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio
 * menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
 * 10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
 * stock.
 */

SELECT
	p.prod_codigo,
	p.prod_detalle,
	MIN(i.item_precio) AS menor_precio,
	MAX(i.item_precio) AS mayor_precio,
	(MAX(i.item_precio) - MIN(i.item_precio)) / MIN(i.item_precio) * 100 AS diferencia_precios
FROM
	Producto p
INNER JOIN Item_Factura i ON
	p.prod_codigo = i.item_producto
INNER JOIN Stock s ON
	p.prod_codigo = s.stoc_producto
GROUP BY
	p.prod_codigo,
	p.prod_detalle
HAVING
	SUM(s.stoc_cantidad) > 0
	
/* 
 * 8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
 * artículo, stock del depósito que más stock tiene.
 */

SELECT
	p.prod_detalle,
	MAX(s.stoc_cantidad) AS mayor_stock
FROM
	Producto p
INNER JOIN Stock s ON
	p.prod_codigo = s.stoc_producto
GROUP BY
	p.prod_detalle
HAVING
	COUNT(DISTINCT s.stoc_deposito) = (
	SELECT
		COUNT(*)
	FROM
		Deposito)
/*
 * 9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
 * mismo y la cantidad de depósitos que ambos tienen asignados.
 */
		
SELECT
	j.empl_codigo AS jefe,
	CONCAT(RTRIM(j.empl_nombre), SPACE(1), RTRIM(j.empl_apellido)) as nombre_jefe,
	e.empl_codigo AS empleado,
	CONCAT(RTRIM(e.empl_nombre), SPACE(1), RTRIM(e.empl_apellido)) as nombre_empleado,
	(
	SELECT
		count(*)
	FROM
		Deposito d
	WHERE
		(d.depo_encargado = j.empl_codigo
		OR d.depo_encargado = e.empl_codigo)) AS depositos_asignados
FROM
	Empleado e
INNER JOIN Empleado j ON
	e.empl_jefe = j.empl_codigo

/* 
 * 10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
 * vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
 * mayor compra realizo.
 */
	
SELECT
	p.prod_codigo,
	(
	SELECT
		TOP 1 f2.fact_cliente
	FROM
		Item_Factura i2
	INNER JOIN Factura f2 ON
		i2.item_numero = f2.fact_numero
		AND f2.fact_tipo = i2.item_tipo
		AND f2.fact_sucursal = i2.item_sucursal
	WHERE
		i2.item_producto = p.prod_codigo
	GROUP BY
		f2.fact_cliente
	ORDER BY
		SUM(i2.item_cantidad) DESC) AS cliente_mayor_compras
FROM
	Producto p
WHERE
	p.prod_codigo IN (
	SELECT
		TOP 10 i2.item_producto
	FROM
		Item_Factura i2
	GROUP BY
		i2.item_producto
	ORDER BY
		SUM(i2.item_cantidad) DESC )
	OR p.prod_codigo IN (
	SELECT
		TOP 10 i2.item_producto
	FROM
		Item_Factura i2
	GROUP BY
		i2.item_producto
	ORDER BY
		SUM(i2.item_cantidad) ASC )

/*
 * 11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
 * productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
 * ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
 * solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
 * el año 2012.
 */

SELECT
	f.fami_id,
	f.fami_detalle,
	COUNT(DISTINCT i.item_producto) AS productos_diferentes_vendidos,
	SUM(i.item_precio * i.item_cantidad) AS ventas_sin_impuestos
FROM
	Familia f
INNER JOIN Producto p ON
	f.fami_id = p.prod_familia
INNER JOIN Item_Factura i ON
	p.prod_codigo = i.item_producto
GROUP BY
	f.fami_id,
	fami_detalle
HAVING
	(
	SELECT
		SUM(i2.item_precio * i2.item_cantidad)
	FROM
		Item_Factura i2
	INNER JOIN Producto p2 ON
		i2.item_producto = p2.prod_codigo
	INNER JOIN Factura f2 ON
		i2.item_numero = f2.fact_numero
		AND i2.item_tipo = f2.fact_tipo
		AND i2.item_sucursal = f2.fact_sucursal
	WHERE
		YEAR(f2.fact_fecha) = 2012
		AND p2.prod_familia = f.fami_id) > 20000
ORDER BY
	COUNT(DISTINCT i.item_producto) DESC

/*
 * 12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe
 * promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
 * producto y stock actual del producto en todos los depósitos. Se deberán mostrar
 * aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
 * ordenarse de mayor a menor por monto vendido del producto.
 */
	
SELECT
	p.prod_detalle,
	COUNT(DISTINCT f.fact_cliente) AS compradores_distintos,
	ROUND(AVG(i.item_precio), 2) AS precio_promedio,
	(
	SELECT
		COUNT(DISTINCT s1.stoc_deposito)
	FROM
		Stock s1
	WHERE
		s1.stoc_producto = p.prod_codigo
		AND s1.stoc_cantidad > 0) AS depositos_con_stock,
	(
	SELECT
		ISNULL(SUM(s2.stoc_cantidad),
		0)
	FROM
		Stock s2
	WHERE
		s2.stoc_producto = p.prod_codigo) AS stock_actual
FROM
	Producto p
INNER JOIN Item_Factura i ON
	p.prod_codigo = i.item_producto
INNER JOIN Factura f ON
	i.item_numero = f.fact_numero
	AND i.item_tipo = f.fact_tipo
	AND i.item_sucursal = f.fact_sucursal
WHERE
	EXISTS (
	SELECT
		1
	FROM
		Item_Factura i2
	INNER JOIN Factura f2 ON
		i2.item_numero = f2.fact_numero
		AND i2.item_tipo = f2.fact_tipo
		AND i2.item_sucursal = f2.fact_sucursal
	WHERE
		YEAR(f2.fact_fecha) = 2012
		AND i2.item_producto = p.prod_codigo)
GROUP BY
	p.prod_codigo,
	p.prod_detalle
ORDER BY
	SUM(i.item_cantidad * i.item_precio) DESC

/*
 * 13. Realizar una consulta que retorne para cada producto que posea composición nombre
 * del producto, precio del producto, precio de la sumatoria de los precios por la cantidad 
 * de los productos que lo componen. Solo se deberán mostrar los productos que estén
 * compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
 * cantidad de productos que lo componen.
 */

SELECT
	p.prod_detalle,
	p.prod_precio,
	(SUM(pc.prod_precio) * COUNT(DISTINCT pc.prod_codigo)) AS precio_componentes
FROM
	Producto p
INNER JOIN Composicion c ON
	p.prod_codigo = c.comp_producto
INNER JOIN Producto pc ON
	c.comp_componente = pc.prod_codigo
GROUP BY
	p.prod_detalle,
	p.prod_precio
HAVING
	COUNT(DISTINCT pc.prod_codigo) > 2
ORDER BY
	COUNT(DISTINCT pc.prod_codigo) DESC	
	
/*
 * 14. Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que
 * debe retornar son:
 * Código del cliente
 * Cantidad de veces que compro en el último año
 * Promedio por compra en el último año
 * Cantidad de productos diferentes que compro en el último año
 * Monto de la mayor compra que realizo en el último año
 * Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
 * el último año.
 * No se deberán visualizar NULLs en ninguna columna
 */
	
-- Reemplazar 2012 por GETDATE()
-- Para fines prácticos y por los datos de la base, se utiliza el valor harcodeado

SELECT
	c.clie_codigo,
	COUNT(DISTINCT CONCAT(f.fact_numero, f.fact_tipo, f.fact_sucursal)) AS cantidad_compras,
	ISNULL(AVG(f.fact_total),
	0) AS promedio_por_compra,
	(
	SELECT
		COUNT(DISTINCT i2.item_producto)
	From
		Item_Factura i2
	INNER JOIN Factura f2 ON
		i2.item_numero = f2.fact_numero
		AND i2.item_tipo = f2.fact_tipo
		AND i2.item_sucursal = f2.fact_sucursal
		AND YEAR(f2.fact_fecha) = 2012
	WHERE
		f2.fact_cliente = c.clie_codigo) AS productos_distintos_comprados,
	ISNULL(MAX(f.fact_total),
	0)AS monto_mayor_compra
FROM
	Cliente c
LEFT JOIN Factura f ON
	c.clie_codigo = f.fact_cliente
	AND YEAR(f.fact_fecha) = 2012
GROUP BY
	c.clie_codigo
ORDER BY
	COUNT(DISTINCT CONCAT(f.fact_numero, f.fact_tipo, f.fact_sucursal)) DESC

/*
 * 15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
 * (en la misma factura) más de 500 veces. El resultado debe mostrar el código y
 * descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
 * juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
 * juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
 * Ejemplo de lo que retornaría la consulta:
 * PROD1 DETALLE1 PROD2 DETALLE2 VECES
 * 1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
 * 1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2
 */

SELECT
	p.prod_codigo,
	p.prod_detalle,
	p2.prod_codigo,
	p2.prod_detalle,
	COUNT(*)
FROM
	Item_Factura i
INNER JOIN Producto p ON
	i.item_producto = p.prod_codigo
INNER JOIN Item_Factura i2 ON
	i.item_tipo = i2.item_tipo
	AND i.item_sucursal = i2.item_sucursal
	AND i.item_numero = i2.item_numero
	AND i.item_producto < i2.item_producto
INNER JOIN Producto p2 ON
	i2.item_producto = p2.prod_codigo
GROUP BY
	p.prod_codigo,
	p.prod_detalle,
	p2.prod_codigo,
	p2.prod_detalle
HAVING
	COUNT(*) > 500

/*
 * 16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
 * en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
 * inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
 * Además mostrar
 * 1. Nombre del Cliente
 * 2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
 * 3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
 * mostrar solamente el de menor código) para ese cliente.
 * Aclaraciones:
 * La composición es de 2 niveles, es decir, un producto compuesto solo se compone de
 * productos no compuestos.
 * Los clientes deben ser ordenados por código de provincia ascendente.
 */



02269 	6987.00
03652 	125.00
02796 	3943.00

02796 	00001705	500.00
02269 	00010258	406.00
03652 	00010395	14.00


MALLERET JORGE LUIS                                                                                 	7762.00	00010258
ABADIE ULISES                                                                                       	2449.00	00010708
TISOCCO ALBA ISOLINA                                                                                	587.00	00010457

SELECT
	c.clie_razon_social,
	ISNULL(SUM(i.item_cantidad),
	0) AS unidades_vendidas_cliente,
	(
	SELECT
		TOP 1 i3.item_producto
	FROM
		Item_Factura i3
	INNER JOIN Factura f3 ON
		i3.item_numero = f3.fact_numero
		AND i3.item_tipo = f3.fact_tipo
		AND i3.item_sucursal = f3.fact_sucursal
	WHERE
		f3.fact_cliente = c.clie_codigo
		AND YEAR(f3.fact_fecha) = 2012
	GROUP BY
		f3.fact_cliente, i3.item_producto
	ORDER BY
		SUM(i3.item_cantidad) DESC, i3.item_producto ASC ) AS producto_mas_vendido_cliente
FROM
	Cliente c
INNER JOIN Factura f ON
	c.clie_codigo = f.fact_cliente
	AND YEAR(f.fact_fecha) = 2012
INNER JOIN Item_Factura i ON
	f.fact_numero = i.item_numero
	AND f.fact_tipo = i.item_tipo
	AND f.fact_sucursal = i.item_sucursal
GROUP BY
	c.clie_codigo,
	c.clie_razon_social,
	c.clie_domicilio
HAVING
	SUM(i.item_cantidad) < 1.00 / 3 * (
	SELECT
		TOP 1 AVG(i.item_cantidad)
	FROM
		Item_Factura i
	INNER JOIN Factura f ON
		f.fact_numero = i.item_numero
		AND f.fact_tipo = i.item_tipo
		AND f.fact_sucursal = i.item_sucursal
		AND YEAR(f.fact_fecha) = 2012
	GROUP BY
		i.item_producto
	ORDER BY
		SUM(i.item_cantidad) DESC)
ORDER BY
	c.clie_domicilio ASC

/*
 * 17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
 * producto.
 * La consulta debe retornar:
 * PERIODO: Año y mes de la estadística con el formato YYYYMM
 * PROD: Código de producto
 * DETALLE: Detalle del producto
 * CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
 * VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
 * pero del año anterior
 * CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
 * periodo
 * La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
 * por periodo y código de producto.
 */

SELECT
	FORMAT(f.fact_fecha,
	'yyyyMM') AS periodo,
	p.prod_codigo,
	p.prod_detalle,
	ISNULL(SUM(i.item_cantidad),
	0) AS cantidad_vendida,
	(
	SELECT
		ISNULL(SUM(i2.item_cantidad),
		0)
	FROM
		Item_Factura i2
	INNER JOIN Factura f2 ON
		i2.item_numero = f2.fact_numero
		AND i2.item_tipo = f2.fact_tipo
		AND i2.item_sucursal = f2.fact_sucursal
	WHERE
		i2.item_producto = i.item_producto
		AND MONTH(f2.fact_fecha) = MONTH(f.fact_fecha)
		AND YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) -1 ) AS ventas_anio_anterior,
	COUNT(DISTINCT fact_tipo + fact_sucursal + fact_numero) AS cantidad_facturas
FROM
	Producto p
INNER JOIN Item_Factura i ON
	p.prod_codigo = i.item_producto
INNER JOIN Factura f ON
	i.item_numero = f.fact_numero
	AND i.item_tipo = f.fact_tipo
	AND i.item_sucursal = f.fact_sucursal
GROUP BY
	MONTH(f.fact_fecha),
	YEAR(f.fact_fecha),
	FORMAT(f.fact_fecha,
	'yyyyMM'),
	p.prod_codigo,
	p.prod_detalle
ORDER BY
	FORMAT(f.fact_fecha,
	'yyyyMM'),
	p.prod_codigo

/*
 * 18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
 * La consulta debe retornar:
 * DETALLE_RUBRO: Detalle del rubro
 * VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
 * PROD1: Código del producto más vendido de dicho rubro
 * PROD2: Código del segundo producto más vendido de dicho rubro
 * CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
 * días
 * La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
 * por cantidad de productos diferentes vendidos del rubro.
 */

SELECT
	r.rubr_detalle,
	ISNULL(SUM(i.item_cantidad * i.item_precio),
	0) AS ventas,
	ISNULL((
	SELECT
		TOP 1 p2.prod_codigo
	FROM
		Producto p2
	INNER JOIN Item_Factura i2 ON
		p2.prod_codigo = i2.item_producto
	WHERE
		p2.prod_rubro = r.rubr_id
	GROUP BY
		p2.prod_codigo
	ORDER BY
		SUM(i2.item_cantidad * i2.item_precio) DESC),
	0) AS primer_prod_mas_vendido,
	ISNULL((
	SELECT
		TOP 1 p.prod_codigo
	FROM
		Producto p
	INNER JOIN Item_Factura i ON
		p.prod_codigo = i.item_producto
	WHERE
		p.prod_rubro = r.rubr_id
		AND p.prod_codigo <> (
		SELECT
			TOP 1 p.prod_codigo
		FROM
			Producto p
		INNER JOIN Item_Factura i ON
			p.prod_codigo = i.item_producto
		WHERE
			p.prod_rubro = r.rubr_id
		GROUP BY
			p.prod_codigo
		ORDER BY
			SUM(i.item_cantidad * i.item_precio) DESC)
	GROUP BY
		p.prod_codigo
	ORDER BY
		SUM(i.item_cantidad * i.item_precio) DESC),
	0) AS segundo_prod_mas_vendido,
	ISNULL((
	SELECT
		TOP 1 f3.fact_cliente
	FROM
		Factura f3
	INNER JOIN Item_Factura i3 ON
		f3.fact_tipo = i3.item_tipo
		AND f3.fact_sucursal = i3.item_sucursal
		AND f3.fact_numero = i3.item_numero
	INNER JOIN Producto p3 ON
		i3.item_producto = p3.prod_codigo
	WHERE
		p3.prod_rubro = r.rubr_id
		AND f3.fact_fecha BETWEEN DATEADD(DAY,-30,(SELECT MAX(f4.fact_fecha) FROM Factura f4)) AND (
		SELECT
			MAX(f5.fact_fecha)
		FROM
			Factura f5)
	GROUP BY
		f3.fact_cliente
	ORDER BY
		SUM(i3.item_cantidad) DESC ),
	0)AS cliente_mas_comprador_30_dias
FROM
	Rubro r
INNER JOIN Producto p ON
	rubr_id = p.prod_rubro
LEFT JOIN Item_Factura i ON
	p.prod_codigo = i.item_producto
LEFT JOIN Factura f ON
	i.item_numero = f.fact_numero
	AND i.item_tipo = f.fact_tipo
	AND i.item_sucursal = f.fact_sucursal
GROUP BY
	r.rubr_id,
	r.rubr_detalle
ORDER BY
	COUNT(DISTINCT p.prod_codigo)


/*
 * 19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
 * solicita que desarrolle una consulta sql que retorne para todos los productos:
 *  Codigo de producto
 *  Detalle del producto
 *  Codigo de la familia del producto
 *  Detalle de la familia actual del producto
 *  Codigo de la familia sugerido para el producto
 *  Detalla de la familia sugerido para el producto
 * La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
 * detalle coinciden en los primeros 5 caracteres.
 * En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
 * codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
 * diferente a la sugerida
 * Los resultados deben ser ordenados por detalle de producto de manera ascendente
 */

SELECT
	p.prod_codigo,
	p.prod_detalle,
	f.fami_id AS familia_actual_codigo,
	f.fami_detalle AS familia_actual_detalle,
	(
	SELECT
		TOP 1 f2.fami_id
	FROM
		Familia f2
	INNER JOIN Producto p2 ON
		f2.fami_id = p2.prod_familia
	WHERE
		LEFT(p2.prod_detalle,
		5) = LEFT(p.prod_detalle,
		5)
	GROUP BY
		f2.fami_id
	ORDER BY
		COUNT(*) DESC, f2.fami_id ASC) AS familia_sugerida_codigo,
	(
	SELECT
		TOP 1 f2.fami_detalle
	FROM
		Familia f2
	INNER JOIN Producto p2 ON
		f2.fami_id = p2.prod_familia
	WHERE
		LEFT(p2.prod_detalle,
		5) = LEFT(p.prod_detalle,
		5)
	GROUP BY
		f2.fami_id, f2.fami_detalle
	ORDER BY
		COUNT(*) DESC, f2.fami_id ASC) AS familia_sugerida_detalle
FROM
	Producto p
INNER JOIN Familia f ON
	p.prod_familia = f.fami_id
WHERE
	p.prod_familia <> (
	SELECT
		TOP 1 f3.fami_id
	FROM
		Familia f3
	INNER JOIN Producto p3 ON
		f3.fami_id = p3.prod_familia
	WHERE
		LEFT(p3.prod_detalle,
		5) = LEFT(p.prod_detalle,
		5)
	GROUP BY
		f3.fami_id
	ORDER BY
		COUNT(*) DESC, f3.fami_id ASC)
ORDER BY
	p.prod_detalle ASC

/*
 * 20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
 * Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
 * 2012. El puntaje de cada empleado se calculara de la siguiente manera: para los que
 * hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
 * que superen los 100 pesos que haya vendido en el año, para los que tengan menos de 50
 * facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas
 * por sus subordinados directos en dicho año.
 */

SELECT
	TOP 3 e.empl_codigo AS legajo,
	e.empl_nombre,
	e.empl_apellido,
	e.empl_ingreso,
	CASE
		WHEN(
		SELECT
			COUNT(DISTINCT f2.fact_numero + f2.fact_tipo + f2.fact_sucursal)
		FROM
			Factura f2
		WHERE
			f2.fact_vendedor = e.empl_codigo
			AND YEAR(f2.fact_fecha) = 2011) >= 50 THEN (
		SELECT
			COUNT(DISTINCT f3.fact_numero + f3.fact_tipo + f3.fact_sucursal)
		FROM
			Factura f3
		WHERE
			f3.fact_vendedor = e.empl_codigo
			AND YEAR(f3.fact_fecha) = 2011
			AND f3.fact_total > 100 )
		ELSE 0.5 * (
		SELECT
			COUNT(DISTINCT f4.fact_numero + f4.fact_tipo + f4.fact_sucursal)
		FROM
			Factura f4
		INNER JOIN Empleado e2 ON
			f4.fact_vendedor = e2.empl_codigo
		WHERE
			YEAR(f4.fact_fecha) = 2011
			AND e2.empl_jefe = e.empl_codigo )
	END AS puntaje_2011,
	CASE
		WHEN(
		SELECT
			COUNT(DISTINCT f5.fact_numero + f5.fact_tipo + f5.fact_sucursal)
		FROM
			Factura f5
		WHERE
			f5.fact_vendedor = e.empl_codigo
			AND YEAR(f5.fact_fecha) = 2012) >= 50 THEN (
		SELECT
			COUNT(DISTINCT f6.fact_numero + f6.fact_tipo + f6.fact_sucursal)
		FROM
			Factura f6
		WHERE
			f6.fact_vendedor = e.empl_codigo
			AND YEAR(f6.fact_fecha) = 2012
			AND f6.fact_total > 100 )
		ELSE 0.5 * (
		SELECT
			COUNT(DISTINCT f7.fact_numero + f7.fact_tipo + f7.fact_sucursal)
		FROM
			Factura f7
		INNER JOIN Empleado e2 ON
			f7.fact_vendedor = e2.empl_codigo
		WHERE
			YEAR(f7.fact_fecha) = 2012
			AND e2.empl_jefe = e.empl_codigo )
	END AS puntaje_2012
FROM
	Empleado e
ORDER BY
	puntaje_2012 DESC
	
/*
 * 21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
 * menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta 
 * al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se
 * considera que una factura es incorrecta cuando la diferencia entre el total de la factura
 * menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
 * los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
 * son:
 *  Año
 *  Clientes a los que se les facturo mal en ese año
 *  Facturas mal realizadas en ese año
 */

SELECT
	YEAR(f.fact_fecha),
	COUNT(DISTINCT f.fact_cliente) AS clientes_fact_incorrectas,
	COUNT(DISTINCT f.fact_numero + f.fact_tipo + f.fact_sucursal) AS facturas_incorrectas
FROM
	Factura f
WHERE
	(f.fact_total - f.fact_total_impuestos) - (
	SELECT
		SUM(i2.item_cantidad * i2.item_precio)
	FROM
		Item_Factura i2
	WHERE
		i2.item_tipo = f.fact_tipo
		AND i2.item_sucursal = f.fact_sucursal
		AND i2.item_numero = f.fact_numero) > 1
GROUP BY
	YEAR(f.fact_fecha)
/*
 * 22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
 * trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
 * por cada trimestre).
 * Se deben mostrar 4 columnas:
 *  Detalle del rubro
 *  Numero de trimestre del año (1 a 4)
 *  Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
 * menos un producto del rubro
 *  Cantidad de productos diferentes del rubro vendidos en el trimestre
 * El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
 * rubro primero el trimestre en el que mas facturas se emitieron.
 * No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
 * no superen las 100.
 * En ningun momento se tendran en cuenta los productos compuestos para esta
 * estadistica.
 */


	
/*
 * 23. Realizar una consulta SQL que para cada año muestre :
 *  Año
 *  El producto con composición más vendido para ese año.
 *  Cantidad de productos que componen directamente al producto más vendido
 *  La cantidad de facturas en las cuales aparece ese producto.
 *  El código de cliente que más compro ese producto.
 *  El porcentaje que representa la venta de ese producto respecto al total de venta
 * del año.
 * El resultado deberá ser ordenado por el total vendido por año en forma descendente.
 */

/*
 * 24. Escriba una consulta que considerando solamente las facturas correspondientes a los
 * dos vendedores con mayores comisiones, retorne los productos con composición
 * facturados al menos en cinco facturas,
 * La consulta debe retornar las siguientes columnas:
 *  Código de Producto
 *  Nombre del Producto
 *  Unidades facturadas
 * El resultado deberá ser ordenado por las unidades facturadas descendente.
 */

	
/*
 * 25. Realizar una consulta SQL que para cada año y familia muestre :
 * a. Año
 * b. El código de la familia más vendida en ese año.
 * c. Cantidad de Rubros que componen esa familia.
 * d. Cantidad de productos que componen directamente al producto más vendido de
 * esa familia.
 * e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
 * familia.
 * f. El código de cliente que más compro productos de esa familia.
 * g. El porcentaje que representa la venta de esa familia respecto al total de venta
 * del año.
 * El resultado deberá ser ordenado por el total vendido por año y familia en forma
 * descendente.
 */

/*
 * 26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las
 * siguientes columnas:
 *  Empleado
 *  Depósitos que tiene a cargo
 *  Monto total facturado en el año corriente
 *  Codigo de Cliente al que mas le vendió
 *  Producto más vendido
 *  Porcentaje de la venta de ese empleado sobre el total vendido ese año.
 * Los datos deberan ser ordenados por venta del empleado de mayor a menor.
 */

/*
 * 27. Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
 * envase devolviendo las siguientes columnas:
 *  Año
 *  Codigo de envase
 *  Detalle del envase
 *  Cantidad de productos que tienen ese envase
 *  Cantidad de productos facturados de ese envase
 *  Producto mas vendido de ese envase
 *  Monto total de venta de ese envase en ese año
 *  Porcentaje de la venta de ese envase respecto al total vendido de ese año
 * Los datos deberan ser ordenados por año y dentro del año por el envase con más
 * facturación de mayor a menor
 */
	
/*
 * 28. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
 * siguientes columnas:
 *  Año.
 *  Codigo de Vendedor
 *  Detalle del Vendedor
 *  Cantidad de facturas que realizó en ese año
 *  Cantidad de clientes a los cuales les vendió en ese año.
 *  Cantidad de productos facturados con composición en ese año
 *  Cantidad de productos facturados sin composicion en ese año.
 *  Monto total vendido por ese vendedor en ese año
 * Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
 * vendido mas productos diferentes de mayor a menor.
 */

/*
 * 29. Se solicita que realice una estadística de venta por producto para el año 2011, solo para
 * los productos que pertenezcan a las familias que tengan más de 20 productos asignados
 * a ellas, la cual deberá devolver las siguientes columnas:
 * a. Código de producto
 * b. Descripción del producto
 * c. Cantidad vendida
 * d. Cantidad de facturas en la que esta ese producto
 * e. Monto total facturado de ese producto
 * Solo se deberá mostrar un producto por fila en función a los considerandos establecidos
 * antes. El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor.
 */

	
/*
 * 30. Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean
 * jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la
 * consulta que retorne las siguientes columnas:
 *  Nombre del Jefe
 *  Cantidad de empleados a cargo
 *  Monto total vendido de los empleados a cargo
 *  Cantidad de facturas realizadas por los empleados a cargo
 *  Nombre del empleado con mejor ventas de ese jefe
 * Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese
 * necesario.
 * Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se
 * deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.
 */

	
/*
 * 31. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
 * siguientes columnas:
 *  Año.
 *  Codigo de Vendedor
 *  Detalle del Vendedor
 *  Cantidad de facturas que realizó en ese año
 *  Cantidad de clientes a los cuales les vendió en ese año.
 *  Cantidad de productos facturados con composición en ese año
 *  Cantidad de productos facturados sin composicion en ese año.
 *  Monto total vendido por ese vendedor en ese año
 * Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
 * vendido mas productos diferentes de mayor a menor.
 */

	
/*
 * 32. Se desea conocer las familias que sus productos se facturaron juntos en las mismas
 * facturas para ello se solicita que escriba una consulta sql que retorne los pares de
 * familias que tienen productos que se facturaron juntos. Para ellos deberá devolver las
 * siguientes columnas:
 *  Código de familia
 *  Detalle de familia
 *  Código de familia
 *  Detalle de familia
 *  Cantidad de facturas
 *  Total vendido
 * Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias
 * que se vendieron juntas más de 10 veces.
 */
	
/*
 * 33. Se requiere obtener una estadística de venta de productos que sean componentes. Para
 * ello se solicita que realiza la siguiente consulta que retorne la venta de los
 * componentes del producto más vendido del año 2012. Se deberá mostrar:
 * a. Código de producto
 * b. Nombre del producto
 * c. Cantidad de unidades vendidas
 * d. Cantidad de facturas en la cual se facturo
 * e. Precio promedio facturado de ese producto.
 * f. Total facturado para ese producto
 * El resultado deberá ser ordenado por el total vendido por producto para el año 2012.
 */

/*
 * 34. Escriba una consulta sql que retorne para todos los rubros la cantidad de facturas mal
 * facturadas por cada mes del año 2011 Se considera que una factura es incorrecta cuando
 * en la misma factura se factutan productos de dos rubros diferentes. Si no hay facturas
 * mal hechas se debe retornar 0. Las columnas que se deben mostrar son:
 * 1- Codigo de Rubro
 * 2- Mes
 * 3- Cantidad de facturas mal realizadas.
 */

/*
 * 
 * 35. Se requiere realizar una estadística de ventas por año y producto, para ello se solicita
 * que escriba una consulta sql que retorne las siguientes columnas:
 *  Año
 *  Codigo de producto
 *  Detalle del producto
 *  Cantidad de facturas emitidas a ese producto ese año
 *  Cantidad de vendedores diferentes que compraron ese producto ese año.
 *  Cantidad de productos a los cuales compone ese producto, si no compone a ninguno
 * se debera retornar 0.
 *  Porcentaje de la venta de ese producto respecto a la venta total de ese año.
 * Los datos deberan ser ordenados por año y por producto con mayor cantidad vendida.
*/