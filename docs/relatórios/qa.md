# Relatório de controle de qualidade (QA)

**Projeto de Integração — Grupo 6**

**Fonte:** Censo da Educação Superior, INEP, 2022–2024  
**Banco:** PostgreSQL 18.3  
**Base:** `censo_superior`  
**Schema validado:** `etl`

## 1. Objetivo

Verificar a consistência dos dados integrados pelo pipeline ETL, considerando a preservação dos registros originais, a integridade referencial, a unicidade da granularidade da tabela fato e as cardinalidades do esquema estrela.

Os testes foram implementados em `qa/01_validacao_etl.sql` e executados diretamente no PostgreSQL.

## 2. Resultados

### 2.1. Conferência dos totais anuais

| Ano | Registros | Cursos distintos | Ingressantes | Matrículas | Resultado |
|---|---:|---:|---:|---:|---|
| 2022 | 573.019 | 45.296 | 4.756.957 | 9.444.116 | Aprovado |
| 2023 | 671.610 | 46.317 | 4.994.192 | 9.977.217 | Aprovado |
| 2024 | 720.349 | 46.150 | 5.010.613 | 10.227.266 | Aprovado |

Os valores obtidos coincidem integralmente com as referências documentadas no perfilamento dos microdados.

### 2.2. Integridade referencial

Foram examinadas as seis relações entre a tabela fato e suas dimensões por meio de operações `LEFT JOIN`.

**Resultado:** zero referências inválidas em todas as dimensões, considerando 1.964.978 registros da tabela fato.

### 2.3. Unicidade da granularidade

Foi verificada a combinação formada por ano, curso, município de oferta e tipo de oferta.

**Resultado:** zero grupos duplicados e zero linhas excedentes.

### 2.4. Cardinalidade das tabelas

| Tabela | Registros encontrados | Resultado |
|---|---:|---|
| `fato_oferta_curso` | 1.964.978 | Aprovado |
| `dim_tempo` | 3 | Aprovado |
| `dim_dimensao` | 4 | Aprovado |
| `dim_curso` | 137.763 | Aprovado |
| `dim_ies` | 7.736 | Aprovado |
| `dim_area_cine` | 372 | Aprovado |
| `dim_localidade` | 3.681 | Aprovado |

## 3. Conclusão parcial

Os quatro testes executados foram aprovados.

Os resultados demonstram que o Data Warehouse produzido pelo ETL preserva os totais de referência, não apresenta violações de integridade referencial detectadas e respeita a unicidade da granularidade definida para a tabela fato.

A aprovação não equivale a uma auditoria completa de todos os atributos e transformações. A comparação com o resultado ELT será documentada separadamente.

## 4. Evidências

- Script: `qa/01_validacao_etl.sql`
- Captura de execução: `docs/prints/qa/01_validacao_etl.png`
- Saída textual: `docs/prints/qa/01_validacao_etl.txt`