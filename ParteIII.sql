--Script SQL per la creazione dello schema fisico della base di dati 

CREATE INDEX idxRil ON Rilevazioni USING HASH (timeRil);

CREATE INDEX idxPiante ON Piante(gruppo);
CLUSTER Piante USING idxPiante;

CREATE INDEX idxOrti ON Orti (Nsensori, Superficie);

-----------------------------------------------------------------------------------------------------------------------

-- Specifica delle interrogazioni contenute nel carico di lavoro, con la corrispondente richiesta in linguaggio naturale


-- 1° QUERY: seleziona tutte le rilevazioni effettuate in data '2003\06\22'

SELECT *
FROM Rilevazioni
WHERE timeRil = '2003\06\22';


-- 2° QUERY: seleziona il nome comune delle specie per le quali sono state piantate delle repliche nel gruppo n° 20.

SELECT NComune
FROM Piante JOIN Specie ON Piante.Nscientifico = Specie.Nscientifico
WHERE Piante.gruppo = 20;


-- 3° QUERY: seleziona il nome degli orti “nel pulito” in cui sono presenti 10 sensori, e che hanno una superficie maggiore di 100 m2.

SELECT Nome
FROM Orti 
WHERE Nsensori = 10 AND Superficie > 100 AND Pulito = true;



-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------



--Script SQL per l’implementazione della politica di controllo dell’accesso.

-- CREAZIONE RUOLI
CREATE ROLE insegnante;
CREATE ROLE gestoreGlobaleProgetto;
CREATE ROLE referenteScuola;
CREATE ROLE studente;

-- Assegnazione privilegi a studente 
GRANT select, insert, update, delete ON Piante TO studente;
GRANT select, insert, update ON Informazioni, EffettuaRil, Inserisce, Specie TO studente;
GRANT select, insert ON Rilevazioni TO studente;
GRANT select ON Classi, Orti, Gruppi, Dispositivi TO studente;


-- Assegnazione privilegi a insegnante 
GRANT studente TO insegnante;

GRANT select ON Scuole, Persone, Classi, Orti, Dispositivi TO insegnante ;
GRANT delete ON Informazioni, EffettuaRil, Inserisce, Specie, Rilevazioni TO insegnante ;
GRANT delete, update ON Rilevazioni TO insegnante;
GRANT delete, update, insert ON Gruppi TO insegnante;



-- Assegnazione privilegi a referenteScuola
GRANT insegnante TO referenteScuola;

GRANT delete, update, insert ON Persone, Classi, Orti, Dispositivi TO referenteScuola;



-- Assegnazione privilegi a gestoreGlobaleProgetto
GRANT referenteScuola TO gestoreGlobaleProgetto;

GRANT delete, update, insert ON Scuole TO gestoreGlobaleProgetto;



-- Creazione degli utenti richiesti
CREATE USER nomeutente1 PASSWORD '1';
CREATE USER nomeutente2 PASSWORD '2';
CREATE USER nomeutente3 PASSWORD '3';
CREATE USER nomeutente4 PASSWORD '4';


-- Assegnazione dei ruoli agli utenti
GRANT gestoreGlobaleProgetto to Nomeutente1
WITH ADMIN OPTION;
GRANT referenteScuola to Nomeutente2;
GRANT insegnante to Nomeutente3;
GRANT studente to Nomeutente4;