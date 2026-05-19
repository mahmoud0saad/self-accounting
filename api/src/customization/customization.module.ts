import { Module } from '@nestjs/common';
import { CatalogController } from './catalog.controller';
import { CatalogService } from './catalog.service';
import { CustomizationController } from './customization.controller';
import { CustomizationService } from './customization.service';

@Module({
  controllers: [CatalogController, CustomizationController],
  providers: [CatalogService, CustomizationService],
  exports: [CatalogService, CustomizationService],
})
export class CustomizationModule {}
