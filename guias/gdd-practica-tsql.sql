USE GD2C2022PRACTICA 
GO


-- TEMPLATE FUNCTION
CREATE FUNCTION fx_nombre(@param1 DATETIME, @param2 NVARCHAR(50))
RETURNS VARCHAR(2) AS
BEGIN
	
	DECLARE @var1 CHAR(100)
	DECLARE @var2 INTEGER
	
	SET @var1 = 'HOLA'
	SET @var2 = 100
	
	PRINT @var1
	PRINT @var2
	
	WHILE(CONDICION)
	BEGIN
		...
	END
	
	IF @param1 IS NULL
	BEGIN
		RETURN 'NO'
	END
	IF @param2 = 'OTRO STRING'
	BEGIN
		RETURN 'SI'
	END
RETURN 'ME'
END

/* Práctica de T-SQL */

/* 
 * 
 * 1. Hacer una función que dado un artículo y un deposito devuelva un string que
 * indique el estado del depósito según el artículo. Si la cantidad almacenada es
 * menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
 * % de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
 * “DEPOSITO COMPLETO”.
 */

CREATE OR ALTER FUNCTION fx_estado_deposito(@producto char(8), @deposito char(2))
RETURNS nvarchar(50) AS
BEGIN
	
	RETURN (
		SELECT
			CASE
				WHEN isnull(s.stoc_cantidad, 0) < s.stoc_stock_maximo THEN CONCAT('OCUPACION DEL DEPOSITO ', CONVERT(NUMERIC(4, 2), s.stoc_cantidad * 100 / s.stoc_stock_maximo), '%')
				ELSE 'DEPOSITO COMPLETO'
			END
		FROM
			Stock s
		WHERE
			s.stoc_producto = @producto
			AND s.stoc_deposito = @deposito
	) 
END

-- Prueba
SELECT dbo.fx_estado_deposito('00000030', '00')

-- Drop
DROP FUNCTION dbo.fx_estado_deposito

/*
 * 2. Realizar una función que dado un artículo y una fecha, retorne el stock que
 * existía a esa fecha
 */

CREATE OR ALTER FUNCTION fx_stock_fecha(@producto char(8), @fecha DATETIME)
RETURNS INTEGER AS
BEGIN
	DECLARE @stock_actual INTEGER
	DECLARE @cantidad_vendida INTEGER
	
	SELECT @stock_actual = ISNULL(SUM(s.stoc_cantidad), 0) FROM Stock s WHERE s.stoc_producto = @producto
	SELECT @cantidad_vendida = ISNULL(SUM(i.item_cantidad), 0)
	FROM
		Item_Factura i
	INNER JOIN Factura f ON
		item_tipo = f.fact_tipo
		AND i.item_sucursal = f.fact_sucursal
		AND i.item_numero = f.fact_numero
	WHERE
		i.item_producto = @producto
	AND
		f.fact_fecha >= @fecha
		
	RETURN @stock_actual + @cantidad_vendida
END

-- Prueba
SELECT dbo.fx_stock_fecha('00010220', CAST('2010-08-12 00:00:00' as DATETIME))

-- Drop
DROP FUNCTION dbo.fx_stock_fecha

/*
 * 
 * 3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
 * en caso que sea necesario. Se sabe que debería existir un único gerente general
 * (debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
 * sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
 * mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
 * empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
 * de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
 * de empleados que había sin jefe antes de la ejecución.
 */

-- Datos de prueba 
INSERT INTO GD2C2022PRACTICA.dbo.Empleado
(empl_codigo, empl_nombre, empl_apellido, empl_nacimiento, empl_ingreso, empl_tareas, empl_salario, empl_comision, empl_jefe, empl_departamento)
VALUES(10, 'Pablo', 'Picasso', DATEADD(YEAR, -40, GETDATE()),  DATEADD(YEAR, -11, GETDATE()), 'Gerente', 26000,0, NULL,1);

INSERT INTO GD2C2022PRACTICA.dbo.Empleado
(empl_codigo, empl_nombre, empl_apellido, empl_nacimiento, empl_ingreso, empl_tareas, empl_salario, empl_comision, empl_jefe, empl_departamento)
VALUES(11, 'Guillermo', 'Francella', DATEADD(YEAR, -40, GETDATE()),  DATEADD(YEAR, -13, GETDATE()), 'Gerente', 26000,0, NULL,1);

