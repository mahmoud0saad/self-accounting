import {
  Body,
  Controller,
  Delete,
  Param,
  Patch,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import type { RequestUser } from '../common/types/jwt-payload';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CustomizationService } from './customization.service';
import { CreateUserCategoryDto } from './dto/create-user-category.dto';
import { CreateUserTaskDto } from './dto/create-user-task.dto';
import { CustomizationBatchDto } from './dto/customization-batch.dto';
import { UpdateUserCategoryDto } from './dto/update-user-category.dto';
import { UpsertCategoryOverrideDto } from './dto/upsert-category-override.dto';
import { UpsertTaskOverrideDto } from './dto/upsert-task-override.dto';

@ApiTags('Customization')
@ApiBearerAuth()
@Controller()
export class CustomizationController {
  constructor(private readonly customization: CustomizationService) {}

  @Post('user-categories')
  createCategory(
    @CurrentUser() user: RequestUser,
    @Body() dto: CreateUserCategoryDto,
  ) {
    return this.customization.createUserCategory(user.sub, dto);
  }

  @Patch('user-categories/:id')
  updateCategory(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Body() dto: UpdateUserCategoryDto,
  ) {
    return this.customization.updateUserCategory(user.sub, id, dto);
  }

  @Delete('user-categories/:id')
  @ApiQuery({ name: 'force', required: false, type: Boolean })
  deleteCategory(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Query('force') force?: string,
  ) {
    return this.customization.deleteUserCategory(
      user.sub,
      id,
      force === 'true',
    );
  }

  @Put('user-category-overrides/:categoryCode')
  upsertCategoryOverride(
    @CurrentUser() user: RequestUser,
    @Param('categoryCode') categoryCode: string,
    @Body() dto: UpsertCategoryOverrideDto,
  ) {
    return this.customization.upsertCategoryOverride(
      user.sub,
      categoryCode,
      dto,
    );
  }

  @Post('user-tasks')
  createTask(@CurrentUser() user: RequestUser, @Body() dto: CreateUserTaskDto) {
    return this.customization.createUserTask(user.sub, dto);
  }

  @Patch('user-tasks/:id')
  updateTask(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Body() dto: CreateUserTaskDto,
  ) {
    return this.customization.updateUserTask(user.sub, id, dto);
  }

  @Delete('user-tasks/:id')
  @ApiQuery({ name: 'archive', required: false, type: Boolean })
  deleteTask(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Query('archive') archive?: string,
  ) {
    return this.customization.deleteUserTask(
      user.sub,
      id,
      archive === 'true',
    );
  }

  @Put('user-task-overrides/:taskCode')
  upsertTaskOverride(
    @CurrentUser() user: RequestUser,
    @Param('taskCode') taskCode: string,
    @Body() dto: UpsertTaskOverrideDto,
  ) {
    return this.customization.upsertTaskOverride(user.sub, taskCode, dto);
  }

  @Put('customizations/batch')
  batch(@CurrentUser() user: RequestUser, @Body() dto: CustomizationBatchDto) {
    return this.customization.processBatch(user.sub, dto.ops);
  }
}
