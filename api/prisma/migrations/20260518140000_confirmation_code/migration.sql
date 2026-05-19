-- Email confirmation: link token → bcrypt code hash (lookup by user_id)

ALTER TABLE `email_confirmation_tokens` DROP INDEX `email_confirmation_tokens_token_key`;

ALTER TABLE `email_confirmation_tokens` CHANGE `token` `code_hash` VARCHAR(191) NOT NULL;
