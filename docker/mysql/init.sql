-- Runs once on first MySQL data volume init (official MySQL image).
CREATE DATABASE IF NOT EXISTS muhasabah_shadow;
GRANT ALL PRIVILEGES ON muhasabah_shadow.* TO 'muhasabah'@'%';
FLUSH PRIVILEGES;
