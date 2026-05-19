import { IsBoolean, IsInt, IsOptional, IsString } from 'class-validator';

export class UpsertTaskOverrideDto {
  @IsOptional()
  @IsBoolean()
  hidden?: boolean;

  @IsOptional()
  @IsString()
  customName?: string | null;

  @IsOptional()
  @IsInt()
  customPoints?: number | null;

  @IsOptional()
  @IsString()
  customIcon?: string | null;

  @IsOptional()
  @IsString()
  customCategoryRef?: string | null;

  @IsOptional()
  @IsInt()
  sortOrder?: number | null;
}
