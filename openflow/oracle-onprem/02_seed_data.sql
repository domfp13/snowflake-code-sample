-- Seed CUSTOMER and ORDERS with sample rows (runs only if empty)
SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
  v_cnt NUMBER;
BEGIN
  -- Seed CUSTOMERS if empty
  SELECT COUNT(*) INTO v_cnt FROM CUSTOMER;
  IF v_cnt = 0 THEN
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Alice',   'Nguyen',    'alice.nguyen@example.com');
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Bruno',   'Silva',     'bruno.silva@example.com');
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Chloe',   'Martinez',  'chloe.martinez@example.com');
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Diego',   'Santos',    'diego.santos@example.com');
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Elena',   'Kumar',     'elena.kumar@example.com');
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Fatima',  'Hassan',    'fatima.hassan@example.com');
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Gabe',    'Rodriguez', 'gabe.rodriguez@example.com');
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Hiro',    'Tanaka',    'hiro.tanaka@example.com');
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Ivy',     'Chen',      'ivy.chen@example.com');
    INSERT INTO CUSTOMER (FIRST_NAME, LAST_NAME, EMAIL) VALUES ('Jon',     'O''Brien',  'jon.obrien@example.com');
    COMMIT;
  END IF;

  -- Seed ORDERS if empty
  SELECT COUNT(*) INTO v_cnt FROM ORDERS;
  IF v_cnt = 0 THEN
    -- Create a few orders per first 5 customers
    INSERT INTO ORDERS (CUSTOMER_ID, ORDER_DATE, AMOUNT)
      SELECT CUSTOMER_ID, SYSDATE - 10, 149.99 FROM CUSTOMER WHERE EMAIL = 'alice.nguyen@example.com';
    INSERT INTO ORDERS (CUSTOMER_ID, ORDER_DATE, AMOUNT)
      SELECT CUSTOMER_ID, SYSDATE - 9,  89.50  FROM CUSTOMER WHERE EMAIL = 'alice.nguyen@example.com';

    INSERT INTO ORDERS (CUSTOMER_ID, ORDER_DATE, AMOUNT)
      SELECT CUSTOMER_ID, SYSDATE - 8,  250.00 FROM CUSTOMER WHERE EMAIL = 'bruno.silva@example.com';

    INSERT INTO ORDERS (CUSTOMER_ID, ORDER_DATE, AMOUNT)
      SELECT CUSTOMER_ID, SYSDATE - 7,  45.25  FROM CUSTOMER WHERE EMAIL = 'chloe.martinez@example.com';
    INSERT INTO ORDERS (CUSTOMER_ID, ORDER_DATE, AMOUNT)
      SELECT CUSTOMER_ID, SYSDATE - 6,  78.90  FROM CUSTOMER WHERE EMAIL = 'chloe.martinez@example.com';

    INSERT INTO ORDERS (CUSTOMER_ID, ORDER_DATE, AMOUNT)
      SELECT CUSTOMER_ID, SYSDATE - 5,  19.99  FROM CUSTOMER WHERE EMAIL = 'diego.santos@example.com';

    INSERT INTO ORDERS (CUSTOMER_ID, ORDER_DATE, AMOUNT)
      SELECT CUSTOMER_ID, SYSDATE - 4,  500.00 FROM CUSTOMER WHERE EMAIL = 'elena.kumar@example.com';
    COMMIT;
  END IF;
END;
/

-- SELECT * FROM CUSTOMER;
-- SELECT * FROM ORDERS;