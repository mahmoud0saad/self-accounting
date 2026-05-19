export declare const defaultCategoriesSeed: readonly [{
    readonly code: "fajr";
    readonly defaultName: "Fajr";
    readonly defaultIcon: "wb_twilight";
    readonly defaultSortOrder: 0;
    readonly isFard: true;
}, {
    readonly code: "dhuhr";
    readonly defaultName: "Dhuhr";
    readonly defaultIcon: "wb_sunny";
    readonly defaultSortOrder: 1;
    readonly isFard: true;
}, {
    readonly code: "asr";
    readonly defaultName: "Asr";
    readonly defaultIcon: "partly_cloudy_day";
    readonly defaultSortOrder: 2;
    readonly isFard: true;
}, {
    readonly code: "maghrib";
    readonly defaultName: "Maghrib";
    readonly defaultIcon: "wb_twilight";
    readonly defaultSortOrder: 3;
    readonly isFard: true;
}, {
    readonly code: "isha";
    readonly defaultName: "Isha";
    readonly defaultIcon: "nights_stay";
    readonly defaultSortOrder: 4;
    readonly isFard: true;
}, {
    readonly code: "qiyamEvening";
    readonly defaultName: "Qiyam & Evening";
    readonly defaultIcon: "bedtime";
    readonly defaultSortOrder: 5;
    readonly isFard: false;
}, {
    readonly code: "quranFasting";
    readonly defaultName: "Quran & Fasting";
    readonly defaultIcon: "menu_book";
    readonly defaultSortOrder: 6;
    readonly isFard: false;
}, {
    readonly code: "miscAdhkar";
    readonly defaultName: "Misc Adhkar";
    readonly defaultIcon: "auto_awesome";
    readonly defaultSortOrder: 7;
    readonly isFard: false;
}];
export declare const defaultTasksSeed: readonly [{
    readonly id: "fajr_waking_up_adhkar";
    readonly categoryCode: "fajr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 0;
}, {
    readonly id: "fajr_sunnah_before_fajr";
    readonly categoryCode: "fajr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 1;
}, {
    readonly id: "fajr_first_congregation";
    readonly categoryCode: "fajr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 2;
}, {
    readonly id: "fajr_post_prayer_adhkar";
    readonly categoryCode: "fajr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 3;
}, {
    readonly id: "fajr_morning_adhkar";
    readonly categoryCode: "fajr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 4;
}, {
    readonly id: "fajr_duha_4_rakahs";
    readonly categoryCode: "fajr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 5;
}, {
    readonly id: "dhuhr_sunnah_before_4_rakahs";
    readonly categoryCode: "dhuhr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 6;
}, {
    readonly id: "dhuhr_first_congregation";
    readonly categoryCode: "dhuhr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 7;
}, {
    readonly id: "dhuhr_post_prayer_adhkar";
    readonly categoryCode: "dhuhr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 8;
}, {
    readonly id: "dhuhr_sunnah_after";
    readonly categoryCode: "dhuhr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 9;
}, {
    readonly id: "asr_first_congregation";
    readonly categoryCode: "asr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 10;
}, {
    readonly id: "asr_post_prayer_adhkar";
    readonly categoryCode: "asr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 11;
}, {
    readonly id: "asr_evening_adhkar";
    readonly categoryCode: "asr";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 12;
}, {
    readonly id: "maghrib_first_congregation";
    readonly categoryCode: "maghrib";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 13;
}, {
    readonly id: "maghrib_post_prayer_adhkar";
    readonly categoryCode: "maghrib";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 14;
}, {
    readonly id: "maghrib_sunnah_after";
    readonly categoryCode: "maghrib";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 15;
}, {
    readonly id: "isha_first_congregation";
    readonly categoryCode: "isha";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 16;
}, {
    readonly id: "isha_post_prayer_adhkar";
    readonly categoryCode: "isha";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 17;
}, {
    readonly id: "isha_sunnah_after";
    readonly categoryCode: "isha";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 18;
}, {
    readonly id: "qiyam_two_rakahs";
    readonly categoryCode: "qiyamEvening";
    readonly defaultPoints: 4;
    readonly defaultSortOrder: 19;
}, {
    readonly id: "qiyam_daily_quran_two_quarters";
    readonly categoryCode: "qiyamEvening";
    readonly defaultPoints: 4;
    readonly defaultSortOrder: 20;
}, {
    readonly id: "qiyam_witr";
    readonly categoryCode: "qiyamEvening";
    readonly defaultPoints: 1;
    readonly defaultSortOrder: 21;
}, {
    readonly id: "qiyam_adhkar_before_sleep";
    readonly categoryCode: "qiyamEvening";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 22;
}, {
    readonly id: "quran_memorize_half_page";
    readonly categoryCode: "quranFasting";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 23;
}, {
    readonly id: "quran_read_six_quarters";
    readonly categoryCode: "quranFasting";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 24;
}, {
    readonly id: "quran_fasting_mon_thu";
    readonly categoryCode: "quranFasting";
    readonly defaultPoints: 5;
    readonly defaultSortOrder: 25;
}, {
    readonly id: "misc_restroom_adhkar";
    readonly categoryCode: "miscAdhkar";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 26;
}, {
    readonly id: "misc_clothing_adhkar";
    readonly categoryCode: "miscAdhkar";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 27;
}, {
    readonly id: "misc_wudu_adhkar";
    readonly categoryCode: "miscAdhkar";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 28;
}, {
    readonly id: "misc_house_adhkar";
    readonly categoryCode: "miscAdhkar";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 29;
}, {
    readonly id: "misc_mosque_adhkar";
    readonly categoryCode: "miscAdhkar";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 30;
}, {
    readonly id: "misc_walking_mosque_adhkar";
    readonly categoryCode: "miscAdhkar";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 31;
}, {
    readonly id: "misc_eating_drinking_adhkar";
    readonly categoryCode: "miscAdhkar";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 32;
}, {
    readonly id: "misc_riding_traveling_adhkar";
    readonly categoryCode: "miscAdhkar";
    readonly defaultPoints: 2;
    readonly defaultSortOrder: 33;
}];
