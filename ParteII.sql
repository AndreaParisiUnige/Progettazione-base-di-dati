-- NOTA: per testare il tutto sono stati utilizzati gli inserimenti proposti nel file "ParteII_popolamento.sql",
-- il quale contiene anche gli inserimenti relativi al carico di lavoro. Per testare certe richieste è stato necessario
-- introdurre nuove tuple manualmente oltre a quelle presenti, in tal caso abbiamo specificato le tuple introdotte
-- sotto ogni query/funzione

-- Creazione schema
create schema "OrtiScolastici";
set search_path to "OrtiScolastici";
set datestyle to "DMY";



CREATE TABLE Scuole(
    CodMec char(10) PRIMARY KEY,
    Nome varchar(50) NOT NULL,
    Provincia char(2) NOT NULL CHECK (Provincia SIMILAR TO '[A-Z]{2}'),
    CicloIst varchar(7) NOT NULL CHECK (cicloIst in ('primo','secondo')),
    TipoFin varchar(30),
    Partecipa boolean NOT NULL
);

CREATE TABLE Persone(
    Email varchar(100) PRIMARY KEY,
    Nome varchar(30) NOT NULL,
    Cognome varchar(30) NOT NULL,
    Telefono decimal(10,0),
    Ruolo varchar(30) NOT NULL,
    Tipo char(12) NOT NULL CHECK (tipo in ('finanziatore','partecipante')),
    Scuola varchar(10) REFERENCES Scuole (codMec) ON UPDATE CASCADE NOT NULL,
    UNIQUE(nome, cognome, telefono)
);

CREATE TABLE Classi(
    Sezione char(2),
    Ordine varchar(24) CHECK (Ordine in ('primario','secondario primo grado','secondario secondo grado')),
    Scuola varchar(10) REFERENCES Scuole (codMec) ON DELETE CASCADE ON UPDATE CASCADE,
    Tipo varchar(30) NOT NULL,
    Docente varchar(100) REFERENCES Persone (email) ON UPDATE CASCADE NOT NULL,
    PRIMARY KEY(Sezione, Ordine, Scuola),
    CHECK (
        (ordine = 'secondario primo grado' AND sezione SIMILAR TO '[1-3][A-Z]') OR
        (ordine IN ('primario', 'secondario secondo grado') AND sezione SIMILAR TO '[1-5][A-Z]')
    )
);

CREATE TABLE Orti(
    CodGPS varchar(30) PRIMARY KEY,
    Nome varchar(30) NOT NULL,
    Pulito boolean NOT NULL,
    Tipo varchar(14) NOT NULL CHECK(tipo in('in pieno campo','in vaso')),
    Superficie decimal(4,0) NOT NULL CHECK(Superficie>=0),
    Collabora boolean NOT NULL,
    NSensori decimal(3,0) NOT NULL CHECK(NSensori>=1),
    Scuola varchar(10) REFERENCES Scuole (codMec) ON UPDATE CASCADE NOT NULL,
	Dummy char(100) NOT NULL
);

CREATE TABLE Specie(
    NScientifico varchar(50) PRIMARY KEY,
    NRepliche decimal(4,0) NOT NULL CHECK(NRepliche>=0),
    NComune varchar(30) NOT NULL,
	Dummy char(100) NOT NULL
);

CREATE TABLE Gruppi(
    IDgruppo decimal(5,0) PRIMARY KEY, 
    CodGPS varchar(30) REFERENCES Orti (CodGPS) NOT NULL, 
    Scopo varchar(15) NOT NULL CHECK (scopo in ('biomonitoraggio','fitobotanica')),
    TipoGruppo varchar(15) CHECK( TipoGruppo in('di controllo','di monitoraggio')), 
    GruppoCorrispondente decimal(5,0) REFERENCES Gruppi (IDgruppo) ON DELETE CASCADE,
    CHECK((Scopo = 'fitobotanica' AND TipoGruppo IS NULL AND GruppoCorrispondente IS NULL) OR 
		  (Scopo = 'biomonitoraggio' AND TipoGruppo IS NOT NULL))
);

