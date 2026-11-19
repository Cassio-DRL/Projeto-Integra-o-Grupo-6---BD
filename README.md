# Projeto de Integração de Dados — Grupo 6

**Censo da Educação Superior (INEP) | 2022–2024**

Projeto desenvolvido para a disciplina de Banco de Dados do Centro de Informática da Universidade Federal de Pernambuco (CIn/UFPE), semestre 2026.2.

## 1. Visão geral

O projeto tem como objetivo integrar os microdados do Censo da Educação Superior dos anos de 2022, 2023 e 2024, disponibilizados pelo Instituto Nacional de Estudos e Pesquisas Educacionais Anísio Teixeira (INEP).

A integração utiliza duas abordagens de processamento de dados, ETL (*Extract, Transform, Load*) e ELT (*Extract, Load, Transform*), para construir um Data Warehouse relacional em PostgreSQL, modelado em esquema estrela (*Star Schema*).

O modelo permite realizar análises temporais, geográficas e institucionais sobre a educação superior brasileira, considerando indicadores como ingressantes, matrículas, concluintes, vagas, modalidades de ensino, financiamento estudantil e políticas de inclusão.

## 2. Tecnologias utilizadas

| Tecnologia | Finalidade |
|---|---|
| Python | Desenvolvimento e execução dos pipelines |
| pandas e NumPy | Leitura, tratamento e validação de dados |
| PostgreSQL | Armazenamento do Data Warehouse |
| SQL | Transformações, consultas e verificações |
| SQLAlchemy e psycopg2 | Conexão e operações com PostgreSQL |
| Jupyter Notebook / Google Colab | Desenvolvimento e execução dos notebooks |
| Matplotlib | Visualização dos resultados |
| Git e GitHub | Versionamento e colaboração |

O pipeline ETL realiza as transformações principalmente com pandas antes da carga. O pipeline ELT implementa as transformações com SQL no PostgreSQL, utilizando o notebook Python para coordenar a execução.

## 3. Fontes de dados

Os dados são provenientes dos [Microdados do Censo da Educação Superior — INEP](https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-da-educacao-superior).

São utilizadas três edições anuais, de 2022 a 2024.

Para cada ano, o projeto utiliza principalmente os arquivos:

- `MICRODADOS_CADASTRO_CURSOS_<ano>.CSV`: informações sobre os cursos e suas ofertas.
- `MICRODADOS_ED_SUP_IES_<ano>.CSV`: informações sobre as instituições de educação superior.

As bases utilizam separador `;` e codificação ISO-8859-1 (`latin1`).

### Volume dos dados

| Ano | Registros de cursos | Registros de IES |
|---|---:|---:|
| 2022 | 573.019 | 2.595 |
| 2023 | 671.610 | 2.580 |
| 2024 | 720.349 | 2.561 |
| **Total** | **1.964.978** | **7.736** |

Os arquivos originais não são versionados neste repositório devido ao tamanho. Para reproduzir os pipelines, é necessário obtê-los diretamente na fonte oficial.

## 4. Organização do repositório

```text

.
├── analises/
│   ├── 01a_ead_x_presencial_regiao.sql
│   ├── 01b_ead_x_presencial_brasil.sql
│   ├── 02_publica_x_privada.sql
│   └── 03_inclusao_por_area.sql
├── docs/
│   ├── figuras/
│   ├── prints/
│   │   └── qa/
│   └── relatórios/
│       ├── etl.md
│       ├── perfilamento.md
│       └── qa.md
├── notebooks/
│   ├── 00_exploracao.ipynb
│   ├── 01_ETL.ipynb
│   ├── 02_ELT.ipynb
│   └── 03_analises.ipynb
├── qa/
│   ├── 01_validacao_etl.sql
│   └── 02_validacao_elt.sql
├── .gitignore
├── LICENSE
├── README.md
└── requirements.txt

```

A estrutura acima corresponde à branch `main` consultada durante a documentação.

Os diretórios `docs/figuras/` e `docs/prints/` armazenam gráficos e evidências das etapas de execução.

## 5. Modelagem dimensional

O Data Warehouse utiliza um esquema estrela composto por uma tabela fato e seis dimensões.

**Tabela fato:** `fato_oferta_curso`

Contém indicadores quantitativos associados às ofertas de cursos, como vagas, inscritos, ingressantes, matrículas, concluintes e medidas relacionadas a financiamento e reserva de vagas.

**Dimensões:**

| Dimensão | Finalidade |
|---|---|
| `dim_tempo` | Ano de referência do censo |
| `dim_curso` | Identificação e características do curso |
| `dim_ies` | Identificação e características da instituição |
| `dim_area_cine` | Classificação da área do conhecimento |
| `dim_localidade` | Localização geográfica da oferta |
| `dim_dimensao` | Tipo e abrangência geográfica da oferta |

A granularidade da tabela fato é definida pela combinação:

`ano + curso + município de oferta + TP_DIMENSAO`

Essa combinação permite distinguir ofertas presenciais e a distância, incluindo diferentes polos e registros de abrangência nacional.

As dimensões de curso e instituição preservam versões anuais de seus atributos, permitindo analisar alterações entre 2022 e 2024.

As decisões de modelagem e as regras de transformação estão detalhadas em `docs/relatórios/perfilamento.md`.

## 6. Pré-requisitos

Para executar o projeto localmente, são necessários:

- Python compatível com as dependências do projeto;
- PostgreSQL instalado e em execução;
- Git;
- Jupyter Notebook ou VS Code com extensão Jupyter;
- Arquivos CSV dos três anos disponíveis localmente.

### 6.1. Clonar o repositório

```bash
git clone https://github.com/Cassio-DRL/Projeto-Integra-o-Grupo-6---BD.git
cd Projeto-Integra-o-Grupo-6---BD
```

### 6.2. Criar o ambiente virtual

No Windows, utilizando PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Instale as dependências:

```powershell
python -m pip install -r requirements.txt
```

No VS Code, selecione o interpretador Python pertencente ao ambiente `.venv`.

### 6.3. Preparar os microdados

Extraia os arquivos oficiais e organize os CSVs da seguinte maneira:

```text
data/
└── raw/
    ├── 2022/
    │   ├── MICRODADOS_CADASTRO_CURSOS_2022.CSV
    │   └── MICRODADOS_ED_SUP_IES_2022.CSV
    ├── 2023/
    │   ├── MICRODADOS_CADASTRO_CURSOS_2023.CSV
    │   └── MICRODADOS_ED_SUP_IES_2023.CSV
    └── 2024/
        ├── MICRODADOS_CADASTRO_CURSOS_2024.CSV
        └── MICRODADOS_ED_SUP_IES_2024.CSV
```

A pasta `data/` deve permanecer fora do versionamento Git.

## 7. Execução do pipeline ETL

O pipeline ETL está implementado no notebook `notebooks/01_ETL.ipynb`.

### Etapas

1. Leitura dos microdados de cursos e instituições.
2. Seleção e harmonização das colunas dos três anos.
3. Tratamento de valores ausentes e padronização de atributos.
4. Aplicação das regras de classificação e transformação.
5. Construção das dimensões e da tabela fato.
6. Carga dos dados no PostgreSQL.
7. Verificações de consistência e integridade.

### Configuração do PostgreSQL

O notebook utiliza os seguintes parâmetros:

```python
USUARIO = "postgres"
HOST = "localhost"
PORTA = 5432
BANCO = "censo_superior"
SCHEMA = "etl"
```

É necessário criar previamente o banco `censo_superior`, por exemplo, no pgAdmin, e garantir que o usuário configurado tenha permissão para criar schemas e tabelas.

A senha do PostgreSQL é solicitada durante a execução do notebook.

Abra o notebook no VS Code ou no Google Colab, configure a localização dos dados e execute as células na ordem apresentada.

**Atenção:** no ambiente local, o caminho relativo dos CSVs pressupõe que o diretório de execução seja `notebooks/`. Se necessário, ajuste `PASTA_DADOS` para o caminho absoluto da pasta `data/raw/`.

O notebook recria o schema `etl` durante a carga. Uma nova execução pode substituir as tabelas anteriormente existentes nesse schema.

A documentação específica está disponível em `docs/relatórios/etl.md`.

## 8. Execução do pipeline ELT

O pipeline ELT está implementado no notebook `notebooks/02_ELT.ipynb`.

Diferentemente do ETL, no qual os dados são predominantemente transformados com pandas antes da carga, o ELT realiza as transformações dentro do PostgreSQL.

### 8.1. Organização das camadas

O pipeline utiliza os seguintes schemas:

| Schema | Responsabilidade |
|---|---|
| `raw` | Recebimento dos dados brutos dos CSVs |
| `ref` | Dicionários e tabelas auxiliares |
| `stg` | Padronização, limpeza e integração intermediária |
| `dw` | Data Warehouse final em esquema estrela |

### 8.2. Configuração

O notebook utiliza o banco `censo_superior` no PostgreSQL local.

Os arquivos de origem devem estar organizados em `data/raw/<ano>/`, conforme a seção 6.3.

Para executar:

1. Abra `notebooks/02_ELT.ipynb` no VS Code ou em um ambiente Jupyter compatível.
2. Selecione o ambiente Python com as dependências instaladas.
3. Confirme os parâmetros de conexão e a localização dos CSVs.
4. Execute as células na ordem apresentada.
5. Verifique as conferências de integridade e os totais produzidos.
6. Execute a seção de comparação ETL × ELT após ambos os pipelines estarem carregados.

**Atenção:** o notebook recria os schemas `raw`, `ref`, `stg` e `dw` durante sua execução. Recomenda-se utilizar um ambiente de teste e não armazenar senhas no código versionado.

### 8.3. Resultado validado

Após a execução completa, o schema `dw` apresentou:

