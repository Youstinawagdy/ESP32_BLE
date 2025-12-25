import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ReadingsService, Reading } from './readings.service';

@Controller('readings')
export class ReadingsController {
  constructor(private readonly readingsService: ReadingsService) {}

  @Post()
  addReading(@Body() reading: { deviceId: string; temperature: number }) {
    return this.readingsService.addReading(reading);
  }

  @Get(':deviceId')
  getLatest(@Param('deviceId') deviceId: string) {
    const latest = this.readingsService.getLatestReading(deviceId);
    if (!latest) {
      return { message: 'No readings yet for this device' };
    }
    return latest;
  }

  @Get()
  getAll() {
    return this.readingsService.getAllReadings();
  }
}
