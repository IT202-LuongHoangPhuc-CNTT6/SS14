-- Phần A: Phân tích
-- Dữ liệu đầu vào (Mã bệnh nhân, Mã thuốc, Số lượng) -> Đề xuất dùng tham số IN.
-- Dữ liệu đầu ra (Thông báo trạng thái) -> Đề xuất dùng tham số OUT.
-- Giải pháp: Kiểm tra tồn kho trước khi UPDATE. Nếu thiếu thì ROLLBACK, nếu đủ thì COMMIT.

-- Phần B: Triển khai mã nguồn

-- 1. Xóa thủ tục cũ
DROP PROCEDURE IF EXISTS DispenseMedicine;
DELIMITER //
-- 2. Tạo lại thủ tục mới
CREATE PROCEDURE DispenseMedicine( IN p_patient_id INT, IN p_medicine_id INT, IN p_quantity INT, OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_price DECIMAL(18,2);

    START TRANSACTION;
    SELECT stock, price INTO v_stock, v_price
    FROM Medicines
    WHERE medicine_id = p_medicine_id;

    IF p_quantity > v_stock THEN
        ROLLBACK;
        SET p_message = 'Lỗi: Số lượng tồn kho không đủ';
    ELSE
        UPDATE Medicines
        SET stock = stock - p_quantity
        WHERE medicine_id = p_medicine_id;

        UPDATE Patient_Invoices
        SET total_due = total_due + (v_price * p_quantity)
        WHERE patient_id = p_patient_id;
        COMMIT;
        SET p_message = 'Đã cấp phát thành công';
    END IF;

END //

DELIMITER ;

-- PHẦN KIỂM THỬ 
-- Test Case 1: Cấp phát hợp lệ
 CALL DispenseMedicine(1, 1, 10, @status);
SELECT @thongbao AS 'Trạng thái hệ thống';

-- Test Case 2: Chặn lỗi vượt tồn kho
 CALL DispenseMedicine(1, 2, 10, @status);
SELECT @thongbao AS 'Trạng thái hệ thống';
