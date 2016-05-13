drop table viajes;
drop table rutas;
drop table autobuses;
drop table modelos;

create table modelos
(
	codigo				VARCHAR2(3),
	marca				VARCHAR2(10),
	numeroasientos			NUMBER(2),
	potencia			NUMBER(3),
	tipotransmision			     VARCHAR2(20),
	constraint pk_modelos      primary key (codigo),
	constraint marcanonula		check (marca is not null),
	constraint numasientosnonulo	check (numeroasientos is not null),
	constraint tipook		check (tipotransmision in ('Automatica','Manual'))
);

create table autobuses
(
	matricula		VARCHAR2(7),
	codmodelo		VARCHAR2(3),
	anyofabricacion		NUMBER(4),
	fechaadquisicion	DATE,
	fechaultimarevision	DATE,
	constraint pk_autobuses primary key (matricula),
	constraint fk_modelos 	foreign key (codmodelo) references modelos,
	constraint anyook 	check (anyofabricacion>2008),
	constraint fechaok 	check (fechaadquisicion>=to_date('01/01/2009','DD/MM/YYYY'))
);

create table rutas
(
	codigo			VARCHAR2(3),
	numkilometros		NUMBER(3),
	origen			VARCHAR2(10),
	destino			VARCHAR2(10),
	preciobillete		NUMBER(5,2),
	costeestimadoviaje	NUMBER(6,2),
	duracionenminutos	NUMBER(3),
	constraint pk_rutas	primary key(codigo),
	constraint numkmnonulo	check (numkilometros is not null),
	constraint origennonulo check (origen is not null),
	constraint destnonulo	check (destino is not null)
);

create table viajes
(
	codruta			VARCHAR2(3),
	matricula		VARCHAR2(7),
	fechahorasalida		DATE,
	numbilletesvendidos	NUMBER(2) default 0,
	andensalida		NUMBER(3),
	andenllegada		NUMBER(3),
	constraint pk_viajes	primary key(codruta, fechahorasalida),
    CONSTRAINT fk_viajes_codr FOREIGN KEY (codruta) REFERENCES rutas (codigo);
	constraint fk_autobuses foreign key (matricula) references autobuses,
	constraint horasalidaok	check(TO_CHAR(fechahorasalida,'HH24') between '06' and '22')
);

insert into modelos (codigo, marca, numeroasientos, tipotransmision)
values('IR7','Irizar',63,'Automatica');
insert into modelos (codigo, marca, numeroasientos, tipotransmision)
values('IR5','Irizar',55,'Manual');
insert into modelos (codigo, marca, numeroasientos, tipotransmision)
values('MB1','Mercedes',65,'Automatica');
insert into modelos (codigo, marca, numeroasientos, tipotransmision)
values('MB9','Mercedes',33,'Manual');
insert into modelos (codigo, marca, numeroasientos, tipotransmision)
values('SC2','Scania',60,'Automatica');
insert into modelos (codigo, marca, numeroasientos, tipotransmision)
values('SC5','Scania',40,'Manual');

insert into autobuses (matricula, codmodelo, anyofabricacion, fechaadquisicion, fechaultimarevision)
values('7889GHG','IR7',2011,to_date('09/08/12','DD/MM/YY'),to_date('09/06/14','DD/MM/YY'));
insert into autobuses (matricula, codmodelo, anyofabricacion, fechaadquisicion, fechaultimarevision)
values('7890GHG','IR5',2011,to_date('10/08/12','DD/MM/YY'),to_date('09/03/14','DD/MM/YY'));
insert into autobuses (matricula, codmodelo, anyofabricacion, fechaadquisicion, fechaultimarevision)
values('0002GHV','MB1',2010,to_date('11/08/12','DD/MM/YY'),to_date('09/02/14','DD/MM/YY'));
insert into autobuses (matricula, codmodelo, anyofabricacion, fechaadquisicion, fechaultimarevision)
values('0003GHV','MB1',2011,to_date('12/08/12','DD/MM/YY'),to_date('09/04/14','DD/MM/YY'));
insert into autobuses (matricula, codmodelo, anyofabricacion, fechaadquisicion, fechaultimarevision)
values('0004GHV','MB9',2011,to_date('13/08/12','DD/MM/YY'),to_date('09/01/14','DD/MM/YY'));
insert into autobuses (matricula, codmodelo, anyofabricacion, fechaadquisicion, fechaultimarevision)
values('1002HBG','SC2',2012,to_date('14/08/12','DD/MM/YY'),to_date('09/05/14','DD/MM/YY'));
insert into autobuses (matricula, codmodelo, anyofabricacion, fechaadquisicion, fechaultimarevision)
values('1003HBG','SC2',2012,to_date('15/08/12','DD/MM/YY'),to_date('09/11/13','DD/MM/YY'));
insert into autobuses (matricula, codmodelo, anyofabricacion, fechaadquisicion, fechaultimarevision)
values('1004HBB','SC5',2012,to_date('16/08/12','DD/MM/YY'),to_date('09/12/13','DD/MM/YY'));

insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('A01',256,'Sevilla','Granada',12.40,190.40,165);
insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('A02',256,'Granada','Sevilla',12.40,190.40,165);
insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('A03',325,'Sevilla','Motril',15.50,230.40,210);
insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('A04',950,'Sevilla','Oviedo',52.40,690.40,630);
insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('A05',540,'Sevilla','Madrid',32,400,375);
insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('M01',540,'Madrid','Sevilla',32,400,375);
insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('M02',420,'Madrid','Valencia',27.20,250.50,315);
insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('M03',325,'Madrid','Granada',25.50,230.20,240);
insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('B01',350,'Bilbao','Oviedo',27,395,300);
insert into rutas (codigo, numkilometros, origen, destino, preciobillete, costeestimadoviaje, duracionenminutos)
values('B02',986,'Bilbao','Sevilla',45.70,610.50,675);


insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A01','0002GHV',to_date('17/06/14 09:00','DD/MM/YY HH24:MI'),14,1,3);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A01','1004HBB',to_date('17/06/14 12:00','DD/MM/YY HH24:MI'),11,1,3);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A01','0003GHV',to_date('17/06/14 15:00','DD/MM/YY HH24:MI'),8,1,3);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A01','0004GHV',to_date('17/06/14 18:00','DD/MM/YY HH24:MI'),4,2,2);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A01','1002HBG',to_date('17/06/14 21:00','DD/MM/YY HH24:MI'),2,2,2);

insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A02','7889GHG',to_date('16/06/14 09:30','DD/MM/YY HH24:MI'),63,1,3);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A02','7890GHG',to_date('16/06/14 12:30','DD/MM/YY HH24:MI'),55,1,3);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A02','0003GHV',to_date('16/06/14 15:30','DD/MM/YY HH24:MI'),65,1,3);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A02','0004GHV',to_date('16/06/14 18:30','DD/MM/YY HH24:MI'),33,2,2);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A02','1003HBG',to_date('16/06/14 21:30','DD/MM/YY HH24:MI'),60,2,2);

insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A03','7889GHG',to_date('15/06/14 09:30','DD/MM/YY HH24:MI'),63,21,13);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A03','7890GHG',to_date('15/06/14 12:30','DD/MM/YY HH24:MI'),55,23,12);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A03','0003GHV',to_date('15/06/14 15:30','DD/MM/YY HH24:MI'),65,24,14);

insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A04','0002GHV',to_date('17/06/14 09:30','DD/MM/YY HH24:MI'),13,1,2);

insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A05','1004HBB',to_date('17/06/14 08:45','DD/MM/YY HH24:MI'),25,23,12);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('A05','0002GHV',to_date('17/06/14 20:45','DD/MM/YY HH24:MI'),45,24,4);


insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('M01','1004HBB',to_date('18/06/14 08:45','DD/MM/YY HH24:MI'),11,23,12);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('M01','0002GHV',to_date('18/06/14 20:45','DD/MM/YY HH24:MI'),10,24,4);

insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('M02','0002GHV',to_date('14/06/14 09:30','DD/MM/YY HH24:MI'),30,21,13);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('M02','0003GHV',to_date('14/06/14 12:30','DD/MM/YY HH24:MI'),35,23,12);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('M02','0003GHV',to_date('14/06/14 15:30','DD/MM/YY HH24:MI'),23,24,14);

insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('M03','0002GHV',to_date('17/06/13 09:30','DD/MM/YY HH24:MI'),3,41,2);

insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('B01','7890GHG',to_date('16/06/14 18:45','DD/MM/YY HH24:MI'),55,3,12);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('B01','7889GHG',to_date('17/06/14 20:45','DD/MM/YY HH24:MI'),50,4,4);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('B01','7889GHG',to_date('18/06/14 20:45','DD/MM/YY HH24:MI'),52,4,4);

insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('B02','7889GHG',to_date('17/06/14 08:45','DD/MM/YY HH24:MI'),62,23,12);
insert into viajes (codruta, matricula, fechahorasalida, numbilletesvendidos, andensalida, andenllegada)
values('B02','7890GHG',to_date('17/06/14 20:45','DD/MM/YY HH24:MI'),55,24,4);