CREATE TABLE Piante(
    NReplica decimal(4,0) CHECK(NReplica>=1),
    NScientifico varchar(50) REFERENCES Specie(NScientifico) ON DELETE NO ACTION ON UPDATE CASCADE, 
    Esposizione varchar(30) NOT NULL,
    Data_p date NOT NULL,
    Gruppo decimal(5,0) REFERENCES Gruppi (IDgruppo) ON DELETE CASCADE ON UPDATE NO ACTION NOT NULL ,
    CodGPS varchar(30) REFERENCES Orti (CodGPS) ON DELETE CASCADE ON UPDATE NO ACTION NOT NULL ,
    Scuola varchar(10)  NOT NULL ,
    Sezione char(2)  NOT NULL ,
    Ordine varchar(24) NOT NULL ,
	Dummy char(100) NOT NULL,
    PRIMARY KEY(NReplica, NScientifico),
	FOREIGN KEY (Scuola, Sezione, Ordine) REFERENCES Classi (Scuola, Sezione, Ordine)
	
);

CREATE TABLE Dispositivi(
    IdDisp decimal(5,0) PRIMARY KEY,
    Tipo char(7) NOT NULL CHECK (tipo in('arduino','sensore')),
    CodGPS varchar(30) REFERENCES Orti (CodGPS) NOT NULL,
    NReplica decimal(4,0) NOT NULL,
    NScientifico varchar(50)  NOT NULL,
	FOREIGN KEY (NReplica, NScientifico) REFERENCES Piante (NReplica, NScientifico)
);

CREATE TABLE Rilevazioni(
    numRil decimal(5,0) PRIMARY KEY,
    TimeIns date NOT NULL CHECK(TimeIns>=TimeRil),
    TimeRil date NOT NULL,
    Modalità varchar(30) NOT NULL CHECK (Modalità in('manuale','automatica', 'app')),
    Dispositivo decimal(5,0) REFERENCES Dispositivi(IdDisp) NOT NULL,
	Dummy char(100) NOT NULL
);

CREATE TABLE Inserisce(
    Rilevazione decimal(5,0) PRIMARY KEY REFERENCES Rilevazioni(numRil) ON DELETE CASCADE, 
    Scuola varchar(10), 
    Sezione char(2), 
    Ordine varchar(24),
    ResponsabileIns varchar(100) REFERENCES Persone (email),
	FOREIGN KEY (Scuola, Sezione, Ordine) REFERENCES Classi (Scuola, Sezione, Ordine),
    CHECK (
        (ResponsabileIns IS NULL AND (Scuola IS NOT NULL AND Sezione IS NOT NULL AND Ordine IS NOT NULL)) OR
        (ResponsabileIns IS NOT NULL AND (Scuola IS NULL AND Sezione IS NULL AND Ordine IS NULL))
    )
);

CREATE TABLE EffettuaRil(
    Rilevazione decimal(5,0) PRIMARY KEY REFERENCES Rilevazioni(numRil) ON DELETE CASCADE,
    Scuola varchar(10),
    Sezione char(2), 
    Ordine varchar(24),
    ResponsabileRil varchar(100) REFERENCES Persone (email),
	FOREIGN KEY (Scuola, Sezione, Ordine) REFERENCES Classi (Scuola, Sezione, Ordine),
    CHECK (
        (ResponsabileRil IS NULL AND (Scuola IS NOT NULL AND Sezione IS NOT NULL AND Ordine IS NOT NULL)) OR
        (ResponsabileRil IS NOT NULL AND (Scuola IS NULL AND Sezione IS NULL AND Ordine IS NULL))
    )
);

CREATE TABLE Informazioni (
    Rilevazione decimal(5,0) PRIMARY KEY REFERENCES Rilevazioni(numRil),
    LunghFoglie decimal(4,1) NOT NULL CHECK (LunghFoglie >= 0),
    LarghFoglie decimal(4,1) NOT NULL CHECK (LarghFoglie >= 0),
    PesoSeccoFoglie decimal(4,1) NOT NULL CHECK (PesoSeccoFoglie >= 0),
    PesoFrescoFoglie decimal(4,1) NOT NULL CHECK (PesoFrescoFoglie >= 0),
    AltezzaPianta decimal(5,0) NOT NULL CHECK (AltezzaPianta >= 0),
    LunghRadice decimal(5,0) NOT NULL CHECK (LunghRadice >= 0),
    Temperatura decimal(3,1) NOT NULL,
    Umidità decimal(3,0) NOT NULL CHECK (Umidità >= 0),
    Ph decimal(3,1) NOT NULL CHECK (Ph >= 0),
    Lux decimal(4,0) CHECK (Lux >= 0),
    Pressione decimal(3,0) CHECK (Pressione >= 0),
    EC decimal(3,1) NOT NULL CHECK (EC >= 0),
    PesoSeccoRadici decimal(5,1) NOT NULL CHECK (PesoSeccoRadici >= 0),
    PesoFrescoRadici decimal(5,1) NOT NULL CHECK (PesoFrescoRadici >= 0),
    NFiori decimal(3,0) CHECK (NFiori >= 0),
    NFrutti decimal(3,0) CHECK (NFrutti >= 0),
    NFoglieDanneggiate decimal(3,0) NOT NULL CHECK (NFoglieDanneggiate >= 0),
    Danno decimal(3,0) NOT NULL CHECK (Danno >= 0)
);

