-- Jalankan setelah 01_schema_jurnal.sql pada DATABASE UJI.
INSERT INTO chart_of_accounts(account_code, account_name, normal_balance, report_class)
VALUES ('1000','Kas','DEBIT','ASSET'), ('5000','Beban Operasional','DEBIT','EXPENSE')
ON CONFLICT (account_code) DO NOTHING;

INSERT INTO journal_headers(transaction_date, reference_no, description)
VALUES (CURRENT_DATE, 'TEST-JRN-001', 'Uji jurnal seimbang')
RETURNING journal_id;
-- Ganti :journal_id dengan ID yang dikembalikan (contoh di bawah pakai subquery referensi).
INSERT INTO journal_lines(header_id, account_id, debit, credit)
SELECT h.journal_id, a.account_id, 100000, 0
FROM journal_headers h CROSS JOIN chart_of_accounts a
WHERE h.reference_no='TEST-JRN-001' AND a.account_code='5000';
INSERT INTO journal_lines(header_id, account_id, debit, credit)
SELECT h.journal_id, a.account_id, 0, 100000
FROM journal_headers h CROSS JOIN chart_of_accounts a
WHERE h.reference_no='TEST-JRN-001' AND a.account_code='1000';
UPDATE journal_headers SET posting_status='POSTED' WHERE reference_no='TEST-JRN-001';
-- Uji negatif opsional: buat header baru dengan debit != kredit; UPDATE ke POSTED harus gagal.
