-- SOAL 1: Skema jurnal dan kontrol double-entry
CREATE TABLE IF NOT EXISTS chart_of_accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_code VARCHAR(20) NOT NULL UNIQUE,
    account_name VARCHAR(100) NOT NULL,
    normal_balance VARCHAR(6) NOT NULL CHECK (normal_balance IN ('DEBIT','CREDIT')),
    report_class VARCHAR(30) NOT NULL
        CHECK (report_class IN ('ASSET','LIABILITY','EQUITY','REVENUE','EXPENSE'))
);

CREATE TABLE IF NOT EXISTS journal_headers (
    journal_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_date DATE NOT NULL,
    reference_no VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    posting_status VARCHAR(10) NOT NULL DEFAULT 'DRAFT'
        CHECK (posting_status IN ('DRAFT','POSTED','REVERSED')),
    created_by TEXT NOT NULL DEFAULT current_user,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS journal_lines (
    line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    header_id BIGINT NOT NULL REFERENCES journal_headers(journal_id) ON DELETE RESTRICT,
    account_id BIGINT NOT NULL REFERENCES chart_of_accounts(account_id) ON DELETE RESTRICT,
    debit NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (debit >= 0),
    credit NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
    CONSTRAINT chk_line_not_both_zero CHECK (debit <> 0 OR credit <> 0),
    CONSTRAINT chk_line_one_side CHECK (NOT (debit > 0 AND credit > 0))
);

-- Keseimbangan lintas-baris tidak dapat dijamin CHECK biasa.
-- Fungsi ini memvalidasi jurnal ketika header dipindahkan ke POSTED.
CREATE OR REPLACE FUNCTION validate_journal_before_post()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    total_debit NUMERIC(15,2);
    total_credit NUMERIC(15,2);
    line_count INTEGER;
BEGIN
    IF NEW.posting_status = 'POSTED'
       AND OLD.posting_status IS DISTINCT FROM 'POSTED' THEN
        SELECT COALESCE(SUM(debit),0), COALESCE(SUM(credit),0), COUNT(*)
          INTO total_debit, total_credit, line_count
          FROM journal_lines WHERE header_id = NEW.journal_id;

        IF line_count < 2 THEN
            RAISE EXCEPTION 'Jurnal harus memiliki minimal dua baris.';
        END IF;
        IF total_debit <> total_credit THEN
            RAISE EXCEPTION 'Jurnal tidak seimbang: debit %, kredit %',
                total_debit, total_credit;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_journal_before_post ON journal_headers;
CREATE TRIGGER trg_validate_journal_before_post
BEFORE UPDATE OF posting_status ON journal_headers
FOR EACH ROW EXECUTE FUNCTION validate_journal_before_post();
