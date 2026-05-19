-- Phase 7: categories, user customization, task catalog extensions

CREATE TABLE `categories` (
    `code` VARCHAR(191) NOT NULL,
    `default_name` VARCHAR(191) NOT NULL,
    `default_icon` VARCHAR(191) NOT NULL,
    `default_sort_order` INTEGER NOT NULL,
    `is_fard` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`code`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `user_categories` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `icon` VARCHAR(191) NOT NULL,
    `sort_order` INTEGER NOT NULL,
    `archived_at` DATETIME(3) NULL,
    `updated_at` DATETIME(3) NOT NULL,
    INDEX `user_categories_user_id_archived_at_idx`(`user_id`, `archived_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `user_category_overrides` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `category_code` VARCHAR(191) NOT NULL,
    `hidden` BOOLEAN NOT NULL DEFAULT false,
    `custom_name` VARCHAR(191) NULL,
    `custom_icon` VARCHAR(191) NULL,
    `sort_order` INTEGER NULL,
    `updated_at` DATETIME(3) NOT NULL,
    UNIQUE INDEX `user_category_overrides_user_id_category_code_key`(`user_id`, `category_code`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `user_tasks` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `category_ref` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `points` INTEGER NOT NULL,
    `icon` VARCHAR(191) NOT NULL,
    `sort_order` INTEGER NOT NULL DEFAULT 0,
    `archived_at` DATETIME(3) NULL,
    `description` VARCHAR(280) NULL,
    `recurrence` JSON NULL,
    `kind` VARCHAR(191) NOT NULL DEFAULT 'TASK',
    `updated_at` DATETIME(3) NOT NULL,
    INDEX `user_tasks_user_id_archived_at_idx`(`user_id`, `archived_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `user_task_overrides` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `task_code` VARCHAR(191) NOT NULL,
    `hidden` BOOLEAN NOT NULL DEFAULT false,
    `custom_name` VARCHAR(191) NULL,
    `custom_points` INTEGER NULL,
    `custom_icon` VARCHAR(191) NULL,
    `custom_category_ref` VARCHAR(191) NULL,
    `sort_order` INTEGER NULL,
    `updated_at` DATETIME(3) NOT NULL,
    UNIQUE INDEX `user_task_overrides_user_id_task_code_key`(`user_id`, `task_code`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- tasks: category -> category_code, add icons/sort, drop user_id
ALTER TABLE `tasks` ADD COLUMN `category_code` VARCHAR(191) NULL;
ALTER TABLE `tasks` ADD COLUMN `default_icon` VARCHAR(191) NOT NULL DEFAULT 'star';
ALTER TABLE `tasks` ADD COLUMN `default_sort_order` INTEGER NOT NULL DEFAULT 0;

UPDATE `tasks` SET `category_code` = `category`;

ALTER TABLE `tasks` MODIFY `category_code` VARCHAR(191) NOT NULL;
ALTER TABLE `tasks` DROP COLUMN `category`;

ALTER TABLE `tasks` DROP FOREIGN KEY `tasks_user_id_fkey`;
ALTER TABLE `tasks` DROP INDEX `tasks_user_id_idx`;
ALTER TABLE `tasks` DROP COLUMN `user_id`;

CREATE INDEX `tasks_category_code_idx` ON `tasks`(`category_code`);

-- Seed categories before FK (tasks.category_code already populated from legacy `category` column).
INSERT INTO `categories` (`code`, `default_name`, `default_icon`, `default_sort_order`, `is_fard`, `created_at`) VALUES
    ('fajr', 'Fajr', 'wb_twilight', 0, true, CURRENT_TIMESTAMP(3)),
    ('dhuhr', 'Dhuhr', 'wb_sunny', 1, true, CURRENT_TIMESTAMP(3)),
    ('asr', 'Asr', 'partly_cloudy_day', 2, true, CURRENT_TIMESTAMP(3)),
    ('maghrib', 'Maghrib', 'wb_twilight', 3, true, CURRENT_TIMESTAMP(3)),
    ('isha', 'Isha', 'nights_stay', 4, true, CURRENT_TIMESTAMP(3)),
    ('qiyamEvening', 'Qiyam & Evening', 'bedtime', 5, false, CURRENT_TIMESTAMP(3)),
    ('quranFasting', 'Quran & Fasting', 'menu_book', 6, false, CURRENT_TIMESTAMP(3)),
    ('miscAdhkar', 'Misc Adhkar', 'auto_awesome', 7, false, CURRENT_TIMESTAMP(3))
ON DUPLICATE KEY UPDATE `code` = `code`;

ALTER TABLE `tasks` ADD CONSTRAINT `tasks_category_code_fkey` FOREIGN KEY (`category_code`) REFERENCES `categories`(`code`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- daily_logs: optional task_id, add user_task_id
ALTER TABLE `daily_logs` DROP FOREIGN KEY `daily_logs_task_id_fkey`;
ALTER TABLE `daily_logs` MODIFY `task_id` VARCHAR(191) NULL;
ALTER TABLE `daily_logs` ADD COLUMN `user_task_id` VARCHAR(191) NULL;

CREATE UNIQUE INDEX `daily_logs_user_id_date_user_task_id_key` ON `daily_logs`(`user_id`, `date`, `user_task_id`);

ALTER TABLE `daily_logs` ADD CONSTRAINT `daily_logs_task_id_fkey` FOREIGN KEY (`task_id`) REFERENCES `tasks`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `daily_logs` ADD CONSTRAINT `daily_logs_user_task_id_fkey` FOREIGN KEY (`user_task_id`) REFERENCES `user_tasks`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE `user_categories` ADD CONSTRAINT `user_categories_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `user_category_overrides` ADD CONSTRAINT `user_category_overrides_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `user_category_overrides` ADD CONSTRAINT `user_category_overrides_category_code_fkey` FOREIGN KEY (`category_code`) REFERENCES `categories`(`code`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `user_tasks` ADD CONSTRAINT `user_tasks_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `user_task_overrides` ADD CONSTRAINT `user_task_overrides_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `user_task_overrides` ADD CONSTRAINT `user_task_overrides_task_code_fkey` FOREIGN KEY (`task_code`) REFERENCES `tasks`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
