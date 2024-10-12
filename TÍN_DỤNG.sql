
--------------------------------------------------------------------------------------------------------------
				        /*DANH SÁCH HỢP ĐỒNG TÍN DỤNG THEO KHU VỰC*/
--------------------------------------------------------------------------------------------------------------
CREATE PROC PRC_DS_HOPDONG_TINDUNG
	@MaKV	NVARCHAR(5)
	,@year	INT
AS
BEGIN
	SELECT 
		A.MA_HOPDONG_TINDUNG				 AS [MÃ HỢP ĐỒNG]
		,B.TEN_KHACHHANG					 AS	[TÊN KHÁCH HÀNG]
		,C.TEN_CHINHANH						 AS [TÊN CHI NHÁNH]
		,A.SOTIEN							 AS	[SỐ TIỀN]
		,D.TEN_KHUVUC						 AS [TÊN KHU VỰC]
	FROM HOPDONG_TINDUNG A
	INNER JOIN KHACHHANG B
	ON A.MA_KHACHHANG = B.MA_KHACHHANG
	INNER JOIN CHINHANH C
	ON B.MA_CHINHANH = C.MA_CHINHANH
	INNER JOIN KHUVUC D
	ON C.MA_KHUVUC =D.MA_KHUVUC
	WHERE D.MA_KHUVUC = @MaKV
		AND YEAR(A.NGAY_GIAINGAN) = @year
END

EXEC PRC_DS_HOPDONG_TINDUNG 'A01',2023

--------------------------------------------------------------------------------------------------------------
				        /*DANH SÁCH HỢP ĐỒNG TÍN DỤNG THEO KHU VỰC*/
--------------------------------------------------------------------------------------------------------------
	
ALTER PROC PRC_DS_HOPDONG_TINDUNG
	@year INT
AS
BEGIN

	-- Tạo biến bảng @DS_HD_TINDUNG để lưu trữ dữ liệu tính toán Số lượng khoản vay và Dư nợ gốc
	DECLARE @DS_HD_TINDUNG TABLE
	(
	 [TIEUCHI]		NVARCHAR (200)
	,[SOLUONG]		INT
	,[SOTIEN]		NUMERIC(18,2)
	)

	INSERT INTO @DS_HD_TINDUNG
	SELECT * 
	FROM
	(
	--MỤC ĐÍCH CHO VAY
	SELECT
		'A1 - ' + B.TEN_MUCDICH_CAP1	AS [TIEUCHI]
		,COUNT(A.MA_HOPDONG_TINDUNG)	AS [SOLUONG]
		,SUM(A.SOTIEN)					AS [SOTIEN]
	FROM HOPDONG_TINDUNG A
		INNER JOIN MUCDICH_CAPTINDUNG B
		ON A.MA_MUCDICH_CAPTD = B.MA_MUCDICH_CAPTD
		INNER JOIN HINHTHUC_CAPTINDUNG C
		ON A.MA_HINHTHUC_CAPTD = C.MA_HINHTHUC_CAPTD
	WHERE YEAR(A.NGAY_GIAINGAN) = @year
	GROUP BY 
		B.TEN_MUCDICH_CAP1
	UNION ALL
	--HÌNH THỨC CHO VAY
	SELECT 
		'B1 - ' + C.TEN_HINHTHUC_CAP1	AS [TIEUCHI]
		,COUNT(A.MA_HOPDONG_TINDUNG)	AS [SOLUONG]
		,SUM(A.SOTIEN)					AS [SOTIEN]
	FROM HOPDONG_TINDUNG A
		INNER JOIN HINHTHUC_CAPTINDUNG C
		ON A.MA_HINHTHUC_CAPTD = C.MA_HINHTHUC_CAPTD
	WHERE YEAR(A.NGAY_GIAINGAN) = @year
	GROUP BY C.TEN_HINHTHUC_CAP1		
	
	UNION ALL
	--NGÀNH NGHỀ KINH TẾ
	SELECT 
		'C1 - ' + C1.TEN_NGANHNGHE_KINHTE_CAP01	AS [TIEUCHI]
		,COUNT(A.MA_HOPDONG_TINDUNG)			AS [SOLUONG]
		,SUM(A.SOTIEN)							AS [SOTIEN]
	FROM HOPDONG_TINDUNG A
	INNER JOIN KHACHHANG D
	ON A.MA_KHACHHANG = D.MA_KHACHHANG
	INNER JOIN NGANHNGHE_KINHTE_CAP03 C3
	ON D.MA_NGANHNGHE_KINHTE = C3.MA_NGANHNGHE_KINHTE_CAP03
	INNER JOIN NGANHNGHE_KINHTE_CAP02 C2
	ON C3.MA_NGANHNGHE_KINHTE_CAP02 = C2.MA_NGANHNGHE_KINHTE_CAP02
	INNER JOIN NGANHNGHE_KINHTE_CAP01 C1
	ON C2.MA_NGANHNGHE_KINHTE_CAP01 = C1.MA_NGANHNGHE_KINHTE_CAP01
	WHERE YEAR(A.NGAY_GIAINGAN) = @year
	GROUP BY 
	C1.TEN_NGANHNGHE_KINHTE_CAP01
	) AS FINAL
	-- THÊM CÁC ĐẦU MỤC BÁO CÁO
	INSERT INTO @DS_HD_TINDUNG VALUES (N'A0 - Mục đích cấp tín dụng',0,0);
	INSERT INTO @DS_HD_TINDUNG VALUES (N'B0 - Hình thức cấp tín dụng',0,0);
	INSERT INTO @DS_HD_TINDUNG VALUES (N'C0 - Theo ngành nghề kinh tế',0,0);
	
	-- CẬP NHẬT SỐ LƯỢNG.
	--> MỤC ĐÍCH
	UPDATE	@DS_HD_TINDUNG 
	SET		SOLUONG = (SELECT SUM(SOLUONG) FROM @DS_HD_TINDUNG WHERE SUBSTRING(TIEUCHI,1,2) = 'A1')
	WHERE	TIEUCHI LIKE 'A0%';
	--> HÌNH THỨC
	UPDATE	@DS_HD_TINDUNG 
	SET		SOLUONG = (SELECT SUM(SOLUONG) FROM @DS_HD_TINDUNG WHERE SUBSTRING(TIEUCHI,1,2) = 'B1')
	WHERE	TIEUCHI LIKE 'B0%';
	--> NGÀNH NGHỀ
	UPDATE	@DS_HD_TINDUNG 
	SET		SOLUONG = (SELECT SUM(SOLUONG) FROM @DS_HD_TINDUNG WHERE SUBSTRING(TIEUCHI,1,2) = 'C1')
	WHERE	TIEUCHI LIKE 'C0%';
	
	-- CẬP NHẬT SỐ TIỀN.
	--> MỤC ĐÍCH
	UPDATE	@DS_HD_TINDUNG 
	SET		SOTIEN = (SELECT SUM(SOTIEN) FROM @DS_HD_TINDUNG WHERE SUBSTRING(TIEUCHI,1,2) = 'A1')
	WHERE	TIEUCHI LIKE 'A0%';
	--> HÌNH THỨC
	UPDATE	@DS_HD_TINDUNG 
	SET		SOTIEN = (SELECT SUM(SOTIEN) FROM @DS_HD_TINDUNG WHERE SUBSTRING(TIEUCHI,1,2) = 'B1')
	WHERE	TIEUCHI LIKE 'B0%';
	--> NGÀNH NGHỀ
	UPDATE	@DS_HD_TINDUNG 
	SET		SOTIEN = (SELECT SUM(SOTIEN) FROM @DS_HD_TINDUNG WHERE SUBSTRING(TIEUCHI,1,2) = 'C1')
	WHERE	TIEUCHI LIKE 'C0%';
	--Chạy bá0 cáo
	SELECT		* 
	FROM		@DS_HD_TINDUNG
	ORDER BY	TIEUCHI;