-- SP
CREATE OR ALTER PROCEDURE sp_corregir_gerente_general(@empleados_sin_jefe INTEGER OUTPUT) AS
BEGIN
	
	-- Empleados sin jefe
	SELECT @empleados_sin_jefe = COUNT(*) From Empleado e WHERE e.empl_jefe IS NULL
	
	IF @empleados_sin_jefe = 0
	BEGIN
		RETURN @empleados_sin_jefe
	END
	
	-- Obtengo nuevo jefe
	DECLARE @gerente_general NUMERIC(6,0) = (SELECT TOP 1 empl_codigo From Empleado e WHERE e.empl_jefe IS NULL ORDER BY e.empl_salario DESC, e.empl_ingreso ASC)
	
	-- Actualizo nuevo jefe
	UPDATE Empleado SET empl_jefe = @gerente_general WHERE empl_jefe IS NULL AND empl_codigo != @gerente_general
	
	RETURN @empleados_sin_jefe
END

-- Ejecucion
DECLARE @res bigint
EXEC sp_corregir_gerente_general @empleados_sin_jefe = @res OUTPUT
SELECT @res AS Retorno

-- Drop
DROP PROCEDURE dbo.sp_corregir_gerente_general

/* 
 * 4. Cree el/los objetos de base de datos necesarios para actualizar la columna de
 * empleado empl_comision con la sumatoria del total de lo vendido por ese
 * empleado a lo largo del último año. Se deberá retornar el código del vendedor
 * que más vendió (en monto) a lo largo del último año.
 */

CREATE OR ALTER PROCEDURE sp_actualizar_comision(@maximo_vendedor NUMERIC(6,0) OUTPUT) AS
BEGIN
	
	-- Obtengo empleado que más vendió
	SET @maximo_vendedor = (
		SELECT
			TOP 1 f.fact_vendedor
		FROM
			Factura f
		WHERE
			YEAR(f.fact_fecha) = (
			SELECT
				YEAR(MAX(fact_fecha))
			FROM
				Factura)
		GROUP BY
			f.fact_vendedor
		ORDER BY
			ISNULL(SUM(f.fact_total - f.fact_total_impuestos),
			0) DESC
	)
	
	-- Actualizo comisiones
	UPDATE Empleado SET empl_comision = (
		SELECT
			ISNULL(SUM(f.fact_total - f.fact_total_impuestos), 0)
		FROM
			Factura f
		WHERE
			f.fact_vendedor = empl_codigo
			AND YEAR(f.fact_fecha) = (
			SELECT
				YEAR(MAX(fact_fecha))
			FROM
				Factura)
	)
END

-- Ejecucion
DECLARE @result numeric(6)
EXEC dbo.sp_actualizar_comision @maximo_vendedor @maximo_vendedor = @result OUTPUT
SELECT @result AS [Vendedor que mas vendio]

-- Drop
DROP PROCEDURE dbo.sp_actualizar_comision

/*
 * 5. Realizar un procedimiento que complete con los datos existentes en el modelo
 * provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
	Create table Fact_table
	(
		anio char(4) NOT NULL,
		mes char(2) NOT NULL,
		familia char(3) NOT NULL,
		rubro char(4) NOT NULL,
		zona char(3) NOT NULL,
		cliente char(6) NOT NULL,
		producto char(8) NOT NULL,
		cantidad decimal(12,2),
		monto decimal(12,2)
	)
	Alter table Fact_table Add constraint pk_fact_table primary key(anio,mes,familia,rubro,zona,cliente,producto)
 */
	
