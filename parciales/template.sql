/* CONSTRAINTS */
ALTER TABLE STOCKADD CONSTRAINT const_negativo CHECK (stoc_cantidad >= 0)

/* ISOLATION LEVELS */
-- LEE DATOS SUCIOS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
-- LEE DATOS COMMITEADOS (YA SEA PERSISTIDOS O LOS PREVIOS SI HAY OTRO UPDATE EN PROCESO)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
-- LOCKEA UPDATES DE REGISTROS QUE SE ESTAN LEYENDO, PERO ENTRAN REGISTROS FANTASMA (INSERT)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
-- READ/WRITE LOCK, TE DEJA LECTURA CONCURRENTE PERO EL PRIMER UPDATE SE BLOQUEA MIENTRAS SE ESTE LEYENDO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

/* UTILES */
-- DIFF EN PORCENTAJE ENTRE DOS NUMEROS
SELECT  
	100.0 * (curr.Val - prev.Val) / prev.Val As PercentDiff

-- OBTENER UN DATE USANDO LOS VALORES POR SEPARADO
DATEFROMPARTS(2010, 1, 23)
DECLARE @fecha_prueba DATE
SELECT @fecha_prueba = DATEFROMPARTS(2010, 1, 23)

/* FUNCTION */
CREATE FUNCTION fx_nombre(@param1 DATETIME, @param2 NVARCHAR(50))
RETURNS VARCHAR(2) AS
BEGIN
	
	-- DECLARO VARIABLES
	DECLARE @var1 CHAR(100)
	-- VARIABLE CON VALOR POR DEFECTO
	DECLARE @var2 INTEGER = 0
	
	-- SETEO VALORES
	SET @var1 = 'HOLA'
	SET @var2 = 100
	
	-- PRINT POR CONSOLA
	PRINT @var1
	PRINT @var2
	
	-- LOOP
	WHILE(CONDICION)
	BEGIN
		...
	END
	
	-- IF (CONDICION)
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

-- EJEMPLO 2 DEVOLVIENDO UNA TABLA
create function fnc_tabla1 (@codigo char(6))RETURNS TABLE AS
BEGIN
RETURN (
	SELECT
		*
	FROM
		CLIENTE
	WHERE
		clie_codigo != @codigo
	)
END

SELECT
	*
FROM
	DBO.fnc_tabla1 ('00000')
JOIN

/* TRIGGERS*/

CREATE OR ALTER TRIGGER tr_nombre
ON Tabla
AFTER INSERT, UPDATE
-- AFTER INSERT, UPDATE, DELETE
-- INSTEAD OF INSERT, UPDATE, DELETE
AS 
BEGIN
	
	-- INSERTED: tiene los registros POST-INSERT/UPDATE/DELETE
	
	-- DELETED: tiene los registros PRE-INSERT/UPDATE/DELETE
	
	IF EXISTS(
		SELECT 1 FROM Composicion c INNER JOIN INSERTED I ON c.comp_componente = I.comp_producto
		UNION
		SELECT 1 FROM Composicion c INNER JOIN INSERTED I ON c.comp_producto = I.comp_componente
	)
	BEGIN
		ROLLBACK TRANSACTION
	END
	
END

/* STORE PROCEDURE */
CREATE OR ALTER PROCEDURE sp_nombre(@param_input INTEGER, @param_output NUMERIC(6,0) OUTPUT) AS
BEGIN
	IF @param_input > 10
	BEGIN
		SET @param_output = 12
		-- ESTO ES PARA CORTAR LA EJECUCION DEL STORE
		RETURN 1
	END
	-- NO HACE FALTA HACER RETURN DEL PARAMETRO DE SALIDA, LO VOY A MAPEAR DESDE AFUERA
	SET @param_output = 8
END

-- Para ejecutar y obtener el output, se lo paso como parametro con una variable temporal externa
DECLARE @result numeric(6)
EXEC dbo.sp_nombre @param_output = @result OUTPUT
SELECT @result AS [Param Output Store]


/* CURSOR */

-- EJEMPLO 1
BEGIN

	DECLARE	@codigo CHAR(6), @razon_social CHAR(100)
	
	-- INSENSITIVE: lee un snapshot de la consulta, los nuevos cambios no los ve
	DECLARE mi_cursor INSENSITIVE CURSOR FOR
		SELECT
			clie_codigo,
			clie_razon_social
		FROM
			Cliente
		ORDER BY
			clie_codigo
	
	OPEN mi_cursor
	FETCH mi_cursor INTO @codigo, @razon_social 
			
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT CONCAT('Codigo cliente: ', @codigo, ', Razon Social: ', @razon_social)
		
		FETCH mi_cursor INTO @codigo, @razon_social 
	END
	
	CLOSE mi_cursor
	DEALLOCATE mi_cursor
END

-- EJEMPLO 2
BEGIN

	DECLARE	@codigo CHAR(6), @razon_social CHAR(100)
	
	DECLARE mi_cursor CURSOR FOR
		SELECT
			clie_codigo,
			clie_razon_social
		FROM
			Cliente
		ORDER BY
			clie_codigo
	-- FOR UPDATE OF: me permite modificar una columna del registro que estoy parado
	FOR UPDATE OF clie_razon_social
	
	OPEN mi_cursor
	FETCH mi_cursor INTO @codigo, @razon_social 
			
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		
		IF @codigo = '00000'
		BEGIN
			UPDATE Cliente SET clie_razon_social = 'CAMBIO POR CURSOR'
			WHERE
			-- CURRENT OF: filtro por la fila iterada actualmente por el cursos
				CURRENT OF mi_cursor
		END

		FETCH mi_cursor INTO @codigo, @razon_social 
	END
	
	CLOSE mi_cursor
	DEALLOCATE mi_cursor
END


/* VIEWS */
-- CREACION/MODIFICACION
CREATE OR ALTER VIEW v_nombre (cliente, total_comprado)AS
SELECT
	fact_cliente,
	sum(fact_total)
FROM
	Factura f
GROUP BY
	fact_cliente
	
-- CONSULTA
SELECT
	*
FROM
	v_nombre

-- UPDATE
UPDATE
	v_nombre nombre = 'xxxx10'
where
	cliente = '00656'
	
SELECT
	*
FROM
	cliente
WHERE
	clie_codigo = '00656'
	
/* OVER PARTITION */
SELECT
	ROW_NUMBER() OVER(ORDER BY name ASC) AS Row#,
	name,
	recovery_model_desc
FROM
	sys.databases
WHERE
	database_id < 5;

SELECT 
  ROW_NUMBER() OVER(PARTITION BY recovery_model_desc ORDER BY name ASC) 
    AS Row#,
  name, recovery_model_desc
FROM sys.databases WHERE database_id < 5;