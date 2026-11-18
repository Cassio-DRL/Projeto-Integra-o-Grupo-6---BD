SELECT t.ano,
       i.rede,
       SUM(f.qt_mat)::bigint AS mat,
       ROUND(100.0 * SUM(f.qt_mat) / SUM(SUM(f.qt_mat)) OVER (PARTITION BY t.ano), 2) AS pct_mat,
       SUM(f.qt_ing)::bigint AS ing,
       SUM(f.qt_ing_fies)::bigint AS ing_fies,
       (SUM(f.qt_ing_prounii) + SUM(f.qt_ing_prounip))::bigint AS ing_prouni,
       ROUND(100.0 * SUM(f.qt_ing_fies) / NULLIF(SUM(f.qt_ing), 0), 2) AS pct_fies,
       ROUND(100.0 * (SUM(f.qt_ing_prounii) + SUM(f.qt_ing_prounip))
             / NULLIF(SUM(f.qt_ing), 0), 2) AS pct_prouni,
       ROUND(100.0 * (SUM(f.qt_ing_fies) + SUM(f.qt_ing_prounii) + SUM(f.qt_ing_prounip))
             / NULLIF(SUM(f.qt_ing), 0), 2) AS pct_fies_ou_prouni
FROM etl.fato_oferta_curso f
JOIN etl.dim_tempo t ON t.sk_tempo = f.sk_tempo
JOIN etl.dim_ies   i ON i.sk_ies   = f.sk_ies
GROUP BY t.ano, i.rede
ORDER BY t.ano, i.rede;