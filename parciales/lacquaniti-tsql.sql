2.  Realizar un stored procedure que reciba un código de producto y una fecha y devuelva la mayor cantidad de
    días consecutivos a partir de esa fecha que el producto tuvo al menos la venta de una unidad en el día, el
    sistema de ventas on line está habilitado 24-7 por lo que se deben evaluar todos los días incluyendo domingos y feriados.


SOLUCION:

create procedure ejercicioParcial(@CodigoProducto as char(8), @FechaInicial as smalldatetime) as
begin
    DECLARE @CantidadDeDiasQueLleva int, @CantidadDeDiasContador int, @CantidadMaximaObtenida int
    DECLARE @FactFecha smalldatetime

    SET @CantidadDeDiasQueLleva = 0
    SET @CantidadDeDiasContador = 1
    SET @CantidadMaximaObtenida = 0

    DECLARE cursor_facturas CURSOR for
         SELECT fact_fecha from Factura
         JOIN Item_Factura I on Factura.fact_tipo = I.item_tipo and Factura.fact_sucursal = I.item_sucursal and Factura.fact_numero = I.item_numero
         WHERE item_producto=@CodigoProducto
         ORDER BY fact_fecha

    OPEN cursor_facturas
    FETCH NEXT FROM cursor_facturas INTO @FactFecha
    
    WHILE @@FETCH_STATUS = 0
    begin
        IF(DATEDIFF(day,@FechaInicial,@FactFecha) = @CantidadDeDiasContador)
            begin
                SET @CantidadDeDiasContador = @CantidadDeDiasContador + 1
                SET @CantidadDeDiasQueLleva = @CantidadDeDiasQueLleva + 1
            end
        ELSE IF(@CantidadMaximaObtenida < @CantidadDeDiasQueLleva)
            begin
                SET @CantidadMaximaObtenida = @CantidadDeDiasQueLleva
            end
        ELSE IF(DATEDIFF(day,@FechaInicial,@FactFecha) != @CantidadDeDiasContador)
            begin
                SET @CantidadDeDiasQueLleva = 0
                SET @CantidadDeDiasContador = 1
            end

        FETCH NEXT FROM cursor_facturas INTO @FactFecha
    end

    CLOSE cursor_facturas
    DEALLOCATE cursor_facturas

    RETURN @CantidadMaximaObtenida
end
