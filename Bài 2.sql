-- Phần A: Phân tích
-- code trên hình khi chạy thì có tình trạng đã xóa giường cũ những chưa gán giường mới đã vi phạm 2 tính chất trong nguyên lí ACID:
-- Tính nguyên tử (Atomicity)
-- Tính nhất quán (Consistency)

-- Phần B: Sửa chữa mã nguồn
-- 1. Xóa thủ tục cũ
DROP PROCEDURE IF EXISTS TransferBed;

DELIMITER //

-- 1. Xóa thủ tục cũ
DROP PROCEDURE IF EXISTS TransferBed //

-- 2. Tạo lại thủ tục 
CREATE PROCEDURE TransferBed(IN p_patient_id INT, IN p_new_bed_id INT)
BEGIN
    START TRANSACTION;
    UPDATE Beds 
    SET patient_id = NULL 
    WHERE patient_id = p_patient_id;
    
    UPDATE Beds
    SET patient_id = p_patient_id 
    WHERE bed_id = p_new_bed_id;

    COMMIT;
    SELECT 'Thành công: Đã chuyển giường cho bệnh nhân!' AS Message;
END //

DELIMITER ;