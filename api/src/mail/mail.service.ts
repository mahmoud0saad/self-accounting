import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readFileSync } from 'fs';
import { join } from 'path';
import * as Handlebars from 'handlebars';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService implements OnModuleInit {
  private readonly logger = new Logger(MailService.name);
  private transporter!: nodemailer.Transporter;
  private confirmTemplate!: Handlebars.TemplateDelegate;
  private welcomeTemplate!: Handlebars.TemplateDelegate;
  private fromAddress!: string;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const host = this.config.get<string>('SMTP_HOST');
    const port = Number(this.config.get<string>('SMTP_PORT', '587'));
    const user = this.config.get<string>('SMTP_USER');
    const pass = this.config.get<string>('SMTP_PASSWORD');
    const fromName = this.config.get<string>('SMTP_FROM_NAME', 'Muhasabah');

    if (!host || !user || !pass) {
      this.logger.warn(
        'SMTP not fully configured — emails will be logged to console only.',
      );
      this.transporter = nodemailer.createTransport({ jsonTransport: true });
    } else {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });
    }

    this.fromAddress = `"${fromName}" <${user ?? 'noreply@muhasabah.local'}>`;
    const tplDir = join(__dirname, 'templates');
    this.confirmTemplate = Handlebars.compile(
      readFileSync(join(tplDir, 'confirm-email.hbs'), 'utf8'),
    );
    this.welcomeTemplate = Handlebars.compile(
      readFileSync(join(tplDir, 'welcome.hbs'), 'utf8'),
    );
  }

  async sendConfirmEmail(
    to: string,
    code: string,
    expiresMinutes: number,
  ): Promise<void> {
    const html = this.confirmTemplate({ code, expiresMinutes });
    await this.send(to, 'Your Muhasabah confirmation code', html);
  }

  async sendWelcome(to: string, fullName: string): Promise<void> {
    const html = this.welcomeTemplate({ fullName });
    await this.send(to, 'Welcome to Muhasabah', html);
  }

  private async send(to: string, subject: string, html: string): Promise<void> {
    try {
      const info = await this.transporter.sendMail({
        from: this.fromAddress,
        to,
        subject,
        html,
      });
      this.logger.log(`Mail sent to ${to}: ${info.messageId ?? 'ok'}`);
    } catch (err) {
      this.logger.error(`Failed to send mail to ${to}`, err);
      throw err;
    }
  }
}
