-- Variable declarations
DECLARE @TableName NVARCHAR(128);
DECLARE @TableDescription NVARCHAR(254);
DECLARE @SchemaName NVARCHAR(128) = 'dbo';  -- Default schema name
DECLARE @SQL NVARCHAR(MAX);
DECLARE @PropertyExists INT;

-- Cursor to iterate through all records in pbcattbl
DECLARE TableCursor CURSOR FOR
SELECT
	pbt_ownr,     -- Scheme
    pbt_tnam,     -- Table name
    pbt_cmnt      -- Table description
FROM 
    pbcattbl;

-- Open the cursor
OPEN TableCursor;

-- Fetch the first row
FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName, @TableDescription;

-- Loop through all the rows
WHILE @@FETCH_STATUS = 0 
BEGIN
	-- Check if the MS_Description property already exists for the table
    SELECT @PropertyExists = COUNT(*)
    FROM sys.extended_properties ep
    JOIN sys.tables t ON ep.major_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE ep.name = N'MS_Description'
      AND s.name = @SchemaName
      AND t.name = @TableName
      AND ep.minor_id = 0;  -- Minor_id = 0 means it's a table-level property
      IF LEN(ISNULL(@TableDescription,''))>0
      BEGIN
		IF @PropertyExists > 0
			BEGIN
			SET @SQL = N'EXEC sp_updateextendedproperty 
							@name = N''MS_Description'', 
							@value = @TableDescription, 
							@level0type = N''SCHEMA'', 
							@level0name = @SchemaName, 
							@level1type = N''TABLE'', 
							@level1name = @TableName;';
			END
		ELSE
			BEGIN
			SET @SQL = N'EXEC sp_addextendedproperty 
							@name = N''MS_Description'', 
							@value = @TableDescription, 
							@level0type = N''SCHEMA'', 
							@level0name = @SchemaName, 
							@level1type = N''TABLE'', 
							@level1name = @TableName;';
			END
		-- Execute the SQL with parameters
		EXEC sp_executesql 
			@SQL, 
			N'@SchemaName NVARCHAR(128), @TableName NVARCHAR(128), @TableDescription NVARCHAR(254)', 
			@SchemaName, @TableName, @TableDescription;
		END
    -- Fetch the next row
    FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName, @TableDescription;
END;
-- Close and deallocate the cursor
CLOSE TableCursor;
DEALLOCATE TableCursor;
