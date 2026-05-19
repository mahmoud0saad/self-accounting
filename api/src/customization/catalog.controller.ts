import { Controller, Get } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiForbiddenResponse,
} from '@nestjs/swagger';
import type { RequestUser } from '../common/types/jwt-payload';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CatalogService } from './catalog.service';
import { SnapshotStateDto } from './dto/snapshot-state.dto';

@ApiTags('Customization')
@ApiBearerAuth()
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get()
  getCatalog(@CurrentUser() user: RequestUser) {
    return this.catalog.getFullCatalog(user.sub);
  }

  @Get('snapshot-state')
  @ApiOperation({
    summary: 'Whether this account has saved checklist customizations',
    description:
      'Cheap head check before a full catalog restore on sign-in. May gain a `since` query param later for delta pull.',
  })
  @ApiOkResponse({ type: SnapshotStateDto })
  @ApiUnauthorizedResponse()
  @ApiForbiddenResponse()
  getSnapshotState(@CurrentUser() user: RequestUser): Promise<SnapshotStateDto> {
    return this.catalog.getSnapshotState(user.sub);
  }
}