- 1.964.978 registros na tabela fato;
- seis dimensões;
- correspondência integral dos totais anuais com os valores de referência;
- aprovação dos quatro testes independentes de QA;
- equivalência das sete tabelas com o schema `etl`.

A comparação utilizou `EXCEPT ALL` nos dois sentidos e não encontrou registros divergentes entre as tabelas finais.

O relatório de validação completo está disponível em [Relatório de QA](docs/relatórios/qa.md).

## 9. Análises realizadas

O projeto contempla três análises principais, implementadas em SQL e executadas pelo notebook `notebooks/03_analises.ipynb`.

### Análise 1 — EAD × presencial

Investiga a evolução da participação do ensino a distância e presencial nos ingressantes e nas matrículas, com recortes temporais e regionais.

Consultas:

- `analises/01a_ead_x_presencial_regiao.sql`
- `analises/01b_ead_x_presencial_brasil.sql`

### Análise 2 — Rede pública × privada

Compara a participação das redes pública e privada nas matrículas e nos ingressantes, incluindo indicadores relacionados ao FIES e ao ProUni.

Consulta: `analises/02_publica_x_privada.sql`

### Análise 3 — Inclusão por área do conhecimento

Analisa indicadores de ingressantes pretos, pardos e indígenas, assim como registros de ingresso por reserva de vagas e reserva étnica, agrupados por área CINE.

Consulta: `analises/03_inclusao_por_area.sql`

### Execução das análises

O notebook utiliza, por padrão:

```python
BANCO = "censo_superior"
SCHEMA = "etl"
```

As consultas devem ser executadas após a carga do Data Warehouse correspondente.

Os resultados são processados com pandas e visualizados com Matplotlib. As figuras geradas são armazenadas em `docs/figuras/`.

## 10. Controle de qualidade e validação

A qualidade dos dados foi avaliada individualmente nos dois pipelines e por meio de uma comparação entre os Data Warehouses resultantes.

### 10.1. Testes independentes

Foram implementados dois scripts SQL:

- [QA do ETL](qa/01_validacao_etl.sql)
- [QA do ELT](qa/02_validacao_elt.sql)

Cada script contém quatro testes:

1. Conferência dos totais anuais;
2. Integridade referencial entre fato e dimensões;
3. Unicidade da chave natural da tabela fato;
4. Cardinalidade das tabelas do esquema estrela.

**Resultado: os oito testes independentes foram aprovados.**

### 10.2. Equivalência entre os pipelines

Os resultados finais dos schemas `etl` e `dw` foram comparados com `EXCEPT ALL`, em ambos os sentidos, para verificar a existência de registros exclusivos de cada implementação.

| Indicador | Resultado |
|---|---|
| Tabelas comparadas | 7 |
| Tabelas idênticas | 7 |
| Registros exclusivos do ETL | 0 |
| Registros exclusivos do ELT | 0 |
| Situação | APROVADO |

A equivalência foi confirmada para as bases e execuções verificadas.

### 10.3. Evidências

O [Relatório de Controle de Qualidade](docs/relatórios/qa.md) documenta os procedimentos, resultados, limitações e evidências.

As saídas textuais e capturas de tela encontram-se em `docs/prints/qa/`.

## 11. Limitações e cuidados

- Os microdados originais são arquivos volumosos e não estão incluídos no repositório.
- Algumas colunas mudaram entre 2022 e 2024, exigindo regras específicas de harmonização.
- As ofertas EAD podem aparecer em múltiplos polos. Portanto, linhas da fato não equivalem necessariamente a cursos distintos.
- Algumas ofertas EAD não possuem município identificado ou apresentam dados somente em nível nacional.
- Vagas e inscritos de EAD registrados apenas em nível Brasil não devem ser distribuídos artificialmente por município ou região.
- A medida de reserva étnica de 2024 utiliza uma aproximação para compatibilização com os anos anteriores.
- O alinhamento definitivo de determinadas regras de localidade entre ETL e ELT deve ser validado na conferência dos pipelines.

## 12. Documentação e evidências

O repositório mantém a documentação técnica e os registros de execução nas seguintes pastas:

- `docs/relatórios/`: perfilamento, decisões e relatórios técnicos;
- `docs/prints/`: evidências visuais de execução e validação;
- `docs/figuras/`: gráficos das análises;
- `notebooks/`: implementações e resultados dos pipelines.

As contribuições são registradas em commits descritivos e organizadas por meio de branches e Pull Requests, permitindo acompanhar as responsabilidades e as alterações realizadas ao longo do projeto.

## 13. Referências

- [INEP — Microdados do Censo da Educação Superior](https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-da-educacao-superior)
- [PostgreSQL — Documentação oficial](https://www.postgresql.org/docs/)
- [pandas — Documentação oficial](https://pandas.pydata.org/docs/)
- [SQLAlchemy — Documentação oficial](https://docs.sqlalchemy.org/)

---

**Universidade Federal de Pernambuco — Centro de Informática**

**Disciplina:** Banco de Dados
**Semestre:** 2026.2
**Equipe:** Grupo 6
