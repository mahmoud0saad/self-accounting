import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { RequestUser } from '../common/types/jwt-payload';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CatalogService } from './catalog.service';

@ApiTags('Customization')
@ApiBearerAuth()
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get()
  getCatalog(@CurrentUser() user: RequestUser) {
    return this.catalog.getFullCatalog(user.sub);
  }
}
