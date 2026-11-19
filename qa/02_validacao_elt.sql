
-- ============================================================
-- QA 02 - validacao do Data Warehouse ELT
-- Censo da Educacao Superior - INEP (2022 a 2024)
-- Grupo 6 - BD - CIn/UFPE
--
-- Banco: censo_superior
-- Schema: dw
--
-- Objetivos:
-- 1. conferir quantidade de registross e medidas por ano.
-- 2. verificar integridade referencial da tabela fato.
-- 3. identificar duplicatas na granularidade definida.
-- 4. conferir quantidade de registros das dimenssoes.
--
-- todas as consultas sssao somente leitura.
-- ============================================================


-- ============================================================
-- TESTE 1 - conferencia com os microdados originais
-- ============================================================

WITH referencia (
    ano,
    linhas,
    cursos,
    ingressantes,
    matriculas
) AS (
    VALUES
        (2022, 573019, 45296, 4756957, 9444116),
        (2023, 671610, 46317, 4994192, 9977217),
        (2024, 720349, 46150, 5010613, 10227266)
),
resultado AS (
    SELECT
        t.ano,
        COUNT(*) AS linhas,
        COUNT(DISTINCT c.co_curso) AS cursos,
        SUM(f.qt_ing) AS ingressantes,
        SUM(f.qt_mat) AS matriculas
    FROM dw.fato_oferta_curso f
    JOIN dw.dim_tempo t
        ON t.sk_tempo = f.sk_tempo
    JOIN dw.dim_curso c
        ON c.sk_curso = f.sk_curso
    GROUP BY t.ano
)
SELECT
    COALESCE(r.ano, a.ano) AS ano,
    r.linhas AS linhas_esperadas,
    a.linhas AS linhas_obtidas,
    r.cursos AS cursos_esperados,
    a.cursos AS cursos_obtidos,
    r.ingressantes AS ing_esperados,
    a.ingressantes AS ing_obtidos,
    r.matriculas AS mat_esperadas,
    a.matriculas AS mat_obtidas,
    CASE
        WHEN r.ano IS NOT NULL
         AND a.ano IS NOT NULL
         AND r.linhas = a.linhas
         AND r.cursos = a.cursos
         AND r.ingressantes = a.ingressantes
         AND r.matriculas = a.matriculas
        THEN 'APROVADO'
        ELSE 'REPROVADO'
    END AS status
FROM referencia r
FULL OUTER JOIN resultado a
    ON r.ano = a.ano
ORDER BY ano;


-- ============================================================
-- TESTE 2 - integridade referencial
-- cada chave estrangeira da fato deve apontar para
-- um registro existente na dimenssao correspondente.
--
-- esperado: zero violacoes em todas as dimensoes.
-- ============================================================

SELECT
    COUNT(*) AS total_fato,
    COUNT(*) FILTER (
        WHERE t.sk_tempo IS NULL
    ) AS erros_tempo,
    COUNT(*) FILTER (
        WHERE c.sk_curso IS NULL
    ) AS erros_curso,
    COUNT(*) FILTER (
        WHERE i.sk_ies IS NULL
    ) AS erros_ies,
    COUNT(*) FILTER (
        WHERE a.sk_area_cine IS NULL
    ) AS erros_area_cine,
    COUNT(*) FILTER (
        WHERE l.sk_localidade IS NULL
    ) AS erros_localidade,
    COUNT(*) FILTER (
        WHERE d.sk_dimensao IS NULL
    ) AS erros_dimensao
FROM dw.fato_oferta_curso f
LEFT JOIN dw.dim_tempo t
    ON t.sk_tempo = f.sk_tempo
LEFT JOIN dw.dim_curso c
    ON c.sk_curso = f.sk_curso
LEFT JOIN dw.dim_ies i
    ON i.sk_ies = f.sk_ies
LEFT JOIN dw.dim_area_cine a
    ON a.sk_area_cine = f.sk_area_cine
LEFT JOIN dw.dim_localidade l
    ON l.sk_localidade = f.sk_localidade
LEFT JOIN dw.dim_dimensao d
    ON d.sk_dimensao = f.sk_dimensao;


-- ============================================================
-- TESTE 3 - unicidade da granularidade da tabela fato
--
-- chave natural:
-- ano + curso + municipio de oferta + tipo de oferta
--
-- eesperado: zero grupos duplicados.
-- ============================================================

WITH grupos AS (
    SELECT
        t.ano,
        c.co_curso,
        l.co_municipio,
        d.co_dimensao,
        COUNT(*) AS ocorrencias
    FROM dw.fato_oferta_curso f
    JOIN dw.dim_tempo t
        ON t.sk_tempo = f.sk_tempo
    JOIN dw.dim_curso c
        ON c.sk_curso = f.sk_curso
    JOIN dw.dim_localidade l
        ON l.sk_localidade = f.sk_localidade
    JOIN dw.dim_dimensao d
        ON d.sk_dimensao = f.sk_dimensao
    GROUP BY
        t.ano,
        c.co_curso,
        l.co_municipio,
        d.co_dimensao
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS grupos_duplicados,
    COALESCE(SUM(ocorrencias - 1), 0)
        AS linhas_excedentes,
    CASE
        WHEN COUNT(*) = 0 THEN 'APROVADO'
        ELSE 'REPROVADO'
    END AS status
FROM grupos;


-- ============================================================
-- TESTE 4 - cardinalidade das tabelas do Data Warehouse
-- ============================================================

WITH referencia (tabela, esperado) AS (
    VALUES
        ('fato_oferta_curso', 1964978),
        ('dim_tempo', 3),
        ('dim_dimensao', 4),
        ('dim_curso', 137763),
        ('dim_ies', 7736),
        ('dim_area_cine', 372),
        ('dim_localidade', 3681)
),
resultado AS (
    SELECT 'fato_oferta_curso' AS tabela,
           COUNT(*) AS obtido
    FROM dw.fato_oferta_curso

    UNION ALL
    SELECT 'dim_tempo', COUNT(*)
    FROM dw.dim_tempo

    UNION ALL
    SELECT 'dim_dimensao', COUNT(*)
    FROM dw.dim_dimensao

    UNION ALL
    SELECT 'dim_curso', COUNT(*)
    FROM dw.dim_curso

    UNION ALL
    SELECT 'dim_ies', COUNT(*)
    FROM dw.dim_ies

    UNION ALL
    SELECT 'dim_area_cine', COUNT(*)
    FROM dw.dim_area_cine

    UNION ALL
    SELECT 'dim_localidade', COUNT(*)
    FROM dw.dim_localidade
)
SELECT
    r.tabela,
    r.esperado,
    a.obtido,
    CASE
        WHEN r.esperado = a.obtido THEN 'APROVADO'
        ELSE 'REPROVADO'
    END AS status
FROM referencia r
JOIN resultado a
    ON a.tabela = r.tabela
ORDER BY r.tabela;


