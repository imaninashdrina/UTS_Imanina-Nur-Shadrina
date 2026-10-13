-- SOAL 2: Trigger persediaan perpetual dan pencegahan stok negatif
CREATE TABLE IF NOT EXISTS inventory_items (
    item_id VARCHAR(10) PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    stock_qty INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    unit_cost NUMERIC(15,2) NOT NULL CHECK (unit_cost >= 0)
);

CREATE TABLE IF NOT EXISTS inventory_transactions (
    trx_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_id VARCHAR(10) NOT NULL REFERENCES inventory_items(item_id) ON DELETE RESTRICT,
    trx_type VARCHAR(10) NOT NULL CHECK (trx_type IN ('PURCHASE','SALE','ADJUSTMENT')),
    qty INT NOT NULL CHECK (qty > 0),
    trx_date TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inventory_movement_audit (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trx_id BIGINT NOT NULL UNIQUE REFERENCES inventory_transactions(trx_id) ON DELETE RESTRICT,
    item_id VARCHAR(10) NOT NULL,
    trx_type VARCHAR(10) NOT NULL,
    qty_change INT NOT NULL,
    stock_after INT NOT NULL,
    movement_value NUMERIC(15,2) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION trg_update_stock_and_journal()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_stock INT;
    v_delta INT;
    v_new_stock INT;
    v_cost NUMERIC(15,2);
BEGIN
    -- Kunci baris item agar dua kasir tidak membaca stok lama bersamaan.
    SELECT stock_qty, unit_cost
      INTO v_stock, v_cost
      FROM inventory_items
     WHERE item_id = NEW.item_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item % tidak ditemukan', NEW.item_id;
    END IF;

    IF NEW.trx_type = 'PURCHASE' THEN
        v_delta := NEW.qty;
    ELSIF NEW.trx_type = 'SALE' THEN
        v_delta := -NEW.qty;
    ELSE
        -- ADJUSTMENT: qty positif menambah stok; koreksi negatif
        -- bisa dimasukkan dengan qty transaksi positif saja pada skema sederhana ini.
        v_delta := NEW.qty;
    END IF;

    v_new_stock := v_stock + v_delta;
    IF v_new_stock < 0 THEN
        RAISE EXCEPTION 'Stok tidak cukup untuk item %. Stok %, perubahan %',
            NEW.item_id, v_stock, v_delta;
    END IF;

    UPDATE inventory_items
       SET stock_qty = v_new_stock
     WHERE item_id = NEW.item_id;

    INSERT INTO inventory_movement_audit
        (trx_id, item_id, trx_type, qty_change, stock_after, movement_value)
    VALUES
        (NEW.trx_id, NEW.item_id, NEW.trx_type, v_delta, v_new_stock,
         ABS(v_delta) * v_cost);

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS inventory_after_insert ON inventory_transactions;
CREATE TRIGGER inventory_after_insert
AFTER INSERT ON inventory_transactions
FOR EACH ROW EXECUTE FUNCTION trg_update_stock_and_journal();

-- Uji singkat:
-- INSERT INTO inventory_items(item_id,item_name,stock_qty,unit_cost)
-- VALUES ('ITM001','Raket demo',1,2500000)
-- ON CONFLICT (item_id) DO UPDATE SET stock_qty=EXCLUDED.stock_qty;
-- INSERT INTO inventory_transactions(item_id,trx_type,qty) VALUES ('ITM001','SALE',1);
-- Penjualan berikutnya sebanyak 1 akan gagal bila stok sudah 0.
--
-- Catatan: skema soal memberi qty bertipe INT dan CHECK qty > 0.
-- Karena itu ADJUSTMENT pada contoh ini hanya menambah stok. Jika perlu koreksi
-- turun/naik, ubah skema menjadi qty_change INT NOT NULL CHECK (qty_change <> 0)
-- dan tentukan aturan tanda secara eksplisit.
