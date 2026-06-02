import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readFileSync } from 'fs';
import { join } from 'path';
import * as Handlebars from 'handlebars';
import * as nodemailer from 'nodemailer';
import { Resend } from 'resend';

type MailProvider = 'smtp' | 'resend';

@Injectable()
export class MailService implements OnModuleInit {
  private readonly logger = new Logger(MailService.name);
  private provider: MailProvider = 'smtp';
  private transporter!: nodemailer.Transporter;
  private resend: Resend | null = null;
  private resendEnabled = false;
  private confirmTemplate!: Handlebars.TemplateDelegate;
  private welcomeTemplate!: Handlebars.TemplateDelegate;
  private fromAddress!: string;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const rawProvider = this.config
      .get<string>('MAIL_PROVIDER', 'smtp')
      ?.toLowerCase();
    this.provider = rawProvider === 'resend' ? 'resend' : 'smtp';

    const fromName = this.config.get<string>('SMTP_FROM_NAME', 'Muhasabah');
    const tplDir = join(__dirname, 'templates');
    this.confirmTemplate = Handlebars.compile(
      readFileSync(join(tplDir, 'confirm-email.hbs'), 'utf8'),
    );
    this.welcomeTemplate = Handlebars.compile(
      readFileSync(join(tplDir, 'welcome.hbs'), 'utf8'),
    );

    if (this.provider === 'resend') {
      this.initResend(fromName);
    } else {
      this.initSmtp(fromName);
    }
  }

  private initResend(fromName: string): void {
    const apiKey = this.config.get<string>('RESEND_API_KEY');
    const fromEmail = this.config.get<string>(
      'RESEND_FROM',
      'onboarding@resend.dev',
    );

    if (!apiKey) {
      this.logger.warn(
        'RESEND_API_KEY not set — emails will be logged to console only.',
      );
    } else {
      this.resend = new Resend(apiKey);
      this.resendEnabled = true;
      this.logger.log('Mail provider: Resend');
    }

    this.fromAddress = `"${fromName}" <${fromEmail}>`;
  }

  private initSmtp(fromName: string): void {
    const host = this.config.get<string>('SMTP_HOST');
    const port = Number(this.config.get<string>('SMTP_PORT', '587'));
    const user = this.config.get<string>('SMTP_USER');
    const pass = this.config.get<string>('SMTP_PASSWORD');

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
      this.logger.log('Mail provider: SMTP');
    }

    this.fromAddress = `"${fromName}" <${user ?? 'noreply@muhasabah.local'}>`;
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
    if (this.provider === 'resend') {
      await this.sendViaResend(to, subject, html);
      return;
    }
    await this.sendViaSmtp(to, subject, html);
  }

  private async sendViaResend(
    to: string,
    subject: string,
    html: string,
  ): Promise<void> {
    if (!this.resendEnabled || !this.resend) {
      this.logger.log(
        `[Resend dry-run] to=${to} subject="${subject}" from=${this.fromAddress}`,
      );
      return;
    }

    try {
      const { data, error } = await this.resend.emails.send({
        from: this.fromAddress,
        to,
        subject,
        html,
      });
      if (error) {
        throw new Error(error.message);
      }
      this.logger.log(`Mail sent to ${to} via Resend: ${data?.id ?? 'ok'}`);
    } catch (err) {
      this.logger.error(`Failed to send mail to ${to} via Resend`, err);
      throw err;
    }
  }

  private async sendViaSmtp(
    to: string,
    subject: string,
    html: string,
  ): Promise<void> {
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
