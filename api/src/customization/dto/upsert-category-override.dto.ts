import { IsBoolean, IsInt, IsOptional, IsString } from 'class-validator';

export class UpsertCategoryOverrideDto {
  @IsOptional()
  @IsBoolean()
  hidden?: boolean;

  @IsOptional()
  @IsString()
  customName?: string | null;

  @IsOptional()
  @IsString()
  customIcon?: string | null;

  @IsOptional()
  @IsInt()
  sortOrder?: number | null;
}
