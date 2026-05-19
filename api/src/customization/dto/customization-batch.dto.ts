import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsISO8601,
  IsObject,
  IsString,
  ValidateNested,
} from 'class-validator';

export class CustomizationBatchOpDto {
  @IsString()
  opId!: string;

  @IsString()
  opType!: string;

  @IsObject()
  payload!: Record<string, unknown>;

  @IsISO8601()
  clientUpdatedAt!: string;
}

export class CustomizationBatchDto {
  @ValidateNested({ each: true })
  @Type(() => CustomizationBatchOpDto)
  @ArrayMaxSize(200)
  ops!: CustomizationBatchOpDto[];
}
