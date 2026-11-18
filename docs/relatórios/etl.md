# Relatório do pipeline ETL

Censo da Educação Superior (INEP) · 2022 a 2024 · Grupo 6 · Projeto de Integração

## 1. Resumo

O pipeline ETL lê os microdados de cursos e de IES de 2022, 2023 e 2024, transforma e modela tudo em memória com pandas e carrega o esquema estrela pronto no PostgreSQL, no schema `etl`. Todo o código está em [`notebooks/01_ETL.ipynb`](../../notebooks/01_ETL.ipynb). As decisões de modelagem seguem o [relatório de perfilamento](perfilamento.md), citado aqui como *perfilamento §N*.

Resultado no banco:

| Tabela | Linhas | Uma linha por |
| --- | --- | --- |
| `fato_oferta_curso` | 1.964.978 | curso × município × tipo de oferta × ano |
| `dim_tempo` | 3 | ano |
| `dim_dimensao` | 4 | tipo de oferta (`TP_DIMENSAO`) |
| `dim_curso` | 137.763 | curso e ano |
| `dim_ies` | 7.736 | IES e ano |
| `dim_area_cine` | 372 | rótulo CINE |
| `dim_localidade` | 3.681 | município, mais 3 membros especiais |

As linhas, os cursos distintos e os totais de ingressantes e matrículas conferem com a referência do perfilamento (§15) em três pontos: depois da leitura, depois da transformação e no banco.

| Ano | Linhas | Cursos distintos | Ingressantes | Matrículas |
| --- | --- | --- | --- | --- |
| 2022 | 573.019 | 45.296 | 4.756.957 | 9.444.116 |
| 2023 | 671.610 | 46.317 | 4.994.192 | 9.977.217 |
| 2024 | 720.349 | 46.150 | 5.010.613 | 10.227.266 |

## 2. Como executar

1. Copie os CSVs de cursos e de IES de cada ano para `data/raw/<ano>/` (a pasta está no `.gitignore`).
2. Crie o ambiente e instale as dependências: `python -m venv .venv` e `pip install -r requirements.txt`.
3. No PostgreSQL, crie o banco `censo_superior`.
4. Abra `notebooks/01_ETL.ipynb` no VS Code, selecione o kernel `.venv` e rode todas as células. A senha do PostgreSQL é pedida na seção 4.1.

O notebook também roda no Google Colab, com os dados no Google Drive (seção 0). Foi testado com pandas 3.1.1 (versão do `requirements.txt`) e com pandas 2.3.3. No teste, a execução completa usou menos de 2 GB de memória e levou poucos minutos; a carga da fato levou menos de 30 segundos.

## 3. Etapas e decisões

| Etapa | O que foi feito | Por quê | Referência |
| --- | --- | --- | --- |
| Extração | Leitura com `sep=";"` e `encoding="latin1"`, só das colunas necessárias, em blocos de 100 mil linhas; textos convertidos para `category` | A leitura padrão em UTF-8 falha; ler tudo de uma vez gasta memória demais | §2, §7 |
| Colunas | 24 colunas do perfilamento, vagas e inscritos, reserva étnica e nomes das dimensões; mantenedora fora | Vagas e inscritos são as únicas medidas das linhas de EAD em nível Brasil; a mantenedora é instável e não é usada | §7, §9, §13 |
| Local de oferta | Código 0 (2022) e município nulo (2023–2024) viram membros especiais definidos por `TP_DIMENSAO`; nenhuma linha é descartada | São a mesma situação em dois formatos; descartar perderia vagas e quebraria a conferência | §10 |
| Rede de ensino | Derivada da categoria administrativa nos três anos (1, 2, 3 e 7 públicas; 4 e 5 privadas), com erro se surgir outra categoria | `TP_REDE` não existe nas IES de 2022; a regra não tem exceções em 2023 e 2024 | §12 |
| Comunitária e confessional | `-1` ("Não informado") nas IES de 2022 | As colunas não existem em 2022 e não podem ser deduzidas | §4 |
| Reserva étnica | `qt_ing_reserva_etnica` = `QT_ING_RVETNICO` em 2022–2023 e `RVPPI + RVQUILO + RVPOVT` em 2024 | A coluna única deixou de existir em 2024; documentada como aproximação | §8 |
| Limpeza | Aspas removidas de `CO_CINE_ROTULO`; grau acadêmico vazio vira 0 ("Não aplicável") | O código CINE vem como `"0011A09"`; o vazio do grau significa "não aplicável" no dicionário | §5 |
| Decodificação | Cada código ganha uma descrição (`DS_...`), com erro se algum código ficar sem descrição | As listas de códigos são idênticas nos três anos | §5 |
| Granularidade | Chave da fato = ano + curso + município + `TP_DIMENSAO`, verificada como única | Sem `TP_DIMENSAO` há repetições legítimas | §11 |
| Histórico | `dim_curso` e `dim_ies` com uma linha por código e ano; antes, o notebook verifica que cada atributo tem um único valor dentro do ano | Nome, grau, IES e categoria mudam entre anos; a fato aponta para a versão do próprio ano | §13, §14 |
| CINE e localidade | Uma linha por código, com o nome mais recente | Só um rótulo CINE muda de nome, e por renomeação | §14 |
| Nomes no banco | Colunas em minúsculas | No PostgreSQL, maiúsculas exigem aspas em toda consulta | — |
| Surrogate keys | Chave sequencial `sk_...` em cada dimensão; a fato guarda só as chaves e as medidas | Independência dos códigos do INEP | — |
| Carga | Tabelas criadas pelo `to_sql` e preenchidas com `COPY`; chaves primárias e estrangeiras criadas depois | O `to_sql` padrão (vários `INSERT`) levaria muitos minutos para 2 milhões de linhas | — |

### Membros especiais da `dim_localidade`

| Código | Regra | Linhas 2022 | Linhas 2023 | Linhas 2024 |
| --- | --- | --- | --- | --- |
| -1 · Sem município (EAD nível Brasil) | `TP_DIMENSAO` = 3, sem município | 9.207 | 10.576 | 11.319 |
| -2 · Exterior | `TP_DIMENSAO` = 4 | 395 | 459 | 450 |
| -3 · Não informado | outras linhas sem município (`TP_DIMENSAO` = 2) | 1 | 4 | 9 |

> **Para validar com o Cássio:** o perfilamento define os membros "Sem município" e "Exterior", mas não as poucas linhas de `TP_DIMENSAO` = 2 sem município. Elas receberam o membro "Não informado".

### Reserva étnica

| Ano | Reserva étnica | % dos ingressantes |
| --- | --- | --- |
| 2022 | 63.925 | 1,34% |
| 2023 | 72.270 | 1,45% |
| 2024 | 83.041 | 1,66% |

Os percentuais reproduzem os do perfilamento (§8).

## 4. Conferências automáticas

O notebook para com erro (`assert`) se alguma destas condições falhar:

- a leitura de cada ano tem as linhas, os cursos distintos e os totais da referência;
- a regra de rede cobre todas as categorias e não diverge de `TP_REDE` em 2023 e 2024 (5.141 IES comparadas, 0 divergências);
- nenhuma coluna de localização fica vazia depois do tratamento;
- todo código tem descrição;
- cada curso e cada IES tem um único valor de cada atributo dentro do ano;
- a chave da fato não se repete;
- toda linha da fato encontra a sua linha em cada dimensão.

No banco, a seção 4.4 compara linhas, cursos distintos (`COUNT(DISTINCT co_curso)`), ingressantes e matrículas com a referência. As vagas por modalidade também batem com o perfilamento (§9): em 2022, 5.658.590 vagas presenciais e 17.171.895 de EAD.

## 5. Evidências (prints)

Os prints ficam em `docs/prints/etl/`, na ordem em que aparecem no notebook.

| Nº | Seção | O que capturar | Arquivo |
| --- | --- | --- | --- |
| 01 | 0 | Versões de Python, pandas e SQLAlchemy | `01_versoes.png` |
| 02 | 0 | Arquivos encontrados em `data/raw` e seus tamanhos | `02_arquivos.png` |
| 03 | 1.1 | Erro de leitura com UTF-8 | `03_erro_utf8.png` |
| 04 | 1.3 | Resumo da leitura com as colunas ausentes por ano | `04_resumo_leitura.png` |
| 05 | 1.4 | `info()` dos cursos de 2024 | `05.1_info_2024.png`, `05.2_info_2024.png` |
| 06 | 1.5 | Conferência da leitura com a referência (`confere` = True) | `06_conferencia_leitura.png` |
| 07 | — | pgAdmin com o banco `censo_superior` criado | `07_banco_criado.png` |
| 08 | 2.2 | Situação do município por ano e `TP_DIMENSAO` (ANTES) | `08_local_antes.png` |
| 09 | 2.2 | Linhas por membro especial (DEPOIS) | `09_local_depois.png` |
| 10 | 2.3 | Validação da rede (0 divergências) e rede por ano | `10_rede.png` |
| 11 | 2.4 | Reserva étnica por ano e percentual | `11_reserva_etnica.png` |
| 12 | 2.5 | `CO_CINE_ROTULO` e grau acadêmico, antes e depois | `12_limpeza.png` |
| 13 | 2.6 | Tabelas de código → descrição | `13.1_decodificacao.png`, `13.2_decodificacao.png` |
| 14 | 2.7 | Conferência da transformação | `14_conferencia_transformacao.png` |
| 15 | 3.1 | Consistência dos atributos dentro do ano | `15_consistencia.png` |
| 16 | 3.2 | Tamanho das dimensões e membros especiais da localidade | `16.1_dimensoes.png`, `16.2_dimensoes.png` |
| 17 | 3.3 | Chave única, chaves sem correspondência = 0 e primeiras linhas da fato | `17_fato.png` |
| 18 | 3.3 | Conferência da fato com a referência | `18_conferencia_fato.png` |
| 19 | 4.2 | Linhas carregadas e tempo de cada tabela | `19_carga.png` |
| 20 | 4.4 | Contagem no banco e conferência com a referência | `20_verificacao_banco.png` |
| 21 | 4.4 | Vagas, ingressantes e matrículas por ano e modalidade | `21_modalidade.png` |
| 22 | — | pgAdmin com as tabelas do schema `etl` | `22_pgadmin_schema_etl.png` |
| 23 | — | Histórico de commits e Pull Request do ETL no GitHub | `23_github.png` |

## 6. Pontos de alinhamento com o grupo

- **ELT (Pessoa 2):** para a conferência entre os dois caminhos, o ELT deve aplicar as mesmas regras da seção 3 e chegar às mesmas linhas e totais da seção 1.
- **Perfilamento (Cássio):** validar o membro "Não informado" da `dim_localidade` (seção 3).
- **Análises:** cursos sempre contados com `COUNT(DISTINCT co_curso)`. Vagas e inscritos de EAD existem só em nível Brasil e não devem ser quebrados por região (perfilamento §9).
