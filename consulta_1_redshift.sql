-- Trabalho com metas por vendedor e MTD, utilizando sintaxe do Redshift

with dates AS (
        SELECT
            date AS data
        FROM
            public.dim_date
        WHERE
            date <= CURRENT_DATE + 365
            AND date >= '2022-08-01'
    ),dias_uteis AS (
            SELECT
                dates.data,
                CASE
                WHEN date_part('dayofweek', dates.data) = 6
                OR date_part('dayofweek', dates.data) = 0 THEN 0
                ELSE 1 END AS dia_util,
                feriados.data AS feriado
            FROM
                dates
                LEFT JOIN dev.public.dim_date_feriados AS feriados ON feriados.data = dates.data
            WHERE
                feriados.data IS NULL
        )
   --select * from dias_uteis
   ,metas AS (
        SELECT
            month::datetime AS mes,
            "inicio da semana" AS inicio_da_semana,
            "fim da semana" AS fim_da_semana,
            REPLACE(REPLACE(REPLACE("meta nmrr",'R$ ',''),'.',''),',','.') AS meta_mrr,
            vendedor AS vendedor,
            "meta contas" AS meta_contas
        FROM
            dev.public.metas_de_vendas
    ),nmrr_por_vendedor AS (
        SELECT
            DATE_TRUNC('month',deal.won) AS won_month,
            DATE_TRUNC('day',deal.won)::date AS won_date,
            SUM(chartmogul_activities.movement_mrr)::decimal(10,2) AS soma_valor_do_ganho,
            COUNT(*) AS qnt_de_ganhos,
            deal.owner_name AS vendedor,
            (
                DATE_PART(WEEK, deal.won) - DATE_PART(week, DATE_TRUNC('month', deal.won):: date) + 1
            ) AS n_semana_mes,
            DATE_TRUNC('month', deal.won) AS mes
        FROM
            dev.movi_raw.chartmogul_activities AS chartmogul_activities
            LEFT JOIN dev.movi_staging.customer_chartmogul AS customer_chartmogul ON customer_chartmogul.id_customer_chartmogul = chartmogul_activities.id_customer_chartmogul
            LEFT JOIN dev.movi_staging.deal AS deal ON deal.id = customer_chartmogul.deal_id = deal.id
        WHERE
            type IN ('new_biz')
            AND deal.status IN ('won')
            AND DATE_TRUNC('month', deal.won) >= '2022-08-01'
        GROUP BY
            1,2,5,6,7
    ),consolidated AS (
--    selecT * from nmrr_por_vendedor;
    SELECT metas.*
         , ISNULL(
            (SELECT sum(qnt_de_ganhos)
             FROM nmrr_por_vendedor
             WHERE won_date >= metas.inicio_da_semana
               AND won_date <= fim_da_semana
               AND vendedor = metas.vendedor)
        , 0)                                        AS new_accounts_no_periodo
         , ISNULL(
            (SELECT sum(soma_valor_do_ganho)
             FROM nmrr_por_vendedor
             WHERE won_date >= metas.inicio_da_semana
               AND won_date <= fim_da_semana
               AND vendedor = metas.vendedor)
        , 0)                                        AS nmrr_no_periodo
        ,(
             SELECT
                SUM(dia_util)
            FROM
                dias_uteis
            WHERE
                data >= metas.inicio_da_semana
                AND data <= fim_da_semana
        ) AS  dias_uteis_no_periodo_reais
         , CASE
               WHEN CURRENT_DATE >= inicio_da_semana AND CURRENT_DATE <= fim_da_semana
                   THEN
                   ( -- Semana atual, dias úteis até agora
                       SELECT SUM(dia_util)
                       FROM dias_uteis
                       WHERE data >= inicio_da_semana
                         AND data <= CURRENT_DATE)
               ELSE ( -- dias úteis normais
                   SELECT SUM(dia_util)
                   FROM dias_uteis
                   WHERE data >= metas.inicio_da_semana
                     AND data <= fim_da_semana) END AS dias_uteis_no_periodo
         , CASE
               WHEN CURRENT_DATE >= inicio_da_semana AND CURRENT_DATE <= fim_da_semana
                   AND (DATE_TRUNC('month',inicio_da_semana::date)::date = inicio_da_semana AND  LAST_DAY(fim_da_semana::date)::date = fim_da_semana) = False -- Não é meta
                   THEN True
               ELSE False END                       AS semana_atual
         , CASE DATE_TRUNC('month',inicio_da_semana::date)::date = inicio_da_semana AND  LAST_DAY(fim_da_semana::date)::date = fim_da_semana
               WHEN True THEN True
               ELSE False
        END                                         AS meta
    FROM metas AS metas),
    consolidated_mtd AS (
SELECT
    *,
    --(consolidated.meta_mrr::decimal(10,2)/consolidated.dias_uteis_no_periodo_reais::decimal(10,2)) AS "meta div por dias uteis",
    (consolidated.meta_mrr::decimal(10,2)/consolidated.dias_uteis_no_periodo_reais::decimal(10,2)) * consolidated.dias_uteis_no_periodo::decimal(10,2) AS venda_esperada,
    consolidated.nmrr_no_periodo AS venda_realizada,
    consolidated.nmrr_no_periodo/((consolidated.meta_mrr::decimal(10,2)/consolidated.dias_uteis_no_periodo_reais::decimal(10,2)) * consolidated.dias_uteis_no_periodo::decimal(10,2)) AS MTD
FROM consolidated AS consolidated
ORDER BY inicio_da_semana,meta_contas)
SELECT
    mes,
    inicio_da_semana,
    fim_da_semana,
    meta_mrr,
    vendedor,
    meta_contas,
    nmrr_no_periodo,
    dias_uteis_no_periodo_reais,
    dias_uteis_no_periodo,
    semana_atual,
    meta,
    venda_esperada,
    venda_realizada,
    CASE
        WHEN semana_atual = True OR meta = True THEN MTD
        ELSE 1
    END MTD
FROM
    consolidated_mtd
WHERE meta = True
    OR semana_atual = True
    OR inicio_da_semana <= CURRENT_DATE
    OR fim_da_semana <= CURRENT_DATE;
