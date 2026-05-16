-- ============================================================
-- inspection 서비스
-- ============================================================
CREATE SCHEMA IF NOT EXISTS p_inspection;

CREATE USER inspection_user WITH PASSWORD 'inspection_pw';

ALTER SCHEMA p_inspection OWNER TO inspection_user;
GRANT ALL ON SCHEMA p_inspection TO inspection_user;

ALTER USER inspection_user SET search_path TO p_inspection;

-- ============================================================
-- delivery 서비스
-- ============================================================
CREATE SCHEMA IF NOT EXISTS p_delivery;

CREATE USER delivery_user WITH PASSWORD 'delivery_pw';

ALTER SCHEMA p_delivery OWNER TO delivery_user;
GRANT ALL ON SCHEMA p_delivery TO delivery_user;

ALTER USER delivery_user SET search_path TO p_delivery;

-- ============================================================
-- product 서비스
-- ============================================================
CREATE SCHEMA IF NOT EXISTS p_product;

CREATE USER product_user WITH PASSWORD 'product_pw';

ALTER SCHEMA p_product OWNER TO product_user;
GRANT ALL ON SCHEMA p_product TO product_user;

ALTER USER product_user SET search_path TO p_product;

-- ============================================================
-- order 서비스
-- ============================================================
CREATE SCHEMA IF NOT EXISTS p_order;

CREATE USER order_user WITH PASSWORD 'order_pw';

ALTER SCHEMA p_order OWNER TO order_user;
GRANT ALL ON SCHEMA p_order TO order_user;

ALTER USER order_user SET search_path TO p_order;
