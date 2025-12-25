import { Injectable } from '@nestjs/common';

export interface Reading {
  deviceId: string;
  temperature: number;
  timestamp: Date;
}

@Injectable()
export class ReadingsService {
  private readings: Reading[] = [];

  addReading(reading: Omit<Reading, 'timestamp'>) {
    const newReading: Reading = { ...reading, timestamp: new Date() };
    this.readings.push(newReading);
    return newReading;
  }

  getLatestReading(deviceId: string): Reading | null {
    const deviceReadings = this.readings
      .filter(r => r.deviceId === deviceId)
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
    return deviceReadings[0] || null;
  }

  getAllReadings(): Reading[] {
    return this.readings;
  }
}