END;

EXEC PRC_DS_HOPDONG_TINDUNG 2023

-------------------------------------------------------------------------

ALTER trigger after_1924_TUAN
on KHACHHANG
INSTEAD OF INSERT
AS
BEGIN 
	DECLARE @YEAR INT
	SET		@YEAR = (SELECT YEAR(A.NGAY_SINH) FROM inserted A)
	IF		@YEAR < 1924
			BEGIN 
				RAISERROR ('NĂM SINH KHÔNG HỢP LỆ',10,1)
				ROLLBACK TRANSACTION
			END
	ELSE	
			BEGIN 
				INSERT INTO KHACHHANG (NGAY_SINH)
				SELECT inserted.NGAY_SINH 
				FROM   inserted
			END
END;
ALTER TRIGGER DEL_NO_CUSTOMER
ON CHINHANH
INSTEAD OF DELETE
AS
BEGIN
	DECLARE @CN AS NVARCHAR(10)
	SET		@CN = (SELECT A.MA_CHINHANH FROM deleted A)
	IF @CN  in (SELECT KHACHHANG.MA_CHINHANH FROM KHACHHANG)
		BEGIN 
			print('CHI NHÁNH CÓ KHÁCH HÀNG')
			ROLLBACK TRANSACTION
		END
	ELSE 
		BEGIN
			PRINT('XÓA KHÔNG')
		END
END;


--------------------------------------------------------------------------------------------------

--1) Tính số dư nợ casa của toàn hàng tại thời điểm 31/1.
WITH CTE AS
(
SELECT 	 af_balance     'Số dư',		
		ROW_NUMBER() OVER (PARTITION BY T.casa_account ORDER BY T.actiondate DESC)  'XH' 
FROM Transfer_history T
WHERE actiondate <='2024-01-31'
)
SELECT SUM(CTE.[Số dư]) 'SỐ DƯ TẠI 31/01'
FROM CTE
WHERE CTE.XH = 1

