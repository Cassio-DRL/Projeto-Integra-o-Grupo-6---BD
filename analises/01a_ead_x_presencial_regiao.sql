SELECT t.ano,
       l.regiao,
       SUM(f.qt_ing)::bigint AS ing_total,
       (SUM(f.qt_ing) FILTER (WHERE c.modalidade = 'EAD'))::bigint AS ing_ead,
       ROUND(100.0 * SUM(f.qt_ing) FILTER (WHERE c.modalidade = 'EAD')
             / NULLIF(SUM(f.qt_ing), 0), 2) AS pct_ing_ead,
       SUM(f.qt_mat)::bigint AS mat_total,
       (SUM(f.qt_mat) FILTER (WHERE c.modalidade = 'EAD'))::bigint AS mat_ead,
       ROUND(100.0 * SUM(f.qt_mat) FILTER (WHERE c.modalidade = 'EAD')
             / NULLIF(SUM(f.qt_mat), 0), 2) AS pct_mat_ead
FROM etl.fato_oferta_curso f
JOIN etl.dim_tempo      t ON t.sk_tempo = f.sk_tempo
JOIN etl.dim_curso      c ON c.sk_curso = f.sk_curso
JOIN etl.dim_localidade l ON l.sk_localidade = f.sk_localidade
WHERE l.co_municipio > 0
GROUP BY t.ano, l.regiao
ORDER BY t.ano, l.regiao;