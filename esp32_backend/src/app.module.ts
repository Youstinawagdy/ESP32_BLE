import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ReadingsModule } from './readings/readings.module';

@Module({
  imports: [ReadingsModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
