SELECT t.ano,
       a.area_geral,
       SUM(f.qt_ing)::bigint AS ing,
       (SUM(f.qt_ing_preta) + SUM(f.qt_ing_parda) + SUM(f.qt_ing_indigena))::bigint AS ing_ppi,
       ROUND(100.0 * (SUM(f.qt_ing_preta) + SUM(f.qt_ing_parda) + SUM(f.qt_ing_indigena))
             / NULLIF(SUM(f.qt_ing), 0), 2) AS pct_ppi,
       SUM(f.qt_ing_reserva_vaga)::bigint AS ing_reserva_vaga,
       ROUND(100.0 * SUM(f.qt_ing_reserva_vaga) / NULLIF(SUM(f.qt_ing), 0), 2) AS pct_reserva_vaga,
       SUM(f.qt_ing_reserva_etnica)::bigint AS ing_reserva_etnica,
       ROUND(100.0 * SUM(f.qt_ing_reserva_etnica) / NULLIF(SUM(f.qt_ing), 0), 2) AS pct_reserva_etnica
FROM etl.fato_oferta_curso f
JOIN etl.dim_tempo     t ON t.sk_tempo = f.sk_tempo
JOIN etl.dim_area_cine a ON a.sk_area_cine = f.sk_area_cine
GROUP BY t.ano, a.area_geral
ORDER BY a.area_geral, t.ano;