--2) Lập danh sách các ngân hàng đã chuyển khoản, nhận chuyển khoản trong 4 tháng đầu năm 2024 theo các tiêu chí: 
--Mã ngân hàng / số lượng giao dịch đến / số tiền đến / số lượng giao dịch đi / số tiền đi
with DD_den as
(
	SELECT REPLACE(LEFT(destination_account,3),'CAS','VNC')								'MÃ NGÂN HÀNG',
		COUNT(t.destination_account)									'Số lượng giao dịch đến',
		sum(t.decrease)													'Số tiền đến'
	FROM Transfer_history T
	where t.decrease <> 0 AND T.destination_account <> ''
	GROUP BY REPLACE(LEFT(destination_account,3),'CAS','VNC')
),
DD_di as
(
	SELECT REPLACE(LEFT(Sent_account,3),'CAS','VNC')										'MÃ NGÂN HÀNG',
		COUNT(t.Sent_account)											'Số lượng giao dịch đi',
		sum(t.increase)													'Số tiền đi'
	FROM Transfer_history T
	where t.increase <> 0 AND T.Sent_account <> ''
	GROUP BY REPLACE(LEFT(Sent_account,3),'CAS','VNC')
)
SELECT a.* ,
		coalesce(b.[Số lượng giao dịch đi],0)  'Số lượng giao dịch đi',
		coalesce(b.[Số tiền đi],0)				'Số liền đi'
FROM DD_den a
FULL OUTER JOIN DD_di b
ON a.[MÃ NGÂN HÀNG] = b.[MÃ NGÂN HÀNG] 

--3. Tính số tiền mặt đã nộp, đã rút từ VNC theo tháng.
SELECT
		sum(case when T.destination_account ='' then decrease else 0 end) 'Số tiền đã rút',
		sum(case when T.Sent_account ='' then increase else 0 end) 'Số tiền đã nộp'
FROM Transfer_history T
WHERE Transfer_type = 'INN'
group by ISNUMERIC(T.pre_balance)
--4. Giả sử mỗi giao dịch chuyển tiền ngoài ngân hàng, VNC mất 100đ + 0.01% giá trị chuyển khoản. Tính số phí phải nộp theo mỗi tháng.
SELECT MONTH(T.actiondate)					'Tháng',
		sum(T.decrease*0.01% +100)			'Phí chuyển khoản'
FROM Transfer_history T
WHERE transfer_type = 'out' AND decrease <> 0 AND destination_account <> ''
group by MONTH(T.actiondate);
----6. Tính số dư trung bình vào các thời điểm cuối tháng của các khách hàng cá nhân.
WITH DTE as
(
	SELECT T.casa_account		'TK',
			MONTH(T.actiondate) 'Tháng',
			T.af_balance		'Số dư',
			ROW_NUMBER() OVER (PARTITION BY T.casa_account, MONTH(t.actiondate) ORDER BY T.actiondate DESC)  'XH' 
	FROM Transfer_history T
)
SELECT D.Tháng			'Tháng',
		avg(D.[Số dư]) 'Số dư Trung bình'
FROM DTE D
WHERE D.XH =1
GROUP BY  D.Tháng
ORDER BY D.Tháng

CREATE PROC THEM_MOI_KEHOACH_MUANO
AS
BEGIN
	DECLARE @MA_HOPDONG_TINDUNG		AS	NVARCHAR(20);					
    DECLARE @SOTIEN					AS	numeric(18,2);
    DECLARE @NGAY_GIAINGAN			AS	date;
    DECLARE @NGAY_DENHAN			AS	date;
    DECLARE @LAISUAT				AS	numeric(5,2);

	DECLARE CURSOR_KEHOACH CURSOR FOR							
    SELECT DISTINCT  MA_HOPDONG_TINDUNG FROM HOPDONG_TINDUNG;	

    OPEN CURSOR_KEHOACH;										
    FETCH NEXT FROM  CURSOR_KEHOACH INTO @MA_HOPDONG_TINDUNG;	
	
    WHILE @@FETCH_STATUS = 0									
    BEGIN
		SET @SOTIEN			= (SELECT SOTIEN		FROM HOPDONG_TINDUNG WHERE MA_HOPDONG_TINDUNG = @MA_HOPDONG_TINDUNG);
		SET @NGAY_GIAINGAN	= (SELECT NGAY_GIAINGAN FROM HOPDONG_TINDUNG WHERE MA_HOPDONG_TINDUNG = @MA_HOPDONG_TINDUNG);
		SET @NGAY_DENHAN	= (SELECT NGAY_DAOHAN	FROM HOPDONG_TINDUNG WHERE MA_HOPDONG_TINDUNG = @MA_HOPDONG_TINDUNG);
		SET @LAISUAT		= (SELECT LAISUAT		FROM HOPDONG_TINDUNG WHERE MA_HOPDONG_TINDUNG = @MA_HOPDONG_TINDUNG);
		
        EXEC TAO_KEHOACH_TRANO  @MA_HOPDONG_TINDUNG, @SOTIEN, @NGAY_GIAINGAN, @NGAY_DENHAN, @LAISUAT;
        FETCH NEXT FROM CURSOR_KEHOACH INTO @MA_HOPDONG_TINDUNG;			
    END;
    CLOSE		CURSOR_KEHOACH;								
    DEALLOCATE	CURSOR_KEHOACH;								
END;


EXEC THEM_MOI_KEHOACH_MUANO

