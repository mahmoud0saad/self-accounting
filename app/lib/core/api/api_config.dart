/// Base URL for the Muhasabah API (includes `/v1` prefix).
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/v1',
);
