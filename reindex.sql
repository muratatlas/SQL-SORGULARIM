/*
SELECT dbschemas.[name] as 'Schema', 
    dbtables.[name] as 'Table', 
    dbindexes.[name] as 'Index',
    indexstats.alloc_unit_type_desc,
    indexstats.avg_fragmentation_in_percent,
    indexstats.page_count
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
and indexstats.avg_fragmentation_in_percent>30
    AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID() --and  dbindexes.[name] is not null
ORDER BY indexstats.avg_fragmentation_in_percent desc

*/

declare @tableName nvarchar(500)

 

declare @indexName nvarchar(500)

 

declare @indexType nvarchar(55)

 

declare @percentFragment decimal(11,2)

 


 

declare FragmentedTableList cursor for

 

SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName,

 

   isnull(ind.name,'') AS IndexName, indexstats.index_type_desc AS IndexType,

 

   indexstats.avg_fragmentation_in_percent

 

FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats

 

   INNER JOIN sys.indexes ind ON ind.object_id = indexstats.object_id

 

        AND ind.index_id = indexstats.index_id

 

  WHERE

 

-- indexstats.avg_fragmentation_in_percent , e.g. >30, you can specify any number in percent

 

   indexstats.avg_fragmentation_in_percent > 5

 

 -- AND ind.Name is not null

 

  ORDER BY indexstats.avg_fragmentation_in_percent DESC

 


 

    OPEN FragmentedTableList

 

    FETCH NEXT FROM FragmentedTableList 

 

    INTO @tableName, @indexName, @indexType, @percentFragment

 


 

    WHILE @@FETCH_STATUS = 0

 

    BEGIN

 

      print 'Processing ' + @indexName + 'on table ' + @tableName + ' which is ' + cast(@percentFragment as nvarchar(50)) + ' fragmented'

 

      

     if @indexName<>''
	 Begin
      if(@percentFragment<= 30)

 

      BEGIN

 

            EXEC( 'ALTER INDEX ' +  @indexName + ' ON ' + @tableName + ' REBUILD; ')

 

       print 'Finished reorganizing ' + @indexName + 'on table ' + @tableName

 

      END

 

      ELSE

 

      BEGIN

 

         EXEC( 'ALTER INDEX ' +  @indexName + ' ON ' + @tableName + ' REORGANIZE;')

 

        print 'Finished rebuilding ' + @indexName + 'on table ' + @tableName

 

      END 
	  End
	  Else
	  Begin

	  EXEC( 'ALTER TAble ' + @tableName + ' REBUILD;')

 

        print 'Finished rebuilding on table ' + @tableName

	  ENd
 

      FETCH NEXT FROM FragmentedTableList 

 

        INTO @tableName, @indexName, @indexType, @percentFragment

 

    END

 

    CLOSE FragmentedTableList

 

    DEALLOCATE FragmentedTableList