--------------------------------------------------------------------------------------------------------------------------

-- B. 	La definizione di una vista che fornisca alcune informazioni riassuntive per ogni attività di biomonitoraggio: per
-- 		ogni gruppo e per il corrispondente gruppo di controllo mostrare il numero di piante, la specie, l’orto in cui è
-- 		posizionato il gruppo e, su base mensile, il valore medio dei parametri ambientali e di crescita delle piante (selezionare
-- 		almeno tre parametri, quelli che si ritengono più significativi).
CREATE VIEW InfoBiom AS (

	SELECT 	G1.IDGruppo1, EXTRACT (MONTH FROM R1.TimeRil) AS MeseGruppo1, P1.NScientifico, G1.codGPS AS OrtoGruppo1, COUNT(G1.IDGruppo) AS NumPianteGruppo1, 
			AVG(I1.Temperatura) AS TemperaturaGruppo1, AVG(I1.AltezzaPianta) AS AltezzaPiantaGruppo1, AVG(I1.PesoFrescoFoglie) AS PesoFoglieGruppo1,
			G2.IDGruppo2, G2.MeseGruppo2, G2.OrtoGruppo2, G2.NumPianteGruppo2 , G2.TemperaturaGruppo2, G2.AltezzaPiantaGruppo2 , G2.PesoFoglieGruppo2

	FROM    Gruppi AS G1 JOIN Piante AS P1 ON G1.IDgruppo = P1.Gruppo 
			JOIN Dispositivi AS D1 ON D1.NReplica = P1.NReplica AND D1.NScientifico = P1.NScientifico
			JOIN Rilevazioni AS R1 ON D1.IdDisp = R1.Dispositivo
			JOIN Informazioni AS I1 ON I1.Rilevazione = R1.numRil
			JOIN(
				SELECT 	G2.IDGruppo AS IDGruppo2, EXTRACT (MONTH FROM R2.TimeRil) AS MeseGruppo2, G2.codGPS AS OrtoGruppo2, COUNT(G2.IDGruppo) AS NumPianteGruppo2, 
				AVG(I2.Temperatura) AS TemperaturaGruppo2, AVG(I2.AltezzaPianta) AS AltezzaPiantaGruppo2, AVG(I2.PesoFrescoFoglie) AS PesoFoglieGruppo2

				FROM Gruppi AS G2 JOIN Piante AS P2 ON G2.IDgruppo = P2.Gruppo 
				JOIN Dispositivi AS D2 ON D2.NReplica = P2.NReplica AND D2.NScientifico = P2.NScientifico
				JOIN Rilevazioni AS R2 ON D2.IdDisp = R2.Dispositivo
				JOIN Informazioni AS I2 ON I2.Rilevazione = R2.numRil
				
				WHERE G2.Scopo = 'biomonitoraggio' AND G2.TipoGruppo = 'di controllo'
				GROUP BY G2.IDGruppo, R2.TimeRil, P2.NScientifico, G2.codGPS
			) AS G2 ON G1.GruppoCorrispondente = G2.IDGruppo2

	WHERE G1.Scopo = 'biomonitoraggio' AND G1.TipoGruppo = 'di monitoraggio' 
	GROUP BY G1.IDGruppo, R1.TimeRil, P1.NScientifico, G1.codGPS, G2.IDGruppo2, G2.MeseGruppo2, G2.OrtoGruppo2,G2.NumPianteGruppo2 , G2.TemperaturaGruppo2, G2.AltezzaPiantaGruppo2 , G2.PesoFoglieGruppo2
	ORDER BY G1.IDGruppo 
)


