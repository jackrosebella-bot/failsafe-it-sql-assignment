# FailSafe IT – databasuppgift

Det här paketet innehåller ett SQL Server-skript och ett ER-diagram för uppgiften. Exempelpersoner, telefonfält och organisationsnummer är testdata och inte riktiga person- eller företagsuppgifter.

## Filer

- `FailSafeIT.sql` – skapar databasen `FailSafeIT`, tabeller, index och testdata samt kör frågorna A–E.
- `ER-diagram.svg` – ER-diagram som visar primärnycklar, främmande nycklar och relationer.

## Datamodell

`Customers` innehåller kunduppgifter och `Consultants` konsultuppgifter. `Assignments` kopplar varje uppdrag till en kund och en konsult. Därför blir relationen mellan kunder och konsulter många-till-många över tid, upplöst genom uppdragstabellen: en kund kan ha många uppdrag och en konsult kan arbeta på många uppdrag.

**Aktivt uppdrag** definieras i skriptet som ett uppdrag där dagens datum ligger mellan startdatum och slutdatum, inklusive båda datumen. Fråga C använder `LEFT JOIN`, så även kunder utan aktiva uppdrag visas med antalet noll.

## Köra skriptet

1. Öppna `FailSafeIT.sql` i Visual Studio med en SQL Server-anslutning eller i SQL Server Management Studio.
2. Anslut till SQL Server LocalDB eller en SQL Server-instans.
3. Kör hela skriptet. Det skapar databasen om den saknas och använder därefter databasen `FailSafeIT`.

Skriptet är avsett att köras en gång mot en ny databas. Det tar inte bort befintliga tabeller eller data.

## Normalisering till 3NF

Tabellerna uppfyller **1NF** eftersom varje kolumn innehåller ett enskilt värde och inga kolumner lagrar listor. De uppfyller **2NF** eftersom varje tabell har en enkel primärnyckel och övriga kolumner beskriver hela raden. De uppfyller **3NF** eftersom kunduppgifter bara finns i `Customers`, konsultuppgifter bara finns i `Consultants` och `Assignments` innehåller främmande nycklar samt uppdragets egna datum och rollbeskrivning. Därmed kopieras inte företagsnamn eller konsultnamn till varje uppdragsrad, och inga icke-nyckelkolumner är beroende av andra icke-nyckelkolumner.

## DevSecOps-reflektion

**Sec – SQL Injection:** Använd parametriserade SQL-frågor så att text från användaren behandlas som data och inte byggs in i SQL-kommandot. Ge applikationens databaskonto endast de behörigheter som behövs och undvik att använda ett administratörskonto i webbappen.

**Ops – sökhastighet:** Ett index på `OrganizationNumber` gör exakta sökningar snabbare när kundtabellen växer. Skriptet skapar ett unikt icke-klustrat index, vilket både hjälper sökningar och hindrar dubbletter.

## Viktigt om DELETE-frågan

Fråga E visar en kund utan aktiva uppdrag. I testdatan har kunden inte heller några historiska uppdragsrader, så främmande nyckeln tillåter borttagningen. Om avslutade uppdrag finns kvar bör de normalt bevaras; i ett verkligt system är det ofta bättre att markera kunden som inaktiv än att radera historiken.
