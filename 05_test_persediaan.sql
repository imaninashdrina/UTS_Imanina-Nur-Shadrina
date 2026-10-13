-- Jalankan setelah 02_inventory_trigger.sql pada DATABASE UJI.
INSERT INTO inventory_items(item_id,item_name,stock_qty,unit_cost)
VALUES ('ITM001','Raket demo',1,2500000)
ON CONFLICT (item_id) DO UPDATE SET stock_qty=1, unit_cost=2500000;

-- Seharusnya sukses: stok 1 menjadi 0.
INSERT INTO inventory_transactions(item_id,trx_type,qty)
VALUES ('ITM001','SALE',1);

-- Seharusnya GAGAL dan rollback: stok 0 tidak cukup untuk menjual 1 unit.
-- Jalankan perintah ini terpisah agar mudah melihat error:
-- INSERT INTO inventory_transactions(item_id,trx_type,qty)
-- VALUES ('ITM001','SALE',1);

SELECT * FROM inventory_items WHERE item_id='ITM001';
SELECT * FROM inventory_movement_audit WHERE item_id='ITM001' ORDER BY audit_id;