----------------------------------------------------------------------------------------------------------------------
-- C. Le seguenti interrogazioni:
--	a. Determinare le scuole che, pur avendo un finanziamento per il progetto, non hanno inserito rilevazioni
--	   in questo anno scolastico;
SELECT DISTINCT CodMec, Nome 
FROM Scuole JOIN Classi ON CodMec = Classi.Scuola 
    JOIN Inserisce ON Inserisce.Scuola = Classi.Scuola   
	JOIN Rilevazioni ON Rilevazione = numRil
WHERE TipoFin IS NOT NULL AND EXTRACT (YEAR FROM TimeIns) != EXTRACT (YEAR FROM CURRENT_DATE);                                                                       




--	b. Determinare le specie utilizzate in tutti i comuni in cui ci sono scuole aderenti al progetto
SELECT Piante.NScientifico
FROM Piante JOIN Scuole ON Piante.scuola = Scuole.CodMec 
WHERE partecipa = True
GROUP BY NScientifico
HAVING COUNT(provincia) = (  SELECT COUNT(provincia)
                             FROM Scuole
                             WHERE partecipa = True);


-- Inserimenti da effettuare in seguito al popolamento della base dati per testare la query
INSERT INTO Classi (sezione, ordine, scuola, tipo, docente) VALUES
('1G', 'secondario primo grado', '27974888', 'ms8FmS6yNpRb3NFN8St', 'EFreed@lycos.dk'),
('1G', 'secondario primo grado', '20264416', 'ms8FmS6yNpRb3NFN8St', 'EFreed@lycos.dk');

INSERT INTO Piante (nreplica, nscientifico, esposizione, data_p, gruppo, codgps, scuola, sezione, ordine, dummy) VALUES
(2, 'uu', 'crK', '2018-07-23', 3, 'FyTHAZNlkdYCkwi', '10918660', '5G', 'primario', 'FcmUjXv6eZ6PW6SPQ8BebMr788p3aJ'),
(3, 'uu', 'crK', '2018-07-23', 3, 'FyTHAZNlkdYCkwi', '20264416', '1G', 'secondario primo grado', 'FcmUjXv6eZ6PW6SPQ8BebMr788p3aJ'),
(4, 'uu', 'crK', '2018-07-23', 3, 'FyTHAZNlkdYCkwi', '27974888', '1G', 'secondario primo grado', 'FcmUjXv6eZ6PW6SPQ8BebMr788p3aJ'),
(5, 'uu', 'crK', '2018-07-23', 3, 'FyTHAZNlkdYCkwi', '57837145', '5Y', 'primario', 'FcmUjXv6eZ6PW6SPQ8BebMr788p3aJ'),
(6, 'uu', 'crK', '2018-07-23', 3, 'FyTHAZNlkdYCkwi', '64725191', '2B', 'secondario primo grado', 'FcmUjXv6eZ6PW6SPQ8BebMr788p3aJ'),
(7, 'uu', 'crK', '2018-07-23', 3, 'FyTHAZNlkdYCkwi', '70326708', '1K', 'secondario primo grado', 'FcmUjXv6eZ6PW6SPQ8BebMr788p3aJ'),
(8, 'uu', 'crK', '2018-07-23', 3, 'FyTHAZNlkdYCkwi', '76449756', '2A', 'secondario primo grado', 'FcmUjXv6eZ6PW6SPQ8BebMr788p3aJ'),
(9, 'uu', 'crK', '2018-07-23', 3, 'FyTHAZNlkdYCkwi', '84407533', '2W', 'primario', 'FcmUjXv6eZ6PW6SPQ8BebMr788p3aJ');



--	c. Determinare per ogni scuola l’individuo/la classe della scuola che ha effettuato più rilevazioni.

