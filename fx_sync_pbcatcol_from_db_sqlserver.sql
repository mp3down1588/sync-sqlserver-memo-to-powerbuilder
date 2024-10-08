/****** Script for sync pbcatcol  from database in sql server******/
----步骤1:对于已经存在的表，根据scheme,表名,同步object id
UPDATE pbcatcol
SET pbc_tid=pbcatcol_src.pbc_tid
FROM pbcatcol,
(
SELECT 
t.name AS pbc_tnam,
t.object_id AS pbc_tid,
s.name AS pbc_ownr,
CONVERT(varchar(254),ep.value) AS pbc_cmnt
FROM 
	sys.tables t
JOIN 
	sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN 
	sys.extended_properties ep 
	ON ep.major_id = t.object_id 
	AND ep.minor_id = 0  -- 0 indicates that the property is at the table level, not a column level
	AND ep.name = 'MS_Description'
) pbcatcol_src
WHERE 
pbcatcol.pbc_tnam=pbcatcol_src.pbc_tnam
AND
pbcatcol.pbc_ownr=pbcatcol_src.pbc_ownr
AND
pbcatcol.pbc_tid<>pbcatcol_src.pbc_tid
GO
----步骤2:对于已经存在的列，根据scheme,表名,列名,同步column id
UPDATE pbcatcol
SET pbc_cid=pbcatcol_src.pbc_cid
FROM pbcatcol,
(
SELECT 
    t.name AS pbc_tnam,
    t.object_id AS pbc_tid,
    s.name AS pbc_ownr,
    c.name AS pbc_cnam,
    c.column_id AS pbc_cid,
    CONVERT(varchar(254),ep.value) AS pbc_cmnt
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
JOIN 
    sys.columns c ON t.object_id = c.object_id
LEFT JOIN 
    sys.extended_properties ep 
    ON t.object_id = ep.major_id 
    AND c.column_id = ep.minor_id 
    AND ep.name = 'MS_Description'
) pbcatcol_src
WHERE 
pbcatcol.pbc_tnam=pbcatcol_src.pbc_tnam
AND
pbcatcol.pbc_ownr=pbcatcol_src.pbc_ownr
AND
pbcatcol.pbc_tid=pbcatcol_src.pbc_tid
AND
pbcatcol.pbc_cnam=pbcatcol_src.pbc_cnam
AND
pbcatcol.pbc_cid<>pbcatcol_src.pbc_cid
GO
---------------------------------------------------------------
----步骤3:用新的description更新pbc_labl,pbc_hdr,pbc_cmnt
UPDATE pbcatcol
----TODO:可以客制化自己的规则，现有规则是，如果已经通过pb或者sql server设置过了，则就不更新了
SET pbc_cmnt=(CASE WHEN(pbcatcol.pbc_cmnt IS NULL OR LEN(ISNULL(pbcatcol.pbc_cmnt,''))=0) THEN pbcatcol_src.pbc_cmnt ELSE pbcatcol.pbc_cmnt END)
,pbc_labl=(CASE WHEN(pbcatcol.pbc_labl IS NULL OR LEN(ISNULL(pbcatcol.pbc_labl,''))=0) THEN pbcatcol_src.pbc_cmnt ELSE pbcatcol.pbc_labl END)
,pbc_hdr=(CASE WHEN(pbcatcol.pbc_hdr IS NULL OR LEN(ISNULL(pbcatcol.pbc_hdr,''))=0) THEN pbcatcol_src.pbc_cmnt ELSE pbcatcol.pbc_hdr END)
FROM pbcatcol,
(
SELECT 
    t.name AS pbc_tnam,
    t.object_id AS pbc_tid,
    s.name AS pbc_ownr,
    c.name AS pbc_cnam,
    c.column_id AS pbc_cid,
    CONVERT(varchar(254),ep.value) AS pbc_cmnt
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
JOIN 
    sys.columns c ON t.object_id = c.object_id
LEFT JOIN 
    sys.extended_properties ep 
    ON t.object_id = ep.major_id 
    AND c.column_id = ep.minor_id 
    AND ep.name = 'MS_Description'
) pbcatcol_src
WHERE 
pbcatcol.pbc_tnam=pbcatcol_src.pbc_tnam
AND
pbcatcol.pbc_ownr=pbcatcol_src.pbc_ownr
AND
pbcatcol.pbc_tid=pbcatcol_src.pbc_tid
AND
pbcatcol.pbc_cnam=pbcatcol_src.pbc_cnam
AND
pbcatcol.pbc_cid=pbcatcol_src.pbc_cid
GO
----insert into pbcatcol which is not existed
INSERT INTO pbcatcol
(pbc_tnam
,pbc_tid
,pbc_ownr
,pbc_cnam
,pbc_cid
,pbc_labl
,pbc_lpos
,pbc_hdr
,pbc_hpos
,pbc_jtfy
,pbc_mask
,pbc_case
,pbc_hght
,pbc_wdth
,pbc_ptrn
,pbc_bmap
,pbc_init
,pbc_cmnt
,pbc_edit
,pbc_tag)
SELECT 
t.name AS pbc_tnam,
t.object_id AS pbc_tid,
s.name AS pbc_ownr,
c.name AS pbc_cnam,
c.column_id AS pbc_cid,
-----------------------
---TODO:在此按照实际需求设置默认值
CONVERT(varchar(254),ep.value) AS pbc_labl,
23 AS pbc_lpos,
CONVERT(varchar(254),ep.value) AS pbc_hdr,
25 AS pbc_hpos,
25 AS pbc_jtfy,
NULL AS pbc_mask,
0 AS pbc_case,
0 AS pbc_hght,
0 AS pbc_wdth,
NULL AS pbc_ptrn,
'N' AS pbc_bmap,
NULL AS pbc_init,
CONVERT(varchar(254),ep.value) AS pbc_edit,
NULL AS pbc_edit,
NULL AS pbc_tag
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
JOIN 
    sys.columns c ON t.object_id = c.object_id
LEFT JOIN 
    sys.extended_properties ep 
    ON t.object_id = ep.major_id 
    AND c.column_id = ep.minor_id 
    AND ep.name = 'MS_Description'
WHERE t.name+'||'+CONVERT(varchar(254),t.object_id)+'||'+s.name+'||'+c.name+'||'+CONVERT(varchar(254),c.column_id) not in 
(
	SELECT 
	pbc_tnam+'||'+CONVERT(varchar(254),pbc_tid)+'||'+pbc_ownr+'||'+pbc_cnam+'||'+CONVERT(varchar(254),pbc_cid) FROM pbcatcol
)
ORDER BY 
	s.name, 
	t.name
GO
