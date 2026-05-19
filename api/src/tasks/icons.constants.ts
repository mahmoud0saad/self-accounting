/** Curated Material Symbols codes — must match `app/lib/core/icons/curated_icons.dart`. */
export const CURATED_ICONS = [
  'mosque',
  'book_5',
  'sunny',
  'nights_stay',
  'volunteer_activism',
  'self_improvement',
  'favorite',
  'auto_awesome',
  'local_florist',
  'water_drop',
  'wb_twilight',
  'dark_mode',
  'light_mode',
  'schedule',
  'alarm',
  'notifications',
  'menu_book',
  'bookmark',
  'star',
  'check_circle',
  'radio_button_unchecked',
  'flag',
  'bolt',
  'eco',
  'spa',
  'psychology',
  'lightbulb',
  'coffee',
  'restaurant',
  'bedtime',
  'wb_sunny',
  'partly_cloudy_day',
  'family_restroom',
  'groups',
  'phone',
  'chat',
  'directions_walk',
  'directions_run',
  'fitness_center',
  'library_books',
] as const;

export type CuratedIcon = (typeof CURATED_ICONS)[number];

const iconSet = new Set<string>(CURATED_ICONS);

export function isCuratedIcon(value: string): value is CuratedIcon {
  return iconSet.has(value);
}
