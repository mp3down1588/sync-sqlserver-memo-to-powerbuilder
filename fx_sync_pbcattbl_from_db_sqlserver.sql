/****** Script for sync pbcattbl  from database in sql server******/
----步骤1:对于已经存在的表，根据scheme,表名,同步object id，并用新的description更新pbt_cmnt
UPDATE pbcattbl
SET pbt_tid=pbcattbl_src.pbt_tid
FROM pbcattbl,
(
SELECT 
t.name AS pbt_tnam,
t.object_id AS pbt_tid,
s.name AS pbt_ownr,
CONVERT(varchar(254),ep.value) AS pbt_cmnt
FROM 
	sys.tables t
JOIN 
	sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN 
	sys.extended_properties ep 
	ON ep.major_id = t.object_id 
	AND ep.minor_id = 0  -- 0 indicates that the property is at the table level, not a column level
	AND ep.name = 'MS_Description'
) pbcattbl_src
WHERE 
pbcattbl.pbt_tnam=pbcattbl_src.pbt_tnam
AND
pbcattbl.pbt_ownr=pbcattbl_src.pbt_ownr
AND
pbcattbl.pbt_tid<>pbcattbl_src.pbt_tid
GO
---------------------------------------------------------------
----步骤2:用新的description更新pbt_cmnt
UPDATE pbcattbl
SET pbt_cmnt=pbcattbl_src.pbt_cmnt
FROM pbcattbl,
(
SELECT 
t.name AS pbt_tnam,
t.object_id AS pbt_tid,
s.name AS pbt_ownr,
CONVERT(varchar(254),ep.value) AS pbt_cmnt
FROM 
	sys.tables t
JOIN 
	sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN 
	sys.extended_properties ep 
	ON ep.major_id = t.object_id 
	AND ep.minor_id = 0  -- 0 indicates that the property is at the table level, not a column level
	AND ep.name = 'MS_Description'
) pbcattbl_src
WHERE 
pbcattbl.pbt_tnam=pbcattbl_src.pbt_tnam
AND
pbcattbl.pbt_ownr=pbcattbl_src.pbt_ownr
AND
pbcattbl.pbt_tid=pbcattbl_src.pbt_tid
AND
----仅仅为空的时候才更新，避免pb里面做的调整被冲掉,可以按需要修改此限制
(pbcattbl.pbt_cmnt is null OR LEN(ISNULL(pbcattbl.pbt_cmnt,'')) = 0)
GO
----insert into pbcattbl which is not existed
INSERT INTO pbcattbl
(pbt_tnam
,pbt_tid
,pbt_ownr
,pbd_fhgt
,pbd_fwgt
,pbd_fitl
,pbd_funl
,pbd_fchr
,pbd_fptc
,pbd_ffce
,pbh_fhgt
,pbh_fwgt
,pbh_fitl
,pbh_funl
,pbh_fchr
,pbh_fptc
,pbh_ffce
,pbl_fhgt
,pbl_fwgt
,pbl_fitl
,pbl_funl
,pbl_fchr
,pbl_fptc
,pbl_ffce
,pbt_cmnt)
SELECT 
t.name AS pbt_tnam,
t.object_id AS pbt_tid,
s.name AS pbt_ownr,
-----------------------
---TODO:在此按照需求设置默认值
-10 AS pbd_fhgt,
400 AS pbd_fwgt,
'N' AS pbd_fitl,
'N' AS pbd_funl,
0 AS pbd_fchr,
34 AS pbd_fptc,
'Tahoma' AS pbd_ffce,
-10 AS pbh_fhgt,
400 AS pbh_fwgt,
'N' AS pbh_fitl,
'N' AS pbh_funl,
0 AS pbh_fchr,
34 AS pbh_fptc,
'Tahoma' AS pbh_ffce,
-10 AS pbl_fhgt,
400 AS pbl_fwgt,
'N' AS pbl_fitl,
'N' AS pbl_funl,
0 AS pbl_fchr,
34 AS pbl_fptc,
'Tahoma' AS pbl_ffce,
----------------------------
CONVERT(varchar(254),ep.value) AS pbt_cmnt
FROM 
	sys.tables t
JOIN 
	sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN 
	sys.extended_properties ep 
	ON ep.major_id = t.object_id 
	AND ep.minor_id = 0  -- 0 indicates that the property is at the table level, not a column level
	AND ep.name = 'MS_Description'
WHERE t.name+'||'+CONVERT(varchar(254),t.object_id)+'||'+s.name not in (SELECT pbt_tnam+'||'+CONVERT(varchar(254),pbt_tid)+'||'+pbt_ownr FROM pbcattbl)
ORDER BY 
	s.name, 
	t.name
GO
