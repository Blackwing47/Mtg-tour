# Turnierregeln und App-Vorgaben

Stand: 14.11.2026. Diese Datei hält fest, was für die Turnier-App entschieden wurde. Sie ist die Grundlage für den Code. Ändert sich eine Regel, wird sie zuerst hier geändert.

## Rahmen

- Format: Commander, vier Spieler pro Tisch, jeder gegen jeden.
- Tour: sechs Turniere, alle zwei Monate, Start im Februar 2027. Die Punkte aller Turniere werden addiert, der Toursieger wird am Ende gekürt.
- Erwartete Größe: 60 Teilnehmer, also 15 Tische.
- Ein Handy pro Tisch liegt in der Tischmitte und führt den Zähler.
- Partner-Commander sind erlaubt.

## Ablauf eines Turniertags

- Schweizer System: Alle Spieler spielen gleich viele Runden, niemand scheidet vorher aus.
- Runde 1: Die Tische werden zufällig gelost.
- Ab Runde 2: Spieler mit ähnlichem Punktestand sitzen zusammen, Wiederholungen werden möglichst vermieden.
- Die Rundenzahl richtet sich nach der Teilnehmerzahl wie in einem üblichen Turnier 1 gegen 1. Dafür zählt jeder Tisch als eine Paarung, also wie zwei Spieler:

| Tische | Spieler (bei Vierertischen) | Runden |
|---|---|---|
| 1 | 4 | 1 |
| 2 | 6 bis 8 | 2 |
| 3 bis 4 | 9 bis 16 | 3 |
| 5 bis 8 | 17 bis 32 | 4 |
| 9 bis 16 | 33 bis 64 | 5 |
| 17 bis 32 | 65 bis 128 | 6 |

- Bei 60 Teilnehmern sind das 15 Tische und 5 Runden.
- Die Turnierleitung kann die Rundenzahl von Hand festlegen.
- Ein zusätzlicher Finaltisch der vier Punktbesten ist möglich, aber standardmäßig aus, weil diese vier dann eine Runde mehr spielen.
- Geht die Teilnehmerzahl nicht durch vier auf, gibt es einzelne Dreiertische.
- Rangliste bei Punktgleichheit: erst Anzahl der Siege, dann Punkte der bisherigen Gegner.

## Nachträge und Abmeldungen

- Die Turnierleitung kann während des Turniers Spieler nachtragen und abmelden.
- Nachgetragene Spieler steigen ab der nächsten Auslosung mit 0 Punkten ein. Verpasste Runden werden nicht nachgeholt.
- Abgemeldete Spieler behalten ihre Punkte, bleiben in der Rangliste und werden nicht mehr gelost. Sie lassen sich zurückholen.
- Solange in einer Runde noch kein Tisch gemeldet hat, kann die Runde neu ausgelost werden. Dann gelten die Änderungen schon für diese Runde.
- Fällt ein Spieler während einer laufenden Partie aus, wertet der Tisch ihn als ausgeschieden (Aufgabe).

## Tourwertung

- Nach der letzten Runde eines Turniers wird die Rangliste in die Tourwertung übernommen.
- Die Tourwertung addiert die Punkte aller gespeicherten Turniere. Bei Punktgleichheit entscheiden die Siege, danach die beste Einzelplatzierung.
- Spieler werden über ihren Namen zugeordnet. Der Name muss deshalb in jedem Turnier gleich geschrieben sein, bis es Profile gibt.
- Die Rangliste eines laufenden Turniers zeigt zusätzlich den Tourstand einschließlich der laufenden Punkte.
- Im Prototyp liegt die Tourwertung nur auf dem Gerät der Turnierleitung. Sie lässt sich als Sicherungsdatei herunterladen und wieder einlesen.

## Punkte pro Partie

| Platz | Reguläres Ende | Ende durch Zeitablauf |
|---|---|---|
| 1 | 3 | 2 |
| 2 | 2 | 1 |
| 3 | 1 | 0 |
| 4 | 0 | 0 |

An Dreiertischen gibt es 3, 2 und 1 Punkt, bei Zeitablauf 2, 1 und 0.

