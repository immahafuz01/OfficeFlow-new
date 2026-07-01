-- Invoice v2 migration
-- Adds party_id FK and auto-generated invoice_number to the invoices table

-- 1. Link invoices to a party (nullable — invoice can exist without a party)
ALTER TABLE invoices
  ADD COLUMN IF NOT EXISTS party_id INTEGER REFERENCES parties(id) ON DELETE SET NULL;

-- 2. invoice_number: unique human-readable identifier e.g. INV-0001
ALTER TABLE invoices
  ADD COLUMN IF NOT EXISTS invoice_number VARCHAR(20) UNIQUE;

-- 3. Create a sequence for invoice numbering (start at 1)
CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START 1;

-- 4. Backfill existing rows with invoice numbers
UPDATE invoices
  SET invoice_number = 'INV-' || LPAD(nextval('invoice_number_seq')::TEXT, 4, '0')
  WHERE invoice_number IS NULL;

-- 5. Default for future rows (trigger approach)
CREATE OR REPLACE FUNCTION set_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.invoice_number IS NULL THEN
    NEW.invoice_number := 'INV-' || LPAD(nextval('invoice_number_seq')::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_invoice_number ON invoices;
CREATE TRIGGER trg_invoice_number
  BEFORE INSERT ON invoices
  FOR EACH ROW EXECUTE FUNCTION set_invoice_number();
