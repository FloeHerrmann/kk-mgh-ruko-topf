float temperature = 60.0;
float target = 80.0;

void setup() {
	Serial3.begin( 9600 );
}

void loop() {
	
	// Daten an den nodeMCU müssen im Format {Aktuelle Temp.};{Zieltemp.}<CR> übertragenwerden
	// Beispiel: 67.5;80.0\r

	String output = "";
	output += temperature;
	output += ";";
	output += target;
	output += "\r";

	Serial3.print( output );

	temperature += 2.1;
	delay( 7000 );
}