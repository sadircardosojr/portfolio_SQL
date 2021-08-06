##########################################################################################
    
              Executa uma sequência de tratamentos de dados 
              e retorna uma tabela tratada. Além de buscar 
              e relacionar dados de várias tabelas diferentes.
              
                        Dúvidas é só chamar! 

##########################################################################################

SELECT tk.number                                                             AS
       'Número',
       tk.serviceid,
       (SELECT CASE tk.origin
                 WHEN 0 THEN 'FirstAction'
                 WHEN 1 THEN 'Cliente'
                 WHEN 2 THEN 'Agente'
                 WHEN 3 THEN 'Email'
                 WHEN 4 THEN 'Gatilho do sistema'
                 WHEN 5 THEN 'Chat'
                 WHEN 6 THEN 'Chat Offline'
                 WHEN 7 THEN 'Email enviado'
                 WHEN 8 THEN 'Formulário'
                 WHEN 9 THEN 'Api'
                 WHEN 10 THEN 'Agendamento automático'
                 WHEN 11 THEN 'JiraIssue'
                 WHEN 12 THEN 'RedmineIssue'
                 WHEN 13 THEN 'ReceivedCall'
                 WHEN 14 THEN 'MadeCall'
                 WHEN 15 THEN 'LostCall'
                 WHEN 16 THEN 'DropoutCall'
                 WHEN 17 THEN 'Acesso remoto'
                 WHEN 18 THEN 'WhatsApp'
                 WHEN 19 THEN 'Integration'
                 WHEN 20 THEN 'ZenviaChat'
                 ELSE 'NotAnsweredCall'
               END)                                                          AS
       'Origem',
       jt.NAME                                                               AS
       'Justificativa',
       st.NAME                                                               AS
       'Status',
       resp.businessname                                                     AS
       'Responsável',
       te.NAME                                                               AS
       'Responsável: Equipe',
       (SELECT TOP 1 p.businessname
        FROM   ticketclient tc
               LEFT JOIN personrelationship pr
                      ON pr.id = tc.clientid
               LEFT JOIN person p
                      ON p.id = pr.personid
        WHERE  tc.ticketid = tk.id)                                          AS
       'Cliente',
       (SELECT businessname
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
                                                     WHERE  tc.ticketid = tk.id)
                                         AND isdeleted = 0)))                AS
       'Organização',
       CONVERT(VARCHAR, CONVERT(DATETIME, Switchoffset(CONVERT(DATETIMEOFFSET,
                                                       tk.createddate), '-03:00'
                                                           )), 20)           AS
       'Aberto em',
       CONVERT(VARCHAR, CONVERT(DATETIME, Switchoffset(CONVERT(DATETIMEOFFSET,
                                                       tk.createddate), '-03:00'
                                                           )), 103)          AS
       'Aberto em - Data',
       CONVERT(VARCHAR, CONVERT(DATETIME, Switchoffset(CONVERT(DATETIMEOFFSET,
                                                       tk.createddate), '-03:00'
                                                           )), 24)           AS
       'Aberto em - Hora',
       tk.resolveddate                                                       AS
       'Resolvido em',
       CONVERT(VARCHAR, CONVERT(DATETIME, Switchoffset(CONVERT(DATETIMEOFFSET,
                                                       tk.resolveddate),
                                                           '-03:00')), 103)  AS
       'Resolvido em - Data',
       CONVERT(VARCHAR, CONVERT(DATETIME, Switchoffset(CONVERT(DATETIMEOFFSET,
                                                       tk.resolveddate),
                                                           '-03:00')), 24)   AS
       'Resolvido em - Hora',
       ct.NAME                                                               AS
       'Categoria',
       ur.NAME                                                               AS
       'Urgência',
       (SELECT Count(*)
        FROM   ticketaction ta1
        WHERE  ta1.ticketid = tk.id
               AND ta1.isdeleted = 0)                                        AS
       'Quantidade de ações',
       (SELECT NAME
        FROM   personclassification
        WHERE  id = (SELECT personclassificationid
                     FROM   person
                     WHERE  id = (SELECT TOP 1 personid
                                  FROM   personrelationship
                                  WHERE  id = (SELECT TOP 1 parentid
                                               FROM   personrelationship
                                               WHERE  personid = (SELECT TOP 1
                                                                 p.id
                                                                  FROM
                                                      ticketclient tc
                                         LEFT JOIN personrelationship pr
                                                ON pr.id = tc.clientid
                                         LEFT JOIN person p
                                                ON p.id = pr.personid
                                         LEFT JOIN personclassification pc
                                                ON
                                         pc.id = p.personclassificationid
                                                     WHERE
                                         tc.ticketid = tk.id)
                                         AND isdeleted = 0))))  AS
       'Cliente: Classificação (Organização)',
       (SELECT value
        FROM   personcustomfieldvalue
        WHERE  customfieldid = 23979
               AND isdeleted = 0
               AND personid = (SELECT id
                               FROM   person
                               WHERE  id = (SELECT TOP 1 personid
                                            FROM   personrelationship
                                            WHERE  id = (SELECT TOP 1 parentid
                                                         FROM
                                                   personrelationship
                                                         WHERE
                                                   personid = (SELECT TOP
                                                              1 p.id
                                                               FROM
                                                   ticketclient tc
                                                   LEFT JOIN personrelationship
                                                             pr
                                                          ON pr.id = tc.clientid
                                                   LEFT JOIN person p
                                                          ON p.id = pr.personid
                                                               WHERE
                                                   tc.ticketid = tk.id)
                                                   AND isdeleted = 0))))     AS
       'Cliente (Organização): Licenças',
       CONVERT(VARCHAR, CONVERT(DATETIME, Switchoffset(CONVERT(DATETIMEOFFSET, (
                                                       SELECT
                                                       value
                                                       FROM
                                                       personcustomfieldvalue
                                                               WHERE
                                                       customfieldid =
                                                       23528
                                                       AND isdeleted = 0
                                                       AND
                                                       personid = (SELECT id
                                                                   FROM   person
                                                                   WHERE
                                                       id =
                                          (SELECT TOP 1
                                          personid
                                           FROM
                                                       personrelationship
                                                             WHERE  id = (SELECT
                                                                    TOP 1
                                          parentid
                                           FROM
                                          personrelationship
                                                WHERE
                                          personid = (SELECT
                                          TOP
                                                     1 p.id
                                                      FROM
                                          ticketclient tc
                                          LEFT JOIN personrelationship pr
                                                 ON pr.id = tc.clientid
                                          LEFT JOIN person p
                                                 ON p.id = pr.personid
                                                      WHERE
                                          tc.ticketid = tk.id)
                                          AND isdeleted = 0))))),
                                               '-03:00')), 103) AS
       'Cliente (Organização): Data de contratação',
       (SELECT value
        FROM   personcustomfieldvalue
        WHERE  customfieldid = 23526
               AND isdeleted = 0
               AND personid = (SELECT id
                               FROM   person
                               WHERE  id = (SELECT TOP 1 personid
                                            FROM   personrelationship
                                            WHERE  id = (SELECT TOP 1 parentid
                                                         FROM
                                                   personrelationship
                                                         WHERE
                                                   personid = (SELECT TOP
                                                              1 p.id
                                                               FROM
                                                   ticketclient tc
                                                   LEFT JOIN personrelationship
                                                             pr
                                                          ON pr.id = tc.clientid
                                                   LEFT JOIN person p
                                                          ON p.id = pr.personid
                                                               WHERE
                                                   tc.ticketid = tk.id)
                                                   AND isdeleted = 0))))     AS
       'MRR',
       (SELECT TOP 1 NAME
        FROM   ticketcustomfieldvalue tcfv WITH (nolock)
               INNER JOIN ticketcustomfielditem tcfi WITH (nolock)
                       ON tcfi.ticketcustomfieldvalueid = tcfv.id
               INNER JOIN customfielditem cfi WITH (nolock)
                       ON tcfi.customfielditemid = cfi.id
        WHERE  tcfv.customfieldid = 11111
               AND tcfv.tenantid = 2
               AND tcfv.ticketid = tk.id
               AND tcfv.isdeleted = 0)                                       AS
       'Origem Dúvida',
       (SELECT TOP 1 NAME
        FROM   ticketcustomfieldvalue tcfv WITH (nolock)
               INNER JOIN ticketcustomfielditem tcfi WITH (nolock)
                       ON tcfi.ticketcustomfieldvalueid = tcfv.id
               INNER JOIN customfielditem cfi WITH (nolock)
                       ON tcfi.customfielditemid = cfi.id
        WHERE  tcfv.customfieldid = 25107
               AND tcfv.tenantid = 2
               AND tcfv.ticketid = tk.id
               AND tcfv.isdeleted = 0)                                       AS
       'Origem Problema',
       (SELECT TOP 1 NAME
        FROM   ticketcustomfieldvalue tcfv WITH (nolock)
               INNER JOIN ticketcustomfielditem tcfi WITH (nolock)
                       ON tcfi.ticketcustomfieldvalueid = tcfv.id
               INNER JOIN customfielditem cfi WITH (nolock)
                       ON tcfi.customfielditemid = cfi.id
        WHERE  tcfv.customfieldid = 31527
               AND tcfv.tenantid = 2
               AND tcfv.ticketid = tk.id
               AND tcfv.isdeleted = 0)                                       AS
       'Origem Solicitação',
       Format(CONVERT(DATETIME, Switchoffset(CONVERT(DATETIMEOFFSET,
                                (SELECT TOP 1 slasolutiondate
                                                  FROM
                                ticketslahistory
                                                  WHERE
                                ticketid = tk.id
                                                  ORDER  BY
                                changeddate DESC)), '-03:00')),
       'dd/MM/yyyy HH:mm:ss')                                                AS
       'Vencimento em',
       Format(CONVERT(DATETIME, Switchoffset(CONVERT(DATETIMEOFFSET,
                                (SELECT TOP 1 slaresponsedate
                                                  FROM
                                ticketslahistory
                                                  WHERE
                                ticketid = tk.id
                                                  ORDER  BY
                                changeddate DESC)), '-03:00')),
       'dd/MM/yyyy HH:mm:ss')                                                AS
       'Resposta vence em',
       Format(CONVERT(DATETIME, Switchoffset(CONVERT(DATETIMEOFFSET,
                                             (SELECT
                                                    slarealresponsedate
                                                                      FROM
                                             ticket
                                                                      WHERE  id
                                             =
                                             tk.id)),
                                       '-03:00')), 'dd/MM/yyyy HH:mm:ss')    AS
       'Data da resposta',
       (SELECT CASE tk.resolvedinfirstcall
                 WHEN 1 THEN 'Sim'
                 ELSE 'Não'
               END)                                                          AS
       'Resolvido em primeiro atendimento'
FROM   ticket tk
       FULL JOIN category ct WITH (nolock)
              ON ct.id = tk.categoryid
       FULL JOIN status st WITH (nolock)
              ON st.id = tk.statusid
       FULL JOIN justification jt WITH (nolock)
              ON jt.id = tk.justificationid
       FULL JOIN person resp WITH (nolock)
              ON resp.id = tk.ownerid
       FULL JOIN chatgroup cg WITH (nolock)
              ON cg.id = tk.chatgroupid
       FULL JOIN personteam pt WITH (nolock)
              ON pt.personid = resp.id
       FULL JOIN team te WITH (nolock)
              ON te.id = tk.ownerteamid
       FULL JOIN urgency ur WITH (nolock)
              ON ur.id = tk.urgencyid
       FULL JOIN service ser WITH (nolock)
              ON ser.id = tk.serviceid
WHERE  tk.tenantid = 2
       AND tk.isdeleted = 0
       AND tk.isdraft = 0
       AND tk.type = 2
       AND ( tk.lastupdate >= ( Dateadd(day, -1, CONVERT(DATE, Getdate())) )
              OR tk.createddate >= ( Dateadd(day, -1, CONVERT(DATE, Getdate()))
                                   ) )
       AND te.id IN ( 18703, 2961, 18330, 34860 )
GROUP  BY tk.number,
          tk.serviceid,
          tk.origin,
          jt.NAME,
          st.NAME,
          resp.businessname,
          te.NAME,
          tk.id,
          tk.createddate,
          tk.resolveddate,
          ct.NAME,
          ur.NAME,
          tk.resolvedinfirstcall
ORDER  BY tk.number 
