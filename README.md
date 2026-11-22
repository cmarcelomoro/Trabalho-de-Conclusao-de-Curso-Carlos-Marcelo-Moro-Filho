# Repositório contendo a programação do hardware (dispositivo de leitura) e do software (aplicativo)

## Instruções para rodar a solução de hardware desenvolvida:
### Ambiente: VS Code com extensão PlatformIO IDE ( ou PlatformIO Core CLI).
### Placa / Plataforma: wemos_d1_uno32 (espressif32, framework arduino).
### Bibliotecas (instaladas automaticamente pelo platform.ini):
  * makuna/Rfid134 by Makuna (^1.0.2)
  * olikraus/u8g2 (^2.36.17)
 Monitor serial: 115200 baud.
 Como rodar :

cd hardware  
pio run --target upload  
pio device monitor  

## Instruções para rodar a solução de software desenvolvida:
### Ambiente: Flutter SDK com Dart SDK ^3.11.0 + Android Studio / VS Code (para execução em Android físico com BLE).
### Principais dependências (pubsec.yaml):
  * flutter_blue_plus (^2.2.1) - comunicação Bluetooth Low Energy (BLE) com leitor
  * firebase_core (^4.10.0), firebase_auth (^6.5.2) e cloud_firestore (^6.5.0)
### Configuração externa:
  * Projeto Firebase configurado (firebase.json, lib/firebase_options.dart e android/app/google-services.json; caso use outro projeto Firebase, reconfigurar via flutterfire configure).
  * Dipositivo físico Android com Bluetooth e Localização ativados.

cd software/gerenciamento_de_rebanho  
flutter pub get  
flutter run  