-- Inseriamo l'individuo e la classe che ha effettuato più rilevazioni in una stessa colonna, con relativo numero di rilevazioni associato
SELECT R.Rilevazione, R.NRilevazioniEffettuate
FROM(
	-- L'individuo che ha effettuato il maggior numero di rilevazioni
    SELECT ResponsabileRil AS Rilevazione, COUNT(rilevazione) AS NRilevazioniEffettuate
    FROM EffettuaRil 
	WHERE ResponsabileRil IS NOT NULL
    GROUP BY ResponsabileRil 
    HAVING COUNT(rilevazione) >= ALL ( 
                                    SELECT COUNT (DISTINCT rilevazione) 
                                    FROM EffettuaRil 
									WHERE ResponsabileRil IS NOT NULL
                                    GROUP BY ResponsabileRil 
                                    )
 
    UNION 

	-- La classe che ha effettuato il maggior numero di rilevazioni
    SELECT CONCAT_WS(' ',Scuola, Sezione, Ordine) AS Rilevazione, COUNT(rilevazione) AS NRilevazioniEffettuate
    FROM EffettuaRil 
	WHERE Sezione IS NOT NULL AND Ordine IS NOT NULL AND Scuola IS NOT NULL
    GROUP BY Sezione, Ordine, Scuola 
    HAVING COUNT(rilevazione) >= ALL ( 
                                    SELECT COUNT (DISTINCT rilevazione) 
                                    FROM EffettuaRil 
									WHERE Sezione IS NOT NULL AND Ordine IS NOT NULL AND Scuola IS NOT NULL
                                    GROUP BY Sezione, Ordine, Scuola 
                                    )
) AS R
	-- Selezionimao delle 2 tuple ottenute, quella con più rilevazioni associate
ORDER BY NRilevazioniEffettuate DESC
LIMIT 1;


-- Seconda opzione più complessa per selezionare l'elemento con più rilevazioni associate (al posto di limitare le tuple a 1)
	WHERE NRilevazioniEffettuate >= ALL (   SELECT COUNT(rilevazione) AS NRilevazioniEffettuate
											FROM EffettuaRil 
											WHERE ResponsabileRil IS NOT NULL
											GROUP BY ResponsabileRil 
											HAVING COUNT(rilevazione) >= ALL ( 
												SELECT COUNT (DISTINCT rilevazione) 
												FROM EffettuaRil 
												WHERE ResponsabileRil IS NOT NULL
												GROUP BY ResponsabileRil 
											)
	
											UNION 

											SELECT COUNT(rilevazione) AS NRilevazioniEffettuate
											FROM EffettuaRil 
											WHERE Sezione IS NOT NULL AND Ordine IS NOT NULL AND Scuola IS NOT NULL
											GROUP BY Sezione, Ordine, Scuola 
											HAVING COUNT(rilevazione) >= ALL ( 
												SELECT COUNT (DISTINCT rilevazione) 
												FROM EffettuaRil 
												WHERE Sezione IS NOT NULL AND Ordine IS NOT NULL AND Scuola IS NOT NULL
												GROUP BY Sezione, Ordine, Scuola 
												)
										)


----------------------------------------------------------------------------------------------------------------------

--  D.  Le seguenti procedure/funzioni:
--  a. funzione che realizza l’abbinamento tra gruppo e gruppo di controllo nel caso di operazioni di biomonitoraggio;
CREATE PROCEDURE AccoppiaGruppi () AS 
	
	$$
	DECLARE
    Gruppo1 decimal(5,0);
    Gruppo2 decimal(5,0);
	
    GruppiDiControllo CURSOR FOR    
        SELECT IDGruppo FROM Gruppi WHERE Scopo = 'biomonitoraggio' AND GruppoCorrispondente IS NULL AND TipoGruppo = 'di controllo' FOR UPDATE;

    GruppiDiMonitoraggio CURSOR FOR    
        SELECT IDGruppo FROM Gruppi WHERE Scopo = 'biomonitoraggio' AND GruppoCorrispondente IS NULL AND TipoGruppo = 'di monitoraggio' FOR UPDATE;
		
	BEGIN
		OPEN GruppiDiControllo;
		FETCH GruppiDiControllo INTO Gruppo1;

		OPEN GruppiDiMonitoraggio;
		FETCH GruppiDiMonitoraggio INTO Gruppo2;

		WHILE FOUND LOOP
			BEGIN
				UPDATE Gruppi
				SET GruppoCorrispondente = Gruppo2 
				WHERE CURRENT OF GruppiDiControllo;

				UPDATE Gruppi
				SET GruppoCorrispondente = Gruppo1
				WHERE CURRENT OF GruppiDiMonitoraggio;

			FETCH GruppiDiControllo INTO Gruppo1;
			IF NOT FOUND THEN
				EXIT;
			END IF;
			
			FETCH GruppiDiMonitoraggio INTO Gruppo2;
			END;
		END LOOP;

		CLOSE GruppiDiControllo;
		CLOSE GruppiDiMonitoraggio;
	END;
	
	$$ LANGUAGE plpgsql;
	