CREATE OR ALTER PROCEDURE sp_completar_fact_table AS
BEGIN
	INSERT
		INTO
		dbo.Fact_table (anio, mes, familia, rubro, zona, cliente, producto, cantidad, monto)
	SELECT
		YEAR(f.fact_fecha),
		MONTH(f.fact_fecha),
		p.prod_familia,
		p.prod_rubro,
		d.depa_zona,
		f.fact_cliente,
		p.prod_codigo,
		ISNULL(SUM(i.item_cantidad),
		0) AS cantidad,
		ISNULL(SUM(i.item_cantidad * i.item_precio),
		0) AS monto
	FROM
		Factura f
	INNER JOIN Item_Factura i ON
		f.fact_tipo = i.item_tipo
		AND f.fact_sucursal = i.item_sucursal
		AND f.fact_numero = i.item_numero
	INNER JOIN Producto p ON
		i.item_producto = p.prod_codigo
	INNER JOIN Empleado e ON
		f.fact_vendedor = e.empl_codigo
	INNER JOIN Departamento d ON
		e.empl_departamento = d.depa_codigo
	GROUP BY
		YEAR(f.fact_fecha),
		MONTH(f.fact_fecha),
		p.prod_familia,
		p.prod_rubro,
		d.depa_zona,
		f.fact_cliente,
		p.prod_codigo
END


-- Ejecucion
EXEC dbo.sp_completar_fact_table

-- Drop
DROP PROCEDURE dbo.sp_completar_fact_table

-- Prueba
SELECT * FROM Fact_table

/*
 * 6. Realizar un procedimiento que si en alguna factura se facturaron componentes
 * que conforman un combo determinado (o sea que juntos componen otro
 * producto de mayor nivel), en cuyo caso deberá reemplazar las filas 
 * correspondientes a dichos productos por una sola fila con el producto que
 * componen con la cantidad de dicho producto que corresponda.
 */

/*
7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.
VENTAS
Código Detalle Cant. Mov. Precio de
Venta
Renglón Ganancia
Código
del
articulo
Detalle
del
articul
o
Cantidad de
movimientos de
ventas (Item
factura)
Precio
promedi
o de
venta
Nro. de línea de
la tabla
Precio de Venta
– Cantidad *
Costo Actual
8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:
DIFERENCIAS
Código Detalle Cantidad Precio_generado Precio_facturado
Código
del
articulo
Detalle
del
articulo
Cantidad de
productos que
conforman el
combo
Precio que se
compone a través de
sus componentes
Precio del producto
9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.
10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.
11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.
12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.
13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías
14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes.
15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.
16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto.
17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock
18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas
19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. Se sabe que en
la actualidad la regla se cumple y existe un único gerente general.
20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.
21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.
22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga más de 20 productos asignados, si un rubro tiene más de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpción “RUBRO REASIGNADO”, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada.
23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse más
de dos productos con composición. Si esto ocurre debera rechazarse la factura.
24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.
25. Desarrolle el/los elementos de base de datos necesarios para que no se permita
que la composición de los productos sea recursiva, o sea, que si el producto A 
compone al producto B, dicho producto B no pueda ser compuesto por el
producto A, hoy la regla se cumple.
26. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.
27. Se requiere reasignar los encargados de stock de los diferentes depósitos. Para
ello se solicita que realice el o los objetos de base de datos necesarios para
asignar a cada uno de los depósitos el encargado que le corresponda,
entendiendo que el encargado que le corresponde es cualquier empleado que no
es jefe y que no es vendedor, o sea, que no está asignado a ningun cliente, se
deberán ir asignando tratando de que un empleado solo tenga un deposito
asignado, en caso de no poder se irán aumentando la cantidad de depósitos
progresivamente para cada empleado.
28. Se requiere reasignar los vendedores a los clientes. Para ello se solicita que
realice el o los objetos de base de datos necesarios para asignar a cada uno de los
clientes el vendedor que le corresponda, entendiendo que el vendedor que le
corresponde es aquel que le vendió más facturas a ese cliente, si en particular un
cliente no tiene facturas compradas se le deberá asignar el vendedor con más
venta de la empresa, o sea, el que en monto haya vendido más.
29. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de diferentes productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.
30. Agregar el/los objetos necesarios para crear una regla por la cual un cliente no
pueda comprar más de 100 unidades en el mes de ningún producto, si esto
ocurre no se deberá ingresar la operación y se deberá emitir un mensaje “Se ha
superado el límite máximo de compra de un producto”. Se sabe que esta regla se
cumple y que las facturas no pueden ser modificadas.
31. Desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda
tener más de 20 empleados a cargo, directa o indirectamente, si esto ocurre
debera asignarsele un jefe que cumpla esa condición, si no existe un jefe para
asignarle se le deberá colocar como jefe al gerente general que es aquel que no
tiene jefe.
*/