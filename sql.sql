
use ecommerce;

drop table warehouses;
CREATE TABLE warehouses(
	id_warehouses char(1) unique ,
    latitude DECIMAL(9, 6),
    longitude DECIMAL(9, 6),
    PRIMARY KEY (id_warehouses)
);

DELETE FROM warehouses
WHERE id_warehouses IS NULL;
select *from warehouses;

drop table transacciones;
CREATE TABLE transacciones (
    id_transacciones INT NOT NULL,
    month int,
    created DATETIME(6),
    order_id INT,
    id_warehouses CHAR(1),
    latitude DECIMAL(16, 13),
    longitude DECIMAL(16, 13),
    delivery_fee FLOAT,
    PRIMARY KEY (id_transacciones),
    FOREIGN KEY (id_warehouses) REFERENCES warehouses(id_warehouses)
);

select *from transacciones;
truncate  table transacciones;
/*Se desea visualizar la evolución del dropoff distance (distancia del almacén al punto de entrega) y del 
ingreso del delivery mensual que hay por cada warehouse para identificar potenciales oportunidades.*/
-- creando la  columna POINT warehouses
ALTER TABLE warehouses
ADD coordenadas POINT;
-- Insertando valores
UPDATE warehouses
SET coordenadas = POINT(longitude, latitude);

-- creando la  columna POINT para transacciones
ALTER TABLE transacciones
ADD coordenadas POINT DEFAULT NULL;
-- Insertando valores
UPDATE transacciones
SET coordenadas = POINT(longitude, latitude);

####################
-- MOSTRANDO LA DISTANCIA EN KILOMETROS
select 
*, round(ST_Distance_Sphere(w.coordenadas, t.coordenadas)/1000,2) as distance
from warehouses w
join transacciones t on(w.id_warehouses=t.id_warehouses);
####
-- Crear una coluMna para las distancias 

ALTER  TABLE transacciones
ADD COLUMN distance FLOAT  DEFAULT NULL ;
SELECT * FROM  transacciones;
-- INSERTANDO LOS DATOS
UPDATE transacciones t
right join warehouses w ON (w.id_warehouses = t.id_warehouses)
SET t.distance = ROUND(ST_Distance_Sphere(w.coordenadas, t.coordenadas) / 1000, 2);
Select * from transacciones;
-- ANALISANDO LOS NULOS
select * 
from transacciones 
where distance is null;

-- eliminacion de nulos por no ser significativos
DELETE FROM transacciones
WHERE distance IS NULL;

-- Se desea visualizar la evolución del dropoff distance 
Select id_warehouses, month ,round(avg(distance),2) as evolucion_distancia
from transacciones
group by id_warehouses,month
order by id_warehouses ,month asc ;

-- del ingreso del delivery mensual que hay por cada warehouse para identificar potenciales oportunidades.
Select  month, id_warehouses, round(sum(distance * delivery_fee),2) as  ingreso_mensual
from transacciones
group by month,id_warehouses
order by month,ingreso_mensual desc ;
-- Identificando warehouses con mayor cantidad e pedidos 

/*2.	Con el objetivo de mantener o incrementar el volumen de transacciones posibles minimizando 
el costo por orden, en un comité se plantea la optimización de las coberturas de los warehouses. 
¿Qué método propondrías para la elaboración de la propuesta? ¿Qué variables utilizarías? Presente la lógica de la solución (no se brindará una BBDD, por lo que es necesario que los pasos a seguir para el planteamiento y el desarrollo de la solución sean específicos). */

-- Identificando warehouses da mayor gasto 
select id_warehouses ,round(sum(distance * delivery_fee),2) as gastos ,count(*) as pedidos 
from transacciones
group by id_warehouses
order by gastos  DESC;

select *from transacciones
where id_warehouses LIKE '%D%';

select *from transacciones
where id_warehouses LIKE '%H%';

/*
3.	Se tienen tres tablas (product_category, product_product, product_variant) con la siguiente estructura:
*/

/*Importacion de las tablas
y carga de datos */
select *from  product_category;

DROP TABLE IF EXISTS product_category;

SELECT @@global.secure_file_priv;
CREATE TABLE IF NOT EXISTS product_category (
  	id_product_category INT,
  	name BIGINT,
  	parent varchar(10),
    PRIMARY KEY(id_product_category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\ej3_product_category.csv'
INTO TABLE product_category 
FIELDS TERMINATED BY ';' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

DROP TABLE IF EXISTS product_product;

CREATE TABLE IF NOT EXISTS product_product (
  	id_product		INTEGER,
  	name 	BIGINT,
  	category_id 	varchar(50),
    price			FLOAT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\ej3_product_product.csv'
INTO TABLE product_product 
FIELDS TERMINATED BY ';' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

DROP TABLE IF EXISTS product_variant;
CREATE TABLE IF NOT EXISTS product_variant (
  	id_product		INTEGER,
  	sku 	INTEGER
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\ej3_product_variant.csv'
INTO TABLE product_variant 
FIELDS TERMINATED BY ';' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;


/* 3.1Se requiere elaborar un query para formar la siguiente tabla (puede crearse una tabla, una 
vista o se puede utilizar un CTE), en donde el campo “id_Product” no puede tener nulos:

*/
-- soluconado los nulos 
select * from product_variant;
select *from product_product;

delete from product_product
where category_id='';

select *from product_category limit 5;

DELETE FROM product_category
WHERE parent ='\r';


select *from product_category;

select *from product_product;

ALTER TABLE product_product
MODIFY COLUMN category_id INT;

-- 
select *from product_variant
where id_product is null;
-- TESTEO 
select  ROUND(pc.id_product_category / 100,0) AS Macro_category,
		FLOOR((pc.id_product_category % 100) / 10) AS Sub_category,
		pc.id_product_category % 10 AS Micro_category, 
pv.id_product ,pv.sku ,pp.name,pp.price
from product_variant as pv
join product_product as pp on (pv.id_product=pp.id_product)
join product_category as pc on (pp.category_id=pc.parent)
limit 5;
-- CREACION DE LA VISTA 
DROP  VIEW product_view ;
CREATE VIEW product_view AS
SELECT
    ROUND(pc.id_product_category / 100, 0) AS Macro_category,
    FLOOR((pc.id_product_category % 100) / 10) AS Sub_category,
    pc.id_product_category % 10 AS Micro_category,
    pv.id_product,
    pv.sku,
    pp.name,
    pp.price
FROM
    product_variant AS pv
    JOIN product_product AS pp ON (pv.id_product = pp.id_product)
    JOIN product_category AS pc ON (pp.category_id = pc.parent);


/*
Una vez que se forme la tabla, se requiere armar un query que muestre el nombre/descripción del SKU más caro de cada categoría
 con la siguiente estructura
(si hay dos productos con el mismo precio, seleccionar el que tenga el código de SKU con el dígito más cercano a 0):

*/

SELECT pv.Macro_category, pv.Sub_category, pv.max_price
FROM (
    SELECT Macro_category, Sub_category, MAX(price) AS max_price
    FROM product_view
    GROUP BY Macro_category, Sub_category
) AS pv
JOIN product_view AS pp ON pv.Macro_category = pp.Macro_category  AND pv.max_price = pp.price;


SELECT Macro_category,MAX(price)
FROM  product_view
GROUP BY Macro_category;
