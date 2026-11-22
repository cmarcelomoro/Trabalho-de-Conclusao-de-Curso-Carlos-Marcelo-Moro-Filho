#include <Esp.h>
#include <Rfid134.h>
#include "Display.hpp"
#include "Leitura.hpp"
#include "Utilidades.hpp"
#include "time.h"
#include "ConexaoBluetooth.hpp"


#define HardwareSerial_Rx 16
#define HardwareSerial_Tx 17
const int buzzerPin = 25;
Display display;
Leitura leitura;
uint64_t ID_Number;
ConexaoBluetooth bt;
String statusConexao;

class RfidNotify
{

  public:
    static void OnError(Rfid134_Error errorCode)
    {
      Serial.println();
      Serial.print("Com Error ");
      Serial.println(errorCode);
      display.renderizarTexto("Erro na Leitura");
    }

    static void OnPacketRead(const Rfid134Reading& reading)
    {
      char temp[8];
      
      Serial.print("TAG: ");

      sprintf(temp, "%03u", reading.country);
      Serial.print(temp);

      Serial.print(" ");
    
      ID_Number = reading.id;

      Serial.println(ID_Number);      
      Serial.println("Ligando Buzzer");

     
      leitura.atualizar(ID_Number);
      bt.enviarDados(Utilidades::brincoString(ID_Number));
      if(ID_Number){
          digitalWrite(buzzerPin, LOW);
          delay(250);
          digitalWrite(buzzerPin, HIGH);
          delay(250);
          digitalWrite(buzzerPin,LOW);
      }
    }
};

Rfid134<HardwareSerial, RfidNotify> rfid(Serial2);

void configurarTempo(){
   configTime(-3 * 3600,0,"pool.ntp.org","time.nist.gov");
}

void setup()
{
  configurarTempo();
  display.iniciarDisplay();
  bt.iniciar("Dispositivo de Leitura");
  Serial.begin(115200);
  display.renderizarTexto("Aguardando Leitura...");
  Serial.println("initializing...");
  Serial.println("Buzzer");
  pinMode(buzzerPin,OUTPUT);
  digitalWrite(buzzerPin, LOW);

  Serial2.begin(9600, SERIAL_8N2, HardwareSerial_Rx, HardwareSerial_Tx);
 
  rfid.begin();

  Serial.println("starting...");
}

void loop()
{

  if(bt.verificarConexao()){
    statusConexao = "Bluetooth On";

  }else{
    statusConexao = "Bluetooth Off";
  }

  display.renderizarLeitura(leitura,statusConexao);
  
  rfid.loop();
}

