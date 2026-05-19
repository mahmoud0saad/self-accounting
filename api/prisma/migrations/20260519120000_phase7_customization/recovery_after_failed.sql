-- Run once if migrate deploy failed at tasks_category_code_fkey (empty categories table).
-- After this succeeds: npx prisma migrate resolve --applied 20260519120000_phase7_customization

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
