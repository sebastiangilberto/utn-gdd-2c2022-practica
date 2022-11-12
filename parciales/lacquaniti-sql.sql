1.  Armar una consulta Sql que retorne:

    - Razón social del cliente
    - Límite de crédito del cliente
    - Producto más comprado en la historia (en unidades)

    Solamente deberá mostrar aquellos clientes que tuvieron mayor cantidad de ventas en el 2012 que
    en el 2011 en cantidades y cuyos montos de ventas en dichos años sean un 30 % mayor el 2012 con
    respecto al 2011. El resultado deberá ser ordenado por código de cliente ascendente

    NOTA: No se permite el uso de sub-selects en el FROM.


SOLUCION PROPUESTA:

SELECT Cli.clie_razon_social as 'Razon Social',
       Cli.clie_limite_credito as 'Limite de Credito',
       ISNULL((SELECT TOP 1 Prod.prod_detalle from Producto Prod
        JOIN Item_Factura I on Prod.prod_codigo = I.item_producto
        JOIN Factura F on F.fact_tipo = I.item_tipo and F.fact_sucursal = I.item_sucursal and F.fact_numero = I.item_numero and F.fact_cliente=Cli.clie_codigo
        GROUP BY Prod.prod_detalle
        ORDER BY sum(I.item_cantidad) DESC), 'No Compro Producto') as 'Producto mas comprado por Cliente'
from Cliente Cli
WHERE  ISNULL((SELECT sum(I2.item_cantidad) from Cliente Cli2
       JOIN Factura F2 on Cli2.clie_codigo = F2.fact_cliente
       JOIN Item_Factura I2 on F2.fact_tipo = I2.item_tipo and F2.fact_sucursal = I2.item_sucursal and F2.fact_numero = I2.item_numero
       WHERE year(F2.fact_fecha) = 2012 and Cli2.clie_codigo=Cli.clie_codigo),0)
       >
       ISNULL((SELECT sum(I3.item_cantidad) from Cliente Cli3
       JOIN Factura F3 on Cli3.clie_codigo = F3.fact_cliente
       JOIN Item_Factura I3 on F3.fact_tipo = I3.item_tipo and F3.fact_sucursal = I3.item_sucursal and F3.fact_numero = I3.item_numero
       WHERE year(F3.fact_fecha) = 2011 and Cli3.clie_codigo=Cli.clie_codigo),0)
AND
       ISNULL((SELECT sum(F2.fact_total) from Cliente Cli2
       JOIN Factura F2 on Cli2.clie_codigo = F2.fact_cliente
       WHERE year(F2.fact_fecha) = 2012 and Cli2.clie_codigo=Cli.clie_codigo),0)
       >
       ISNULL((SELECT sum(F3.fact_total) from Cliente Cli3
       JOIN Factura F3 on Cli3.clie_codigo = F3.fact_cliente
       WHERE year(F3.fact_fecha) = 2011 and Cli3.clie_codigo=Cli.clie_codigo),0) * 1.3
GROUP BY Cli.clie_razon_social, Cli.clie_limite_credito, Cli.clie_codigo
ORDER BY Cli.clie_codigo ASC

SOLUCION MIA:

SELECT
	c.clie_razon_social,
	c.clie_limite_credito AS limite_credito_cliente,
	(
	SELECT
		TOP 1 ISNULL(i.item_producto,
		0)
	FROM
		Item_Factura i
	INNER JOIN Factura f ON
		i.item_tipo = f.fact_tipo
		AND i.item_sucursal = f.fact_sucursal
		AND i.item_numero = f.fact_numero
	WHERE
		f.fact_cliente = c.clie_codigo
	GROUP BY
		i.item_producto
	ORDER BY
		ISNULL(SUM(i.item_cantidad),
		0) DESC) AS producto_mas_comprado
FROM
	Cliente c
WHERE
	(
	SELECT
		SUM(i.item_cantidad)
	FROM
		Item_Factura i
	INNER JOIN Factura f ON
		i.item_tipo = f.fact_tipo
		AND i.item_sucursal = f.fact_sucursal
		AND i.item_numero = f.fact_numero
	WHERE
		YEAR(f.fact_fecha) = 2012
		AND f.fact_cliente = c.clie_codigo) > (
	SELECT
		SUM(i.item_cantidad)
	FROM
		Item_Factura i
	INNER JOIN Factura f ON
		i.item_tipo = f.fact_tipo
		AND i.item_sucursal = f.fact_sucursal
		AND i.item_numero = f.fact_numero
	WHERE
		YEAR(f.fact_fecha) = 2011
		AND f.fact_cliente = c.clie_codigo )
	AND (
	SELECT
		100 * ((
		SELECT
			SUM(f.fact_total)
		FROM
			Factura f
		WHERE
			YEAR(f.fact_fecha) = 2012
			AND f.fact_cliente = c.clie_codigo ) - (
		SELECT
			SUM(f.fact_total)
		FROM
			Factura f
		WHERE
			YEAR(f.fact_fecha) = 2011
			AND f.fact_cliente = c.clie_codigo )) / (
		SELECT
			SUM(f.fact_total)
		FROM
			Factura f
		WHERE
			YEAR(f.fact_fecha) = 2011
			AND f.fact_cliente = c.clie_codigo )) > 30
ORDER BY
	c.clie_codigo ASC