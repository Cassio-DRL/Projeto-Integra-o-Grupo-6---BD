# Relatório de Controle de Qualidade (QA)

**Projeto de Integração de Dados — Grupo 6**

**Fonte:** Censo da Educação Superior, INEP, 2022–2024  
**Banco:** PostgreSQL 18.3  
**Base:** `censo_superior`  
**Schemas validados:** `etl` (ETL) e `dw` (ELT)  
**Ambiente:** Python 3.13.14, pandas 3.1.1, SQLAlchemy 2.1.9 e Visual Studio Code

## 1. Objetivo

O processo de controle de qualidade (Quality Assurance — QA) teve como objetivo verificar a consistência, integridade e equivalência dos dados produzidos pelos pipelines ETL (*Extract, Transform, Load*) e ELT (*Extract, Load, Transform*).

Os pipelines integram os microdados do Censo da Educação Superior de 2022, 2023 e 2024, disponibilizados pelo INEP, e produzem um Data Warehouse em esquema estrela no PostgreSQL.

A validação foi estruturada em três frentes complementares:

1. **Validação independente do ETL:** execução de quatro consultas SQL sobre o schema `etl`, verificando totais anuais, integridade referencial, unicidade e cardinalidades.
2. **Validação independente do ELT:** aplicação dos mesmos quatro critérios ao schema `dw`, além das verificações próprias do notebook ELT.
3. **Comparação ETL × ELT:** comparação dos registros das sete tabelas produzidas pelos pipelines, utilizando `EXCEPT ALL` em ambos os sentidos.

Essa abordagem permitiu avaliar cada pipeline individualmente e, posteriormente, verificar se ambos produziram os mesmos resultados.

## 2. Ambiente de execução e organização

Os pipelines foram executados localmente, utilizando o PostgreSQL 18.3 e os microdados originais dos três anos.

| Componente | Configuração |
|---|---|
| Linguagem | Python 3.13.14 |
| Biblioteca de processamento | pandas 3.1.1 |
| Conexão com PostgreSQL | SQLAlchemy e psycopg2 |
| SGBD | PostgreSQL 18.3 |
| Banco de dados | `censo_superior` |
| Resultado ETL | Schema `etl` |
| Resultado ELT | Schema `dw` |
| Camadas intermediárias ELT | `raw`, `ref`, `stg` |
| Ambiente de desenvolvimento | VS Code e Jupyter Notebook |

Os notebooks utilizados foram:

- [Notebook ETL](../../notebooks/01_ETL.ipynb)
- [Notebook ELT](../../notebooks/02_ELT.ipynb)

Os testes independentes foram implementados em:

- [QA do ETL](../../qa/01_validacao_etl.sql)
- [QA do ELT](../../qa/02_validacao_elt.sql)

## 3. Metodologia de validação

Os mesmos quatro critérios foram aplicados aos Data Warehouses gerados pelos dois pipelines.

| Teste | Objetivo | Método |
|---|---|---|
| Totais anuais | Verificar preservação dos indicadores originais | CTEs, agregações e comparação com valores de referência |
| Integridade referencial | Identificar referências sem correspondência nas dimensões | `LEFT JOIN` e contagem de referências inválidas |
| Unicidade da fato | Verificar ausência de duplicatas na granularidade definida | `GROUP BY` e `HAVING COUNT(*) > 1` |
| Cardinalidade | Conferir o número de registros de cada tabela | `COUNT(*)` e comparação com valores esperados |

Os valores de referência foram obtidos no perfilamento dos microdados e estão documentados em [perfilamento.md](perfilamento.md).

Após as verificações independentes, as sete tabelas finais foram comparadas diretamente, verificando a existência de registros exclusivos de cada pipeline.

## 4. Validação independente do ETL

### 4.1. Leitura e transformação dos microdados

O pipeline ETL foi executado por meio do notebook `01_ETL.ipynb`, utilizando pandas para leitura, harmonização, tratamento e transformação dos dados antes da carga no PostgreSQL.

Os arquivos foram lidos com separador `;` e codificação `latin1`, conforme as características dos CSVs oficiais.

A leitura apresentou:

| Ano | Linhas de cursos | Linhas de IES |
|---|---:|---:|
| 2022 | 573.019 | 2.595 |
| 2023 | 671.610 | 2.580 |
| 2024 | 720.349 | 2.561 |
| **Total** | **1.964.978** | **7.736** |

Durante a execução, foram observadas transformações importantes para a consistência da integração:

- Tratamento de municípios ausentes com membros especiais da dimensão de localidade;
- Derivação da rede pública ou privada a partir da categoria administrativa;
- Compatibilização das colunas de reserva étnica entre os anos;
- Padronização e decodificação de atributos categóricos;
- Construção das dimensões com versionamento anual de cursos e instituições;
- Preservação da granularidade definida para a tabela fato.

O tratamento das localidades classificou 14 registros excepcionais de EAD por polo sem município identificado como "Não informado": um em 2022, quatro em 2023 e nove em 2024.

A verificação da rede administrativa comparou 5.141 registros de IES de 2023 e 2024, sem identificar divergências.

A carga final foi realizada no schema `etl`.

### 4.2. Teste 1 — Conferência dos totais anuais

O teste compara os resultados armazenados no Data Warehouse com as referências estabelecidas durante o perfilamento.

| Ano | Linhas | Cursos distintos | Ingressantes | Matrículas | Status |
|---|---:|---:|---:|---:|---|
| 2022 | 573.019 | 45.296 | 4.756.957 | 9.444.116 | APROVADO |
| 2023 | 671.610 | 46.317 | 4.994.192 | 9.977.217 | APROVADO |
| 2024 | 720.349 | 46.150 | 5.010.613 | 10.227.266 | APROVADO |

Todos os valores obtidos coincidiram com os valores esperados.

**Resultado: APROVADO.**

### 4.3. Teste 2 — Integridade referencial

Foram verificadas as seis relações entre `fato_oferta_curso` e suas dimensões.

| Dimensão | Referências inválidas |
|---|---:|
| `dim_tempo` | 0 |
| `dim_curso` | 0 |
| `dim_ies` | 0 |
| `dim_area_cine` | 0 |
| `dim_localidade` | 0 |
| `dim_dimensao` | 0 |

Foram examinados 1.964.978 registros da tabela fato.

**Resultado: APROVADO — nenhuma referência inválida detectada.**

### 4.4. Teste 3 — Unicidade da granularidade

A granularidade definida no projeto corresponde à combinação:

`ano + curso + município de oferta + TP_DIMENSAO`

A consulta agrupou os registros por essa combinação, procurando ocorrências repetidas.

| Indicador | Resultado |
|---|---:|
| Grupos duplicados | 0 |
| Linhas excedentes | 0 |

**Resultado: APROVADO — nenhuma duplicata detectada.**

### 4.5. Teste 4 — Cardinalidade das tabelas

| Tabela | Registros esperados | Registros obtidos | Status |
|---|---:|---:|---|
| `dim_tempo` | 3 | 3 | APROVADO |
| `dim_dimensao` | 4 | 4 | APROVADO |
| `dim_curso` | 137.763 | 137.763 | APROVADO |
| `dim_ies` | 7.736 | 7.736 | APROVADO |
| `dim_area_cine` | 372 | 372 | APROVADO |
| `dim_localidade` | 3.681 | 3.681 | APROVADO |
| `fato_oferta_curso` | 1.964.978 | 1.964.978 | APROVADO |

**Resultado: APROVADO — sete tabelas com as cardinalidades esperadas.**

### 4.6. Síntese da validação ETL

Os quatro testes independentes foram aprovados.

O Data Warehouse produzido pelo ETL preservou os totais de referência, apresentou integridade referencial nas relações verificadas e respeitou a granularidade e as cardinalidades definidas.

As evidências encontram-se em:

- [Captura da validação ETL](../prints/qa/01_validacao_etl.png)
- [Saída textual da validação ETL](../prints/qa/01_validacao_etl.txt)

## 5. Validação independente do ELT

### 5.1. Execução e organização

O pipeline ELT foi executado por meio do notebook `02_ELT.ipynb`.