CALL AccoppiaGruppi();


--  b. funzione che corrisponde alla seguente query parametrica: data una replica con finalità di fitobonifica e
--  due date, determina i valori medi dei parametri rilevati per tale replica nel periodo compreso
--  tra le due date.
CREATE FUNCTION ParametriMedi (Replica decimal(4,0), NomeScientifico varchar(50), DataInizio date, DataFine date)  
	RETURNS TABLE 	(AVGLunghFoglie decimal(4,1), AVGLarghFoglie decimal(4,1), AVGPesoSeccoFoglie decimal(4,1), AVGPesoFrescoFoglie decimal(4,1), 
					AVGAltezzaPianta decimal(5,0), AVGLunghRadice decimal(5,0), AVGPesoSeccoRadici decimal(5,1), AVGPesoFrescoRadici decimal(5,1), 
					AVGNFoglieDanneggiate decimal(3,0), AVGDanno decimal(3,0)) AS
	$$
	DECLARE
	finalità varchar(15);

    BEGIN
		IF(Replica IS NOT NULL) THEN
			SELECT Scopo INTO finalità
			FROM Piante AS P JOIN Gruppi ON P.Gruppo = IDGruppo
			WHERE P.NReplica = Replica AND P.NScientifico = NScientifico;
			IF(finalità != 'fitobotanica') THEN 
				RAISE EXCEPTION 'La finalità della replica è diversa da fitobotanica';
			END IF;
			
			RETURN QUERY
			SELECT 	AVG(LunghFoglie), AVG(LarghFoglie), AVG(PesoSeccoFoglie), AVG(PesoFrescoFoglie), AVG(AltezzaPianta), AVG(LunghRadice), AVG(PesoSeccoRadici),
					AVG(PesoFrescoRadici), AVG(NFoglieDanneggiate), AVG(Danno)
			FROM Piante AS P JOIN Dispositivi AS D ON (P.NReplica = D.NReplica AND P.NScientifico = D.NScientifico)
			JOIN Rilevazioni AS R ON D.IdDisp = R.Dispositivo JOIN Informazioni AS I ON R.numRil = I.Rilevazione
			WHERE P.NReplica = Replica AND P.NScientifico = NomeScientifico AND (R.TimeRil >= DataInizio AND R.TimeRil <= DataFine);
		END IF;
    END;

    $$ LANGUAGE plpgsql;

-- Una possibile query per testare la funzione (occorre aver già popolato la base dati)
 SELECT *
 FROM parametrimedi(65, 'iq8RpX18zrYbxSDX0Gy8rI187BvoI', '2000/01/01', '2020/01/01')


----------------------------------------------------------------------------------------------------------------------

-- E. I seguenti trigger:
-- a. verifica del vincolo che ogni scuola dovrebbe concentrarsi su tre specie e ogni gruppo dovrebbe
-- contenere 20 repliche;
-- NOTA --> gli inserimenti proposti violano tale trigger, occorre disattivarlo per popolare la base dati

CREATE FUNCTION SpecieRepliche() RETURNS trigger AS
	$$
	BEGIN
		IF(	SELECT COUNT(NScientifico)
			FROM Piante 
			WHERE Scuola = NEW.scuola) > 3 THEN RAISE EXCEPTION 'La scuola specificata si occupa già di 3 specie';
		ELSEIF (	SELECT COUNT(*)
					FROM Piante 
					WHERE Gruppo = NEW.gruppo) > 20 THEN RAISE EXCEPTION 'Il gruppo specificato contiene già 20 repliche';
		END IF;
		RETURN NEW;
	END;

	$$ LANGUAGE plpgsql;


CREATE TRIGGER VerificaRepliche_Specie
BEFORE INSERT ON Piante
FOR EACH ROW
EXECUTE FUNCTION SpecieRepliche();



-- b. generazione di un messaggio (o inserimento di una informazione di warning in qualche tabella)
-- quando viene rilevato un valore decrescente per un parametro di biomassa.

