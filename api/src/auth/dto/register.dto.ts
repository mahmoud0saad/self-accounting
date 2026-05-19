import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'you@example.com' })
  @IsEmail()
  @MaxLength(191)
  email!: string;

  @ApiProperty({ minLength: 8 })
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @ApiProperty({ minLength: 2, example: 'Ahmad Saad' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  fullName!: string;
}

export class LoginDto {
  @ApiProperty()
  @IsEmail()
  email!: string;

  @ApiProperty()
  @IsString()
  @MinLength(8)
  password!: string;
}

export class RefreshDto {
  @ApiProperty()
  @IsString()
  @MinLength(10)
  refreshToken!: string;
}

export class ResendConfirmationDto {
  @ApiProperty()
  @IsEmail()
  email!: string;
}

export class ConfirmEmailCodeDto {
  @ApiProperty()
  @IsEmail()
  email!: string;

  @ApiProperty({ example: '482913', description: '6-digit code from email' })
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Code must be exactly 6 digits.' })
  code!: string;
}