Diferentemente do ETL, os dados foram inicialmente carregados em tabelas brutas no PostgreSQL, sendo posteriormente transformados com SQL.

O processo utiliza quatro schemas:

| Schema | Função |
|---|---|
| `raw` | Armazenamento dos dados originais |
| `ref` | Dicionários e tabelas de referência |
| `stg` | Padronização e transformação intermediária |
| `dw` | Data Warehouse final |

O notebook incorpora verificações relacionadas à carga bruta, às transformações, à consistência dos códigos, à classificação institucional, às localidades, às chaves naturais e aos totais finais.

Além dessas verificações internas, foi desenvolvido um script de QA independente, permitindo aplicar ao ELT os mesmos critérios utilizados na validação do ETL.

### 5.2. Teste 1 — Conferência dos totais anuais

| Ano | Linhas | Cursos distintos | Ingressantes | Matrículas | Status |
|---|---:|---:|---:|---:|---|
| 2022 | 573.019 | 45.296 | 4.756.957 | 9.444.116 | APROVADO |
| 2023 | 671.610 | 46.317 | 4.994.192 | 9.977.217 | APROVADO |
| 2024 | 720.349 | 46.150 | 5.010.613 | 10.227.266 | APROVADO |

Os totais obtidos coincidiram integralmente com as referências.

**Resultado: APROVADO.**

### 5.3. Teste 2 — Integridade referencial

Foram verificadas as chaves estrangeiras dos 1.964.978 registros da tabela fato do schema `dw`.

| Dimensão | Referências inválidas |
|---|---:|
| `dim_tempo` | 0 |
| `dim_curso` | 0 |
| `dim_ies` | 0 |
| `dim_area_cine` | 0 |
| `dim_localidade` | 0 |
| `dim_dimensao` | 0 |

**Resultado: APROVADO — nenhuma referência inválida detectada.**

### 5.4. Teste 3 — Unicidade da granularidade

Foi utilizada a mesma chave natural verificada no ETL.

| Indicador | Resultado |
|---|---:|
| Grupos duplicados | 0 |
| Linhas excedentes | 0 |

**Resultado: APROVADO — nenhuma duplicata detectada.**

### 5.5. Teste 4 — Cardinalidade das tabelas

| Tabela | Registros esperados | Registros obtidos | Status |
|---|---:|---:|---|
| `dim_tempo` | 3 | 3 | APROVADO |
| `dim_dimensao` | 4 | 4 | APROVADO |
| `dim_curso` | 137.763 | 137.763 | APROVADO |
| `dim_ies` | 7.736 | 7.736 | APROVADO |
| `dim_area_cine` | 372 | 372 | APROVADO |
| `dim_localidade` | 3.681 | 3.681 | APROVADO |
| `fato_oferta_curso` | 1.964.978 | 1.964.978 | APROVADO |

**Resultado: APROVADO — sete tabelas com as cardinalidades esperadas.**

### 5.6. Síntese da validação ELT

Os quatro testes independentes do ELT foram aprovados.

As verificações confirmaram a preservação dos totais, a integridade referencial, a unicidade da tabela fato e a correspondência das cardinalidades.

Os resultados também coincidiram com aqueles obtidos no QA independente do ETL.

As evidências encontram-se em:

- [Captura da validação ELT](../prints/qa/02_validacao_elt.png)
- [Saída textual da validação ELT](../prints/qa/02_validacao_elt.txt)

## 6. Comparação direta entre ETL e ELT

### 6.1. Metodologia

Após a conclusão dos dois pipelines, foi realizada uma comparação entre as tabelas finais dos schemas `etl` e `dw`.

A verificação foi executada pelo notebook ELT, utilizando o operador SQL `EXCEPT ALL` em ambos os sentidos.

Para cada tabela, foram calculadas:

- A quantidade de registros existentes exclusivamente no ETL;
- A quantidade de registros existentes exclusivamente no ELT.

O uso de `EXCEPT ALL` permite considerar a multiplicidade dos registros, oferecendo uma comparação mais rigorosa do que a verificação isolada de contagens e somas agregadas.

A comparação direta também considerou as chaves substitutas, que foram geradas de forma correspondente nas duas implementações.

