-- ============================================================
-- inspection 서비스
-- ============================================================
CREATE SCHEMA IF NOT EXISTS p_inspection;

CREATE USER inspection_user WITH PASSWORD 'inspection_pw';

ALTER SCHEMA p_inspection OWNER TO inspection_user;
GRANT ALL ON SCHEMA p_inspection TO inspection_user;

ALTER USER inspection_user SET search_path TO p_inspection;
