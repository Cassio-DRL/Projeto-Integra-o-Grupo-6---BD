SELECT t.ano,
       c.modalidade,
       SUM(f.qt_ing)::bigint AS ing,
       SUM(f.qt_mat)::bigint AS mat
FROM etl.fato_oferta_curso f
JOIN etl.dim_tempo t ON t.sk_tempo = f.sk_tempo
JOIN etl.dim_curso c ON c.sk_curso = f.sk_curso
GROUP BY t.ano, c.modalidade
ORDER BY t.ano, c.modalidade;