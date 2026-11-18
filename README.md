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
│   └── relatórios/
│       ├── etl.md
│       └── perfilamento.md
├── notebooks/
│   ├── 00_exploracao.ipynb
│   ├── 01_ETL.ipynb
│   └── 03_analises.ipynb
├── .gitignore
├── LICENSE
├── README.md
└── requirements.txt
```

A estrutura acima corresponde à branch `main` consultada durante a documentação. O notebook ELT encontra-se na branch de desenvolvimento `ELT` e deve ser integrado posteriormente.

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

## 8. Pipeline ELT

O segundo pipeline utiliza a abordagem ELT, na qual os dados são carregados inicialmente em tabelas brutas e posteriormente transformados dentro do PostgreSQL.

A implementação em desenvolvimento encontra-se na branch `ELT`, no notebook:

`notebooks/ELT/ELT_Censo_Educacao_Superior_Windows.ipynb`

O fluxo utiliza os schemas:

- `raw`: armazenamento inicial dos dados;
- `ref`: tabelas auxiliares de referência e decodificação;
- `stg`: padronização e transformação intermediária;
- `dw`: dimensões e tabela fato resultantes.

Na versão consultada, esse notebook utiliza o banco PostgreSQL `censo`, diferentemente do ETL, que utiliza `censo_superior`.

Antes da comparação automática entre os pipelines, é necessário alinhar a configuração de conexão e as regras de transformação.

O ELT também recria schemas durante a execução, portanto deve ser executado em ambiente de teste apropriado.

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

## 10. Conferências e qualidade dos dados

A qualidade da integração é avaliada por meio de verificações como:

- Preservação da quantidade de registros de origem;
- Comparação dos totais por ano;
- Verificação de cursos distintos;
- Conferência das somas de ingressantes e matrículas;
- Unicidade das chaves naturais;
- Integridade referencial entre fato e dimensões;
- Consistência das regras de transformação;
- Comparação dos resultados produzidos por ETL e ELT.

### Valores de referência

| Ano | Linhas | Ingressantes | Matrículas |
|---|---:|---:|---:|
| 2022 | 573.019 | 4.756.957 | 9.444.116 |
| 2023 | 671.610 | 4.994.192 | 9.977.217 |
| 2024 | 720.349 | 5.010.613 | 10.227.266 |

Esses valores foram obtidos no perfilamento dos microdados e servem como referência para as conferências.

A equivalência completa entre ETL e ELT exige também comparar os registros e atributos resultantes, e não apenas as contagens e somas agregadas.

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
