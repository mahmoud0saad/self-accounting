-- CreateTable
CREATE TABLE `challenge_templates` (
    `code` VARCHAR(191) NOT NULL,
    `default_title` VARCHAR(191) NOT NULL,
    `default_icon` VARCHAR(191) NOT NULL,
    `source_kind` VARCHAR(191) NOT NULL,
    `source_ref` VARCHAR(191) NOT NULL,
    `goal_count` INTEGER NOT NULL,
    `default_sort_order` INTEGER NOT NULL DEFAULT 0,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`code`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_challenges` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `template_code` VARCHAR(191) NULL,
    `custom_title` VARCHAR(191) NULL,
    `custom_icon` VARCHAR(191) NULL,
    `custom_source_kind` VARCHAR(191) NULL,
    `custom_source_ref` VARCHAR(191) NULL,
    `custom_goal_count` INTEGER NULL,
    `started_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `archived_at` DATETIME(3) NULL,
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `user_challenges_user_id_archived_at_idx`(`user_id`, `archived_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_challenge_weeks` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `user_challenge_id` VARCHAR(191) NOT NULL,
    `week_start` DATE NOT NULL,
    `week_end` DATE NOT NULL,
    `goal_count` INTEGER NOT NULL,
    `achieved_count` INTEGER NOT NULL DEFAULT 0,
    `status` VARCHAR(191) NOT NULL DEFAULT 'IN_PROGRESS',
    `completed_at` DATETIME(3) NULL,
    `celebration_seen_at` DATETIME(3) NULL,
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `user_challenge_weeks_user_id_week_start_idx`(`user_id`, `week_start`),
    UNIQUE INDEX `user_challenge_weeks_user_challenge_id_week_start_key`(`user_challenge_id`, `week_start`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `user_challenges` ADD CONSTRAINT `user_challenges_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_challenges` ADD CONSTRAINT `user_challenges_template_code_fkey` FOREIGN KEY (`template_code`) REFERENCES `challenge_templates`(`code`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_challenge_weeks` ADD CONSTRAINT `user_challenge_weeks_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_challenge_weeks` ADD CONSTRAINT `user_challenge_weeks_user_challenge_id_fkey` FOREIGN KEY (`user_challenge_id`) REFERENCES `user_challenges`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