### 6.2. Resultados

| Tabela | Linhas ETL | Linhas ELT | Só no ETL | Só no ELT | Resultado |
|---|---:|---:|---:|---:|---|
| `dim_tempo` | 3 | 3 | 0 | 0 | IDÊNTICA |
| `dim_dimensao` | 4 | 4 | 0 | 0 | IDÊNTICA |
| `dim_curso` | 137.763 | 137.763 | 0 | 0 | IDÊNTICA |
| `dim_ies` | 7.736 | 7.736 | 0 | 0 | IDÊNTICA |
| `dim_area_cine` | 372 | 372 | 0 | 0 | IDÊNTICA |
| `dim_localidade` | 3.681 | 3.681 | 0 | 0 | IDÊNTICA |
| `fato_oferta_curso` | 1.964.978 | 1.964.978 | 0 | 0 | IDÊNTICA |

A execução apresentou a confirmação:

`OK — as sete tabelas são idênticas linha a linha nos dois caminhos.`

**Resultado: APROVADO — sete tabelas idênticas e nenhuma divergência detectada.**

### 6.3. Interpretação

A equivalência demonstra que os pipelines produziram os mesmos registros nas sete tabelas finais, apesar das diferenças de processamento.

No ETL, as transformações são realizadas principalmente com pandas antes da carga.

No ELT, os dados são inicialmente armazenados no PostgreSQL e transformados posteriormente por instruções SQL.

A igualdade entre os resultados fornece evidência de que ambas as implementações aplicaram consistentemente as regras de integração, harmonização e modelagem definidas pelo grupo.

Entretanto, a equivalência dos dados finais não implica igualdade de consumo de memória, armazenamento ou tempo de execução.

**Evidência:** [Comparação ETL × ELT](../prints/qa/03_comparacao_etl_elt.png).

## 7. Problemas encontrados e resolução

Durante a execução do ELT, foi identificado um problema relacionado ao armazenamento disponível no ambiente local.

### 7.1. Erro de armazenamento

A execução foi interrompida durante a construção das dimensões do schema `dw`, apresentando a mensagem:

`DiskFull: No space left on device`

O PostgreSQL não conseguiu gravar um arquivo temporário necessário à operação.

### 7.2. Investigação

Foi verificado que a unidade C: possuía aproximadamente 0,19 GB livres naquele momento.

O banco `censo_superior` ocupava cerca de 2.224 MB, distribuídos principalmente entre os schemas `raw`, `stg` e `etl`.

| Schema | Tamanho aproximado durante a investigação |
|---|---:|
| `raw` | 1.246 MB |
| `stg` | 586 MB |
| `etl` | 362 MB |
| `dw` (parcial) | 21 MB |
| `ref` | 168 KB |

Essas medidas correspondem ao estado intermediário da execução e não representam um benchmark controlado de armazenamento dos dois pipelines.

### 7.3. Resolução

Após liberar espaço em disco, a execução foi retomada sem a necessidade de repetir a carga inicial dos arquivos CSV.

As etapas restantes foram concluídas, permitindo finalizar a construção do Data Warehouse e executar a comparação entre os resultados ETL e ELT.

O problema demonstrou a importância de considerar o armazenamento das camadas intermediárias ao executar processos ELT com bases volumosas.

A falha foi operacional, relacionada ao espaço disponível no ambiente local, e não evidenciou inconsistências nas transformações do pipeline.

## 8. Comparativo técnico entre ETL e ELT

| Critério | ETL | ELT |
|---|---|---|
| Ordem de processamento | Extrair, transformar e carregar | Extrair, carregar e transformar |
| Ambiente principal de transformação | Python e pandas | PostgreSQL e SQL |
| Armazenamento dos dados brutos no banco | Não exigido pelo pipeline | Utilizado na camada `raw` |
| Transformações intermediárias | Principalmente em memória | Principalmente dentro do banco |
| Resultado final | Schema `etl` | Schema `dw` |
| QA independente | 4 testes aprovados | 4 testes aprovados |
| Comparação dos resultados | Equivalência confirmada | Equivalência confirmada |

### 8.1. Vantagens e limitações do ETL

