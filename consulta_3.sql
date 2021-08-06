/*

-- Consulta usada como base para montar a consulta final

SELECT ', Coalesce((select top 1 Coalesce(cv.Value, i.Name) as valor '
       + 'from PersonCustomFieldValue cv '
       +
'left join PersonCustomFieldItem ci on ci.PersonCustomFieldValueId = cv.Id '
       +
'left join CustomFieldItem i on i.id = ci.CustomFieldItemId and i.isDeleted = 0 '
+ 'where cv.IsDeleted = 0 and cv.PersonId = p.Id and cv.CustomFieldId = '
+ Cast(Max(id) AS VARCHAR)
+ ' order by cv.Id desc), '''') as ''' + NAME
+ ''''
FROM   customfield
WHERE  tenantid = 00000
       AND [for] = 2
       AND isdeleted = 0
       AND isactive = 1
GROUP  BY NAME 

*/


SELECT CASE p.persontype
         WHEN 1 THEN 'Pessoa'
         WHEN 2 THEN 'Empresa'
         ELSE 'Departamento'
       END                                  AS Type,
       CASE p.profiletype
         WHEN 1 THEN 'Agente'
         WHEN 2 THEN 'Cliente'
         ELSE 'Agente|Cliente'
       END                                  AS Perfil,
       p.businessname                       AS 'NomeFantasia',
       p.username                           AS 'Usuário',
       p.cpfcnpj                            AS 'CPF / CNPJ',
       a.NAME                               AS 'Perfil de Acesso',
       c.NAME                               AS 'Classificação',
       r.NAME                               AS 'Cargo',
       COALESCE((SELECT TOP 1 COALESCE(cv.value, i.NAME) AS valor
                 FROM   personcustomfieldvalue cv
                        LEFT JOIN personcustomfielditem ci
                               ON ci.personcustomfieldvalueid = cv.id
                        LEFT JOIN customfielditem i
                               ON i.id = ci.customfielditemid
                                  AND i.isdeleted = 0
                 WHERE  cv.isdeleted = 0
                        AND cv.personid = p.id
                        AND cv.customfieldid = 24681
                 ORDER  BY cv.id DESC), '') AS 'Campo 1',
       COALESCE((SELECT TOP 1 COALESCE(cv.value, i.NAME) AS valor
                 FROM   personcustomfieldvalue cv
                        LEFT JOIN personcustomfielditem ci
                               ON ci.personcustomfieldvalueid = cv.id
                        LEFT JOIN customfielditem i
                               ON i.id = ci.customfielditemid
                                  AND i.isdeleted = 0
                 WHERE  cv.isdeleted = 0
                        AND cv.personid = p.id
                        AND cv.customfieldid = 23796
                 ORDER  BY cv.id DESC), '') AS 'Campo 2',
       COALESCE((SELECT TOP 1 COALESCE(cv.value, i.NAME) AS valor
                 FROM   personcustomfieldvalue cv
                        LEFT JOIN personcustomfielditem ci
                               ON ci.personcustomfieldvalueid = cv.id
                        LEFT JOIN customfielditem i
                               ON i.id = ci.customfielditemid
                                  AND i.isdeleted = 0
                 WHERE  cv.isdeleted = 0
                        AND cv.personid = p.id
                        AND cv.customfieldid = 23620
                 ORDER  BY cv.id DESC), '') AS 'Campo 3',
       COALESCE((SELECT TOP 1 COALESCE(cv.value, i.NAME) AS valor
                 FROM   personcustomfieldvalue cv
                        LEFT JOIN personcustomfielditem ci
                               ON ci.personcustomfieldvalueid = cv.id
                        LEFT JOIN customfielditem i
                               ON i.id = ci.customfielditemid
                                  AND i.isdeleted = 0
                 WHERE  cv.isdeleted = 0
                        AND cv.personid = p.id
                        AND cv.customfieldid = 23612
                 ORDER  BY cv.id DESC), '') AS 'Campo 4'
FROM   person p
       INNER JOIN accessprofile a
               ON a.id = P.accessprofileid
       LEFT JOIN personclassification c
              ON c.id = p.personclassificationid
       LEFT JOIN personrole r
              ON r.id = p.personroleid
WHERE  p.tenantid = 00000
       AND p.isdeleted = 0
       AND p.isactive = 1
ORDER  BY p.businessname 
