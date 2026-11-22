#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

class ConexaoBluetooth {
private:
    BLEServer* server;
    BLECharacteristic* characteristic;
    bool conectado = false;

    class ServerCallbacks : public BLEServerCallbacks {
private:
    bool* conectadoPtr;

public:
    ServerCallbacks(bool* conectado) {
        conectadoPtr = conectado;
    }

    void onConnect(BLEServer* pServer) {
        *conectadoPtr = true;
    }

    void onDisconnect(BLEServer* pServer) {
        *conectadoPtr = false;

        
        BLEDevice::startAdvertising();
    }
};

public:
    ConexaoBluetooth() {}

    void iniciar(const String& nomeDispositivo) {
        BLEDevice::init(nomeDispositivo.c_str());

        server = BLEDevice::createServer();
        server->setCallbacks(new ServerCallbacks(&conectado));

       
        BLEService* service = server->createService("12345678-1234-1234-1234-1234567890ab");

        characteristic = service->createCharacteristic(
            "abcd1234-5678-90ab-cdef-1234567890ab",
            BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_WRITE |
            BLECharacteristic::PROPERTY_NOTIFY
        );

        characteristic->addDescriptor(new BLE2902());

        service->start();

        BLEAdvertising* advertising = BLEDevice::getAdvertising();
        advertising->start();
    }

    bool verificarConexao() {
        return conectado;
    }

    void enviarDados(const String& dados) {
        if (conectado) {
            characteristic->setValue(dados.c_str());
            characteristic->notify();
        }
    }

    String lerDados() {
        return String(characteristic->getValue().c_str());
    }
};