##########################################################################################
    
                Executa uma sequência de sub-consultas, afim de 
                levantar dados para estruturar uma string, que 
                também é uma consulta e que necessita de 
                colunas dinâmicas para funcionar corretamente.
		
##########################################################################################


DECLARE @TENANT INT = 00000;
DECLARE @column_pivot NVARCHAR(MAX), @sql_command NVARCHAR(MAX)


DECLARE @FirstDay VARCHAR(MAX) = CAST((Select DateAdd(mm, DateDiff(mm,0,GetDate()) - 1, 0)) AS DATE)
DECLARE @LastDay VARCHAR(MAX) = CAST((Select DateAdd(mm, DateDiff(mm,0,GetDate()), -1)) AS DATE)
PRINT(@FirstDay)
Print(@LastDay)

SET @column_pivot =
   STUFF((
        SELECT
              DISTINCT ',' + CASE WHEN QUOTENAME(J2.Name) IS NOT NULL THEN QUOTENAME(CONCAT(S2.Name,' » ',J2.Name)) ELSE QUOTENAME(S2.Name) END
        FROM Ticket T
             FULL JOIN TicketStatusHistory TSH2     WITH (NOLOCK) on T.Id = TSH2.TicketId
             FULL JOIN Status S2               WITH (NOLOCK) on TSH2.StatusId = S2.Id
             FULL JOIN Justification J2        WITH (NOLOCK) on TSH2.JustificationId = J2.Id
        WHERE T.TenantId = @TENANT AND T.Number > 0 AND T.IsDeleted = 0 AND T.IsDraft = 0 AND T.ResolvedDate  BETWEEN  @FirstDay AND @LastDay
        AND T.rviceId IN (Select Id from service where
                             TenantId = @TENANT
                             AND ParentServiceId IN(
                                                    11111, 
                                                    22222, 
                                                    33333,
                                                    44444,
													55555
                                                   )
												   )
      FOR XML PATH('')
      ), 1, 1, null);
PRINT @column_pivot;
SET @sql_command ='WITH SERVICOS AS (
                SELECT    ID,
                     PARENTSERVICEID,
                     CONVERT(VARCHAR(1000), NAME) AS NOME,
                 0 AS NIVEL -- NÍVEL 0
                FROM      SERVICE
                WHERE     PARENTSERVICEID IS NULL
            AND          TENANTID ='+CAST(@TENANT AS VARCHAR)+'
                UNION ALL
                           SELECT    T1.ID,
                     T1.PARENTSERVICEID,
                     CONVERT(VARCHAR(1000), SERVICOS.NOME +' + ''' » ''' + '+ T1.NAME) AS NOME,
                     NIVEL+1
                FROM      SERVICE T1
                INNER JOIN SERVICOS
                     ON T1.PARENTSERVICEID = SERVICOS.ID
            WHERE     T1.TENANTID ='+CAST(@TENANT AS VARCHAR)+'
    ),SERVICOS2 AS (
SELECT n3.id ''ID'', (select Name from Service where Id = n2.ParentServiceId) ''Nivel1'',  n2.Name ''Nivel2'', n3.name ''Nivel3''
                FROM      service n3
            right join Service n2
               on n3.ParentServiceId = n2.id and n2.ParentServiceId is not null
            WHERE     n3.tenantid = '+CAST(@TENANT AS VARCHAR)+' and n3.TenantId = n2.TenantId
union all
   SELECT n2.id ''ID'', n1.Name ''Nivel1'',  n2.Name ''Nivel2'', '''' ''Nivel3''
                FROM      service n2
            right join Service n1
               on n2.ParentServiceId = n1.id and n1.ParentServiceId is null
            WHERE     n2.tenantid = '+CAST(@TENANT AS VARCHAR)+' and n1.TenantId = n2.TenantId
union all
   SELECT n1.id ''ID'', Name ''Nivel1'',  '''' ''Nivel2'', '''' ''Nivel3''
                FROM      service n1
            WHERE     n1.tenantid = '+CAST(@TENANT AS VARCHAR)+' and n1.ParentServiceId is null),
