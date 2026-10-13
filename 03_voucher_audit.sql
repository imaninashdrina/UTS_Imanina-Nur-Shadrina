-- SOAL 3: Voucher kas keluar, audit log, dan penguncian jurnal POSTED
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS cash_vouchers (
    voucher_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    voucher_no VARCHAR(40) NOT NULL UNIQUE,
    voucher_date DATE NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT','POSTED','REVERSED')),
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    posted_at TIMESTAMPTZ,
    hash_checksum TEXT,
    reversed_from BIGINT REFERENCES cash_vouchers(voucher_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS cash_voucher_lines (
    line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    voucher_id BIGINT NOT NULL REFERENCES cash_vouchers(voucher_id) ON DELETE RESTRICT,
    account_code VARCHAR(20) NOT NULL,
    line_description TEXT,
    debit NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (debit >= 0),
    credit NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
    CHECK (debit <> 0 OR credit <> 0),
    CHECK (NOT (debit > 0 AND credit > 0))
);

CREATE TABLE IF NOT EXISTS audit_log (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    voucher_id BIGINT NOT NULL,
    action VARCHAR(30) NOT NULL,
    actor_id UUID,
    action_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    details JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE OR REPLACE FUNCTION guard_posted_voucher()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_status TEXT;
BEGIN
    IF TG_TABLE_NAME = 'cash_vouchers' THEN
        IF TG_OP = 'DELETE' AND OLD.status = 'POSTED' THEN
            RAISE EXCEPTION 'Voucher POSTED tidak boleh dihapus; buat jurnal pembalik.';
        END IF;
        IF TG_OP = 'UPDATE' AND OLD.status = 'POSTED' THEN
            IF NEW.status <> 'REVERSED' THEN
                RAISE EXCEPTION 'Voucher POSTED tidak boleh diubah; gunakan jurnal pembalik.';
            END IF;
        END IF;
        RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
    ELSE
        IF TG_OP = 'DELETE' THEN
            SELECT status INTO v_status FROM cash_vouchers WHERE voucher_id = OLD.voucher_id;
        ELSE
            SELECT status INTO v_status FROM cash_vouchers WHERE voucher_id = NEW.voucher_id;
        END IF;
        IF v_status = 'POSTED' THEN
            RAISE EXCEPTION 'Baris voucher POSTED tidak boleh diubah atau dihapus.';
        END IF;
        RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS guard_voucher_header ON cash_vouchers;
CREATE TRIGGER guard_voucher_header
BEFORE UPDATE OR DELETE ON cash_vouchers
FOR EACH ROW EXECUTE FUNCTION guard_posted_voucher();

DROP TRIGGER IF EXISTS guard_voucher_lines ON cash_voucher_lines;
CREATE TRIGGER guard_voucher_lines
BEFORE UPDATE OR DELETE ON cash_voucher_lines
FOR EACH ROW EXECUTE FUNCTION guard_posted_voucher();

CREATE OR REPLACE FUNCTION post_cash_voucher(p_voucher_id BIGINT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_debit NUMERIC(15,2);
    v_credit NUMERIC(15,2);
    v_status TEXT;
    v_created_by UUID;
    v_payload TEXT;
BEGIN
    SELECT status, created_by INTO v_status, v_created_by
      FROM cash_vouchers WHERE voucher_id = p_voucher_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Voucher tidak ditemukan'; END IF;
    IF v_status <> 'DRAFT' THEN RAISE EXCEPTION 'Hanya voucher DRAFT yang dapat diposting'; END IF;

    SELECT COALESCE(SUM(debit),0), COALESCE(SUM(credit),0)
      INTO v_debit, v_credit
      FROM cash_voucher_lines WHERE voucher_id = p_voucher_id;
    IF v_debit = 0 OR v_debit <> v_credit THEN
        RAISE EXCEPTION 'Voucher tidak seimbang: debit %, kredit %', v_debit, v_credit;
    END IF;

    v_payload := p_voucher_id::text || '|' || v_debit::text || '|' ||
                 v_credit::text || '|' || clock_timestamp()::text;
    UPDATE cash_vouchers
       SET status = 'POSTED',
           posted_at = now(),
           hash_checksum = encode(digest(v_payload || current_setting('app.hash_secret', true), 'sha256'),'hex')
     WHERE voucher_id = p_voucher_id;

    INSERT INTO audit_log(voucher_id, action, actor_id, details)
    VALUES (p_voucher_id, 'POSTED', v_created_by,
            jsonb_build_object('total_debit',v_debit,'total_credit',v_credit));
END;
$$;

-- Catatan implementasi:
-- 1) Atur app.hash_secret pada konfigurasi server/DB yang terlindungi.
-- 2) Aplikasi harus mengisi created_by dari user yang terautentikasi, bukan dari input bebas.
-- 3) Reversing entry dibuat sebagai voucher BARU dengan debit/kredit dibalik dan
--    reversed_from menunjuk voucher lama. Jangan menghapus voucher lama.
