-- Variable declarations
DECLARE @TableName NVARCHAR(128);
DECLARE @ColumnName NVARCHAR(128);
DECLARE @ColumnDescription NVARCHAR(254);
DECLARE @SchemaName NVARCHAR(128) = 'dbo';  -- Default schema name
DECLARE @SQL NVARCHAR(MAX);
DECLARE @PropertyExists INT;

-- Cursor to iterate through all records in pbcatcol
DECLARE ColumnCursor CURSOR FOR
SELECT
	pbc_ownr,       -- Scheme name
    pbc_tnam,       -- Table name
    pbc_cnam,       -- Column name
    pbc_cmnt    -- Column description
FROM 
    pbcatcol;

-- Open the cursor
OPEN ColumnCursor;

-- Fetch the first row
FETCH NEXT FROM ColumnCursor INTO @SchemaName, @TableName, @ColumnName, @ColumnDescription;

-- Loop through all the rows
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Check if the MS_Description property already exists for the column
    SELECT @PropertyExists = COUNT(*)
    FROM sys.extended_properties ep
    JOIN sys.columns c ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
    JOIN sys.tables t ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE ep.name = N'MS_Description'
      AND s.name = @SchemaName
      AND t.name = @TableName
      AND c.name = @ColumnName;
    -- If the property exists, update it; otherwise, add it
    IF LEN(ISNULL(@ColumnDescription,''))>0
      BEGIN
		IF @PropertyExists > 0
		BEGIN
			SET @SQL = N'EXEC sp_updateextendedproperty 
							@name = N''MS_Description'', 
							@value = @ColumnDescription, 
							@level0type = N''SCHEMA'', 
							@level0name = @SchemaName, 
							@level1type = N''TABLE'', 
							@level1name = @TableName, 
							@level2type = N''COLUMN'', 
							@level2name = @ColumnName;';
		END
		ELSE
		BEGIN
			SET @SQL = N'EXEC sp_addextendedproperty 
							@name = N''MS_Description'', 
							@value = @ColumnDescription, 
							@level0type = N''SCHEMA'', 
							@level0name = @SchemaName, 
							@level1type = N''TABLE'', 
							@level1name = @TableName, 
							@level2type = N''COLUMN'', 
							@level2name = @ColumnName;';
		END
		-- Execute the SQL with parameters
		EXEC sp_executesql 
			@SQL, 
			N'@SchemaName NVARCHAR(128), @TableName NVARCHAR(128), @ColumnName NVARCHAR(128), @ColumnDescription NVARCHAR(254)', 
			@SchemaName, @TableName, @ColumnName, @ColumnDescription;
	END
    -- Fetch the next row
    FETCH NEXT FROM ColumnCursor INTO @SchemaName, @TableName, @ColumnName, @ColumnDescription;
END;
-- Close and deallocate the cursor
CLOSE ColumnCursor;
DEALLOCATE ColumnCursor;