Geteilte Plätze sind möglich. Alle Spieler auf einem geteilten Platz bekommen dessen Punkte, der nächste Spieler rückt direkt dahinter auf. Beispiel: Plätze 1, 2, 2, 3 ergeben 3, 2, 2, 1 Punkte.

## Ausscheiden

Ein Spieler scheidet aus bei:

- 0 oder weniger Lebenspunkten,
- 10 Giftmarken,
- 21 Kampfschaden von demselben Commander (Regel 903.10a). Partner zählen getrennt, verschiedene Gegner ebenfalls,
- einem Sonderfall: konnte nicht ziehen, Niederlage durch Karteneffekt, Aufgabe.

Wer ohne negative Lebenspunkte ausscheidet (Gift, Commander-Schaden, Sonderfall), wird auf 0 Lebenspunkte gesetzt.

Wer allein ausscheidet, bekommt den schlechtesten noch freien Platz.

Ob mehrere Spieler gleichzeitig ausscheiden, entscheidet der Tisch: Erst alle Schäden eintragen, dann einmal bestätigen. Alle, die in diesem Moment tödlich getroffen sind, gelten als gleichzeitig ausgeschieden.

## Zusatzrunde bei gleichzeitigem Ausscheiden

- Scheiden zwei oder drei Spieler gleichzeitig aus, spielen sie die gemeinsam frei werdenden Plätze unter sich aus.
- Jeder von ihnen ist noch genau einmal am Zug, im Uhrzeigersinn ab dem Startspieler der Partie. Jeder Zug wird in der App bestätigt.
- In der Zusatzrunde dürfen Lebenspunkte unter 0 sinken.
- Danach gilt: Der höchste Lebenspunktestand bekommt den besten der offenen Plätze. Gleicher Stand bedeutet geteilter Platz.
- Wer schon vorher ausgeschieden war, bleibt hinter dieser Gruppe.

## Zeitlimit

- Eine Runde dauert 60 Minuten. Der Timer läuft im Zähler mit und warnt in den letzten zehn Minuten.
- Nach Ablauf beginnt die Schlussrunde: Der aktive Spieler beendet seinen Zug, danach ist jeder noch lebende Spieler genau einmal dran.
- Danach werden die noch lebenden Spieler nach Lebenspunkten sortiert. Gleicher Stand bedeutet geteilter Platz. Bereits Ausgeschiedene behalten ihre hinteren Plätze.
- Es gilt die Punktespalte „Ende durch Zeitablauf“.
- Bleibt in der Schlussrunde nur ein Spieler übrig, hat er regulär gewonnen und bekommt 3 Punkte.

## Sieg durch Karteneffekt

Gewinnt ein Spieler durch einen Karteneffekt, scheiden alle anderen gleichzeitig aus und spielen die Zusatzrunde um die übrigen Plätze.

## Ergebnis melden

- Am Ende der Partie schlägt der Zähler die Platzierung vor und fragt, ob das Ergebnis stimmt. Der Tisch kann Plätze korrigieren.
- Nach der Bestätigung wird das Ergebnis an die Turnierleitung gemeldet. Die Turnierleitung sieht, welche Tische fertig sind.
- Sind alle Tische gemeldet, werden die nächsten Paarungen ausgelost und angezeigt.

## Zähler am Tisch

- Vier Felder, je zwei Spieler an den langen Seiten des Handys, zu ihnen gedreht.
- Lebenspunkte: Tippen ändert um 1, gedrückt halten um 10, dazu Knöpfe für 5.
- Zählerfeld pro Spieler: Monarch, Initiative, Aufstieg, Tag/Nacht, Energie, Erfahrung, Schatz, Gift, Rad, Commander-Steuer (getrennt pro Commander), K.o. mit den Sonderfällen.
- Commander-Schaden: eine Kachel pro gegnerischem Commander mit dessen Bild. Tippen zählt 1, gedrückt halten nimmt 1 zurück.
- Commander-Schaden senkt standardmäßig auch die Lebenspunkte.
- Jeder Schritt lässt sich rückgängig machen.

