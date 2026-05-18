-- Phần A: Phân tích và đề xuất giải pháp 
-- 1. Định nghĩa I/O (Dữ liệu đầu vào/Đầu ra):
--    - Tham số IN: p_patient_id (Mã bệnh nhân), p_amount (Số tiền thanh toán).
--    - Tham số OUT: p_message (Chuỗi thông báo trạng thái để hiển thị lên Frontend).

-- 2. Đề xuất 2 chiến lược xử lý:
--    - Chiến lược 1 : Chạy thẳng lệnh UPDATE trừ tiền. Dựa hoàn toàn vào 
--      cơ chế báo lỗi của Database 
--    - Chiến lược 2 : Dùng SELECT để truy xuất 
--      số dư, đối chiếu các điều kiện hợp lệ (số tiền > 0, số dư >= số tiền) rồi mới cập nhật.

-- 3. So sánh và Lựa chọn:
--    - Chiến lược 1: Hiệu năng tốt hơn nhưng bảo mật nghiệp vụ kém, dễ lọt lỗ hổng, 
--      khó trả về thông báo lỗi chi tiết cho người dùng.
--    - Chiến lược 2: Kiểm soát bảo mật cực kỳ chặt chẽ, xử lý thông báo lỗi chi tiết 
--      (Lỗi số âm, thiếu tiền...). Hiệu năng chậm hơn một chút nhưng an toàn tuyệt đối.

-- >>>> Chọn chiến lược 2:

-- Phần B: Thiết kế và triển khai
-- 1. Thiết kế luồng logic (Logical Flow):
--    - B1. Khởi tạo: Mở TRANSACTION.
--    - B2. Rào chắn 1: Bẫy lỗi bảo mật (Số tiền <= 0 -> ROLLBACK).
--    - B3. Khóa & Truy xuất: SELECT số dư FOR UPDATE (Ngăn click thanh toán đúp).
--    - B4. Rào chắn 2: Bẫy lỗi nghiệp vụ (Số dư < Số tiền -> ROLLBACK).
--    - B5. Cập nhật & Hoàn tất: UPDATE ví, UPDATE nợ -> COMMIT.

-- 2. Triển khai  Code:

DROP PROCEDURE IF EXISTS ProcessOneTouchPayment;

DELIMITER //

CREATE PROCEDURE ProcessOneTouchPayment(
    IN p_patient_id INT,
    IN p_amount DECIMAL(18,2),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_balance DECIMAL(18,2);
    START TRANSACTION;
    IF p_amount <= 0 THEN
        ROLLBACK;
        SET p_message = 'Lỗi bảo mật: Số tiền thanh toán phải lớn hơn 0.';
    ELSE
        SELECT balance INTO v_balance 
        FROM Wallets 
        WHERE patient_id = p_patient_id 
        FOR UPDATE;

        IF v_balance IS NULL THEN
            ROLLBACK;
            SET p_message = 'Lỗi: Không tìm thấy ví điện tử của bệnh nhân.';
        ELSEIF v_balance < p_amount THEN
            ROLLBACK;
            SET p_message = 'Lỗi từ chối: Số dư ví không đủ để thanh toán.';
        ELSE
            UPDATE Wallets 
            SET balance = balance - p_amount 
            WHERE patient_id = p_patient_id;

            UPDATE Patient_Invoices 
            SET total_due = total_due - p_amount 
            WHERE patient_id = p_patient_id;

            COMMIT;
            SET p_message = 'Thành công: Đã thanh toán viện phí qua Ví điện tử.';
        END IF;
    END IF;
END //

DELIMITER ;

-- 3. NGHIỆM THU (TEST CASES)

-- Test Case 1: Giao dịch hợp lệ (Đủ tiền)
 CALL ProcessOneTouchPayment(1, 100000, @status_msg);
 SELECT @status_msg AS KetQua_TestCase1;

-- Test Case 2: Chặn lỗi số dư ví không đủ
 CALL ProcessOneTouchPayment(2, 200000, @status_msg);
 SELECT @status_msg AS KetQua_TestCase2;

-- Test Case 3: Bẫy lỗi dữ liệu (Truyền số tiền âm)
CALL ProcessOneTouchPayment(1, -50000, @status_msg);
SELECT @status_msg AS KetQua_TestCase3;
