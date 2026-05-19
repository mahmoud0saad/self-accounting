import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateUserTaskDto {
  @IsString()
  name!: string;

  @IsString()
  categoryRef!: string;

  @IsInt()
  @Min(1)
  points!: number;

  @IsString()
  icon!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}