O ETL permitiu inspecionar e transformar os dados por meio de DataFrames, realizando verificações antes de carregar o esquema estrela.

A estratégia evita manter uma cópia integral das tabelas brutas dentro do banco de destino, embora dependa de recursos de memória disponíveis ao processamento Python.

### 8.2. Vantagens e limitações do ELT

O ELT manteve as informações brutas e intermediárias em schemas específicos do PostgreSQL, permitindo a inspeção das etapas e a aplicação de transformações diretamente com SQL.

A abordagem oferece uma organização explícita entre carga, padronização e modelagem, mas exige armazenamento para as diferentes camadas.

O problema de falta de espaço ocorrido durante a execução demonstrou essa exigência no ambiente utilizado.

### 8.3. Considerações sobre desempenho

A execução permitiu observar diferenças operacionais entre os pipelines, especialmente quanto à necessidade de armazenamento intermediário.

Entretanto, não foi realizado um benchmark controlado de tempo de processamento, consumo de memória e espaço em disco.

Portanto, os resultados não permitem concluir que uma abordagem seja universalmente mais rápida ou eficiente que a outra.

A principal conclusão verificada é a equivalência dos resultados finais.

## 9. Evidências e reprodutibilidade

Todos os testes independentes foram executados diretamente no PostgreSQL e seus resultados registrados em arquivos de texto e capturas de tela.

| Evidência | Referência |
|---|---|
| Script de QA do ETL | [01_validacao_etl.sql](../../qa/01_validacao_etl.sql) |
| Script de QA do ELT | [02_validacao_elt.sql](../../qa/02_validacao_elt.sql) |
| Resultado textual ETL | [01_validacao_etl.txt](../prints/qa/01_validacao_etl.txt) |
| Resultado textual ELT | [02_validacao_elt.txt](../prints/qa/02_validacao_elt.txt) |
| Captura QA ETL | [01_validacao_etl.png](../prints/qa/01_validacao_etl.png) |
| Captura QA ELT | [02_validacao_elt.png](../prints/qa/02_validacao_elt.png) |
| Captura da comparação ETL × ELT | [03_comparacao_etl_elt.png](../prints/qa/03_comparacao_etl_elt.png) |
| Notebook ETL | [01_ETL.ipynb](../../notebooks/01_ETL.ipynb) |
| Notebook ELT | [02_ELT.ipynb](../../notebooks/02_ELT.ipynb) |
| Perfilamento e decisões de modelagem | [perfilamento.md](perfilamento.md) |

Para reproduzir os testes independentes, após a execução dos dois pipelines, utilize:

**QA do ETL:**

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d censo_superior -v ON_ERROR_STOP=1 -f "qa/01_validacao_etl.sql"
```

**QA do ELT:**

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d censo_superior -v ON_ERROR_STOP=1 -f "qa/02_validacao_elt.sql"
```

A comparação direta está implementada na seção de conferência do notebook `02_ELT.ipynb`.

## 10. Conclusão

A validação dos Data Warehouses produzidos pelos pipelines ETL e ELT foi concluída com resultados positivos.

Foram executados **oito testes independentes de QA**, distribuídos igualmente entre os dois pipelines.

Todos os testes foram aprovados, confirmando:

- Correspondência dos totais anuais com os valores de referência;
- Ausência de referências inválidas entre fato e dimensões;
- Ausência de duplicatas na granularidade estabelecida;
- Correspondência das cardinalidades das sete tabelas finais.

Adicionalmente, a comparação por meio de `EXCEPT ALL` confirmou que os sete pares de tabelas apresentam registros idênticos, sem diferenças detectadas em qualquer direção.

A execução do ELT também evidenciou um desafio operacional relacionado ao armazenamento, posteriormente superado para permitir a conclusão do processamento.

Assim, **os resultados obtidos sustentam a consistência dos dados integrados e a equivalência dos Data Warehouses ETL e ELT para as bases, configurações e execuções verificadas**.

O processo reforçou a importância de combinar verificações individuais, testes independentes e comparações diretas entre implementações distintas, garantindo maior rastreabilidade e confiabilidade aos resultados do Projeto de Integração.