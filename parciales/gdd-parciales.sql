
/* PARCIAL PREGUNTA 1 */
SELECT
	p.prod_codigo,
	p.prod_detalle,
	CASE
		WHEN COUNT(c.comp_producto) = 0 THEN 'SIMPLE'
		ELSE 'COMPUESTO'
	END AS tipo,
	SUM(i.item_cantidad) AS cantidad_vendida_otros_anios
FROM
	Producto p
INNER JOIN Item_Factura i ON
	p.prod_codigo = i.item_producto
INNER JOIN Factura f ON
	i.item_tipo = f.fact_tipo
	AND i.item_sucursal = f.fact_sucursal
	AND i.item_numero = f.fact_numero
	AND YEAR(f.fact_fecha) < 2012
LEFT JOIN Composicion c ON
	p.prod_codigo = c.comp_producto
GROUP BY
	p.prod_codigo,
	p.prod_detalle
HAVING 
	p.prod_codigo NOT IN (
	SELECT
		DISTINCT i2.item_producto
	FROM
		Item_Factura i2
	INNER JOIN Factura f2 ON
		i2.item_tipo = f2.fact_tipo
		AND i2.item_sucursal = f2.fact_sucursal
		AND i2.item_numero = f2.fact_numero
	WHERE
		YEAR(f2.fact_fecha) = 2012)
ORDER BY
	SUM(i.item_cantidad) DESC

	SELECT * FROM Composicion

/* PARCIAL PREGUNTA 2 */

CREATE OR ALTER TRIGGER tr_validar_componentes
ON Composicion
AFTER INSERT, UPDATE
AS 
BEGIN
	
	IF EXISTS(
		SELECT 1 FROM Composicion c INNER JOIN INSERTED I ON c.comp_componente = I.comp_producto
		UNION
		SELECT 1 FROM Composicion c INNER JOIN INSERTED I ON c.comp_producto = I.comp_componente
	)
	BEGIN
		ROLLBACK TRANSACTION
	END
	
END

-- Pruebas
SELECT * From Composicion

-- ESTAS LAS INSERTA
INSERT
	INTO
	Composicion (comp_cantidad, comp_producto, comp_componente)
VALUES(6, '00000031', '00000033')

INSERT
	INTO
	Composicion (comp_cantidad, comp_producto, comp_componente)
values(6, '00000102', '00000120')

-- ESTA TIENE QUE FALLAR
INSERT
	INTO
	Composicion (comp_cantidad, comp_producto, comp_componente)
VALUES(6, '00000050', '00000031')

-- ESTE PASA BIEN
UPDATE Composicion SET comp_producto = '00000883' WHERE comp_producto = '00000031'

-- ESTE TIENE QUE FALLAR
UPDATE Composicion SET comp_producto = '00000120' WHERE comp_producto = '00000883'

-- BORRAMOS TODO
DELETE FROM Composicion WHERE comp_producto IN ('00000102', '00000031', '00000050', '00000883')