## Profile und Decks

- Jeder Spieler hat ein Profil mit Anzeigename.
- Im Profil lassen sich beliebig viele Decks speichern: Name, ein oder zwei Commander, Kartenliste.
- Für jedes Turnier meldet der Spieler eines seiner Decks an. Zum Turnierstart wird die Auswahl gesperrt.
- Namen und Commander-Bilder stehen dadurch im Zähler bereit, sobald ein Tisch ausgelost ist.
- Die Veranstalter bekommen Statistiken: gespielte Commander, Farbverteilung, Ergebnisse pro Commander und Farbe, meistgespielte Karten und Highlightkarten.

## Commander-Bilder

- Beim Eintragen eines Commanders schlägt die App passende Karten von Scryfall vor. Gesucht wird nach deutschen und englischen Namen.
- Gibt es mehrere Illustrationen, wählt der Spieler die aus seinem Deck. Vorausgewählt ist die neueste.
- Das Bild füllt das Spielerfeld im Zähler und die Kacheln für den Commander-Schaden. Bei Partnern teilen sich beide Bilder das Feld.
- Vorgaben von Scryfall: Bilder werden nicht verzerrt oder eingefärbt, und Illustrator sowie „© Wizards of the Coast“ stehen in der App (Einrichtung, Zählerfeld, Menü).

## Decklisten und Sammlung

- Decks kommen als Text oder Datei in die App. Das funktioniert mit dem Textexport von Moxfield, Archidekt, ManaBox und ähnlichen Apps sowie mit CSV-Dateien.
- Die App schlägt jede Karte bei Scryfall nach. Stehen Edition und Kartennummer in der Liste, wird genau diese Version übernommen, auch für das Bild des Commanders.
- Geprüft wird: 100 Karten einschließlich Commander, höchstens zwei Commander, Farbidentität, jede Karte nur einmal (Standardländer ausgenommen), verbotene Karten.
- Sideboard, Maybeboard und ähnliche Abschnitte werden nicht mitgezählt.
- Die Sammlung wird aus einer CSV-Datei eingelesen, zum Beispiel aus ManaBox. Im Deck steht dann, welche Karten in der Sammlung fehlen.
- Die Sammlung zeigt pro Karte die Gesamtzahl. Ein Tipp auf die Karte zeigt jede Fassung einzeln mit Edition, Kartennummer, Foil, Sprache und Anzahl.
- Jede Karte in Deck und Sammlung lässt sich antippen: Die App zeigt das Kartenbild, Kosten, Typ und Regeltext sowie einen Link zu Scryfall für Rulings.
- Im Zähler lässt sich pro Platz ein gespeichertes Deck wählen. Commander, Partner und Bilder werden übernommen.
- Ein direktes Verknüpfen von Konten bei Moxfield oder Archidekt ist nicht vorgesehen: Archidekt sperrt Abrufe aus fremden Webseiten, ein Abruf über einen Deck-Link bräuchte den eigenen Server.
- Im Prototyp liegen Decks und Sammlung nur auf dem jeweiligen Gerät.

## Weitere geplante Funktionen

- Kartenscan: Kartenname per Kamera erkennen, aktuellen Kartentext, Übersetzung und offizielle Rulings von Scryfall anzeigen.
- Regelsuche in den Comprehensive Rules.
- Judge-Assistent: Karten auf einem Foto des Spielfelds in Reihenfolge antippen, die KI erklärt Stack und Trigger mit Regelverweis. Das letzte Wort hat ein Mensch.

## Noch offen

- Ist die vollständige Deckliste Pflicht oder freiwillig? Angenommen wird vorerst: freiwillig, nur der Commander ist Pflicht.
- Sehen andere Spieler die gemeldeten Decks vor Turnierende?
- Aufgabe: Bekommt der Spieler automatisch den letzten offenen Platz? Bisher wird er wie bei Gift auf 0 gesetzt.
- Datenschutzerklärung und Einwilligung für die Anmeldung per E-Mail.
- Zeitlimit und Regeln für den Finaltisch.