HS_1 AS (
    SELECT
                         --T.ResolvedDate AS [Resolvido em],
        T.Id AS IDD
        , T.Number AS [Ticket]
              ,(CASE T.Type WHEN 1 THEN' + '''Interno''' + 'ELSE' + '''Público''' + 'END) AS [Tipo]
              , (SELECT TOP 1 businessname
                 FROM   person
                 WHERE  id = (SELECT TOP 1 personid
                              FROM   personrelationship
                              WHERE  id = (SELECT TOP 1 parentid
                                           FROM   personrelationship
                                           WHERE  personid = (SELECT TOP 1 p.id
                                                              FROM   ticketclient tc
                                                                         LEFT JOIN personrelationship pr
                                                                                   ON pr.id = tc.clientid
                                                                         LEFT JOIN person p
                                                                                   ON p.id = pr.personid
                                                              WHERE  tc.ticketid = T.id)
                                             AND isdeleted = 0)))
        AS [Organização]
              ,(SELECT TOP 1 p.businessname
                FROM   ticketclient tc
                           LEFT JOIN personrelationship pr
                                     ON pr.id = tc.clientid
                           LEFT JOIN person p
                                     ON p.id = pr.personid
                WHERE  tc.ticketid = T.id)
        AS [Solicitante]
              ,SERV.Nome AS [Serviço (Completo)]
              ,SERV2.NIVEL1 AS [Serviço (1º Nível)]
              ,SERV2.NIVEL2 AS [Serviço (2º Nível)]
              ,SERV2.NIVEL3 AS [Serviço (3º Nível)]
              ,C.Name AS [Categoria]
              ,U.Name AS [Urgência]
              ,Tm.Name AS [Responsável: Equipe]
              ,P.BusinessName AS [Responsável]
              ,CASE WHEN J.Name IS NOT NULL THEN CONCAT(S.Name, '+ ''' » ''' +' ,J.Name) ELSE S.Name END AS [Status]
              ,TSH.PermanencyTimeWorkingTime AS [Tempo de permanência]
    FROM Ticket AS T
             FULL JOIN Urgency U              WITH (NOLOCK) on T.UrgencyId = U.Id
             FULL JOIN SERVICOS SERV          WITH (NOLOCK) on T.ServiceId = SERV.Id
             FULL JOIN SERVICOS2 SERV2        WITH (NOLOCK) on T.ServiceId = SERV2.Id
             FULL JOIN Category C             WITH (NOLOCK) on T.CategoryId = C.Id
             FULL JOIN Person P               WITH (NOLOCK) on T.OwnerId = P.Id
             FULL JOIN Team Tm                WITH (NOLOCK) on T.OwnerTeamId = Tm.Id
             FULL JOIN TicketStatusHistory TSH     WITH (NOLOCK) on T.Id = TSH.TicketId
             FULL JOIN Status S               WITH (NOLOCK) on TSH.StatusId = S.Id
             FULL JOIN Justification J        WITH (NOLOCK) on TSH.JustificationId = J.Id
    WHERE
            T.TenantId = '+CAST(@TENANT AS VARCHAR)+'
            --AND T.Number = 681869
            AND T.ResolvedDate  >= ''' + @FirstDay + ''' AND T.ResolvedDate  <= ''' + @LastDay + '''
             AND T.ServiceId IN (Select Id from service where
                             TenantId = '+CAST(@TENANT AS VARCHAR)+'
                             AND ParentServiceId IN(
                                                    450846, -- CS - COLETA
                                                    450848, -- CS - ENTREGA
                                                    451936,
                                                    452800,
													515580
                                                   )
												   )
                  AND T.Isdeleted = 0
            AND T.Isdraft = 0
    GROUP BY
        T.Number
           ,T.Id
           ,S.Name
           ,J.Name
           ,T.Type
           ,T.Id
           ,SERV.NOME
           ,SERV2.NIVEL1
           ,SERV2.NIVEL2
           ,SERV2.NIVEL3
           ,C.Name
           ,U.Name
           ,P.BusinessName
           ,Tm.Name
           ,TSH.PermanencyTimeWorkingTime
    )
SELECT    * INTO #hs_result FROM HS_1
         PIVOT (SUM([Tempo de permanência]) FOR [Status]  IN ('+
         CAST(@column_pivot AS VARCHAR(MAX))
         +')) P ORDER BY IDD desc

		-- Toda a lógica abaixo existe apenas para transformar a colunas de status de segundos para o formato `hh:mm:ss`
		;WITH cte As
		(
			SELECT name, Row_Number() OVER (Order By column_id) AS ind
			FROM TempDb.sys.columns
			WHERE object_id = Object_ID(''tempdb..#hs_result'')
		)
		SELECT * INTO #hs_column_map FROM cte

		DECLARE @Sql varchar(MAX);
		DECLARE @index int;
		DECLARE HSUD_CURSOR CURSOR 
		  LOCAL STATIC READ_ONLY FORWARD_ONLY
		FOR 
		SELECT DISTINCT ind 
		FROM #hs_column_map


		OPEN HSUD_CURSOR
		FETCH NEXT FROM HSUD_CURSOR INTO @index
		WHILE @@FETCH_STATUS = 0
		BEGIN 
			SELECT 
				@Sql = CASE WHEN @index < 14
				THEN CONCAT(@sql, QUOTENAME(name), '','')
				ELSE CONCAT(
					@sql, 
					''CONCAT(COALESCE(CAST(CAST('' + QUOTENAME(name) + '' as int)/3600 as varchar(10)), ''''00'''')'', 
					'','''':'''','', 
					''COALESCE(right(''''0'''' + CAST(CAST('' + QUOTENAME(name) + '' as int)%3600/60 as varchar(2)) ,2), ''''00'''')'', 
					'','''':'''','', 
					''COALESCE(right(''''0'''' + CAST(CAST('' + QUOTENAME(name) + ''as int)%60 as varchar(2)), 2), ''''00''''))'', 
					'' AS '', 
					QUOTENAME(name),
					'','')
				END
			FROM #hs_column_map
			WHERE ind = @index;

			FETCH NEXT FROM HSUD_CURSOR INTO @index
		END
		CLOSE HSUD_CURSOR
		DEALLOCATE HSUD_CURSOR
		SELECT @SQL = SUBSTRING(@SQL, 1, (LEN(@SQL) - 1))
		SELECT @SQL = CONCAT(''SELECT '', @SQL, '' FROM #hs_result'')

		execute(@SQL)

		DROP TABLE #hs_result
		DROP TABLE #hs_column_map
		'

execute(@sql_command)
