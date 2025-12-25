#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#include "DHT.h"

#define DHTPIN 4
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);

BLECharacteristic *pCharacteristic;

#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890ab"
#define CHARACTERISTIC_UUID "abcd1234-5678-1234-5678-abcdef123456"

void setup() {
  Serial.begin(115200);
  dht.begin();

  BLEDevice::init("ESP32_Temperature");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();

  Serial.println("BLE started, waiting for Flutter...");
}

void loop() {
  float temp = dht.readTemperature();

  if (!isnan(temp)) {
    char tempString[8];
    dtostrf(temp, 1, 2, tempString);

    pCharacteristic->setValue(tempString);
    pCharacteristic->notify();

    Serial.print("Temperature: ");
    Serial.println(tempString);
  }

  delay(2000);
}