CREATE FUNCTION valoreDecrescente() RETURNS trigger AS
	$$
	DECLARE 
	LunghFoglieAux decimal(4,1);
	LarghFoglieAux decimal(4,1); 
	PesoSeccoFoglieAux decimal(4,1);
	PesoFrescoFoglieAux decimal(4,1);
	AltezzaPiantaAux decimal(5,0);
	LunghRadiceAux decimal(5,0);

	Replica decimal(4,0);
	NomePianta varchar(50);
	RilPrecedente decimal(5,0);

	BEGIN

		-- Guardo su che pianta è stata effettuata la rilevazione inserita
		SELECT P.Nreplica, P.NScientifico INTO Replica, NomePianta
		FROM Rilevazioni AS R JOIN Dispositivi AS D ON R.dispositivo = D.IdDisp
		JOIN Piante AS P ON (P.NReplica = D.NReplica AND P.NScientifico = D.NScientifico)
		WHERE R.numRil = NEW.Rilevazione;

		-- Prendo l'ultima rilevazione su tale pianta
		SELECT numRil INTO RilPrecedente
		FROM Informazioni AS I JOIN Rilevazioni AS R ON I.Rilevazione = R.numRil
		JOIN Dispositivi AS D ON D.IdDisp = R.dispositivo 
		JOIN Piante AS P ON (P.NReplica = D.NReplica AND P.NScientifico = D.NScientifico)
		WHERE P.NScientifico = NomePianta AND P.NReplica = Replica AND
				TimeRil < (	SELECT TimeRil
							FROM Informazioni AS I JOIN Rilevazioni AS R ON I.Rilevazione = R.numRil
							JOIN Dispositivi AS D ON R.dispositivo = D.IdDisp 
							JOIN Piante AS P ON (P.NReplica = D.NReplica AND P.NScientifico = D.NScientifico)
							WHERE P.NScientifico = NomePianta AND P.NReplica = Replica AND R.numRil = NEW.Rilevazione)
		ORDER BY TimeRil DESC
		LIMIT 1;
							
		-- Seleziono i parametri per tale rilevazione
		
		IF EXISTS (
			SELECT LunghFoglie, LarghFoglie, PesoSeccoFoglie, PesoFrescoFoglie, AltezzaPianta, LunghRadice 
			FROM Informazioni
			WHERE Rilevazione = RilPrecedente AND
			(LunghFoglie > NEW.LunghFoglie OR LarghFoglie > NEW.LarghFoglie OR PesoSeccoFoglie > NEW.PesoSeccoFoglie 
			OR PesoFrescoFoglie > NEW.PesoFrescoFoglie OR AltezzaPianta > NEW.AltezzaPianta OR LunghRadice > NEW.LunghRadice))

			THEN RAISE NOTICE 'Rilevato valore decrescente per un parametro di biomassa';
		END IF;
		RETURN NEW;
	END;

	$$ LANGUAGE plpgsql;



CREATE TRIGGER VerificaDecrescente
AFTER INSERT ON Informazioni
FOR EACH ROW
EXECUTE FUNCTION valoreDecrescente();


-- Possibili inserimenti per testare il trigger (occorre aver già popolato la base dati per disporre delle rilevazioni associate):
INSERT INTO informazioni (rilevazione, lunghfoglie, larghfoglie, pesoseccofoglie, pesofrescofoglie, altezzapianta, lunghradice, temperatura, umidità, ph, lux, pressione, ec, pesoseccoradici, pesofrescoradici, nfiori, nfrutti, nfogliedanneggiate, danno) VALUES
(758, 300, 30, 2.6, 30, 239, 3, 8.6, 6, 4.1, '1', '104', 73.5, 81.2, 1.0, NULL, '36', 745, 98);

INSERT INTO informazioni (rilevazione, lunghfoglie, larghfoglie, pesoseccofoglie, pesofrescofoglie, altezzapianta, lunghradice, temperatura, umidità, ph, lux, pressione, ec, pesoseccoradici, pesofrescoradici, nfiori, nfrutti, nfogliedanneggiate, danno) VALUES
(760, 336.1, 29, 2.6, 33.5, 239, 3, 8.6, 6, 4.1, '1', '104', 73.5, 81.2, 1.0, NULL, '36', 745, 98);

INSERT INTO informazioni (rilevazione, lunghfoglie, larghfoglie, pesoseccofoglie, pesofrescofoglie, altezzapianta, lunghradice, temperatura, umidità, ph, lux, pressione, ec, pesoseccoradici, pesofrescoradici, nfiori, nfrutti, nfogliedanneggiate, danno) VALUES
(759, 200, 30, 2.6, 30, 5, 3, 8.6, 6, 4.1, '1', '104', 73.5, 81.2, 1.0, NULL, '36', 745, 98);