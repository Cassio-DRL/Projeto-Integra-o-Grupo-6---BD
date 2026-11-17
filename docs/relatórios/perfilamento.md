# Relatório de perfilamento e testes dos dados

Censo da Educação Superior (INEP) · 2022 a 2024 · Grupo 6 · Projeto de Integração

## 1. Objetivo e escopo

Este relatório consolida os testes feitos sobre os microdados de **cursos** e de **instituições (IES)** do Censo da Educação Superior de 2022, 2023 e 2024. O objetivo foi verificar a consistência do schema, a estabilidade das informações ao longo dos anos, as relações entre campos, a ocorrência de valores nulos ou sentinela, e a existência de duplicidades ou mudanças que poderiam afetar a integração. Os resultados fundamentam as decisões do esquema estrela (seção 15).

Cada seção segue o formato: **teste realizado**, **descobertas**, **motivação** e, quando houve decisão, **implicação para o modelo**.

## 2. Parâmetros de leitura e reprodutibilidade

- Ambiente: Python com pandas em um ambiente virtual (`.venv`) do repositório; testes no notebook `notebooks/00_exploracao.ipynb`.
- Os arquivos usados por ano são `MICRODADOS_CADASTRO_CURSOS_<ano>.CSV` e `MICRODADOS_ED_SUP_IES_<ano>.CSV`, além do dicionário de dados e do `Leia_me.pdf` de cada ano.
- Leitura: `sep=";"` e `encoding="latin1"` (com UTF-8 ocorre `UnicodeDecodeError`). Os cabeçalhos foram lidos com `nrows=0`, e os testes com dados usaram `usecols=` para não carregar as 223 colunas.
- A coluna `NO_MUNICIPIO` tem tipos mistos e gera `DtypeWarning`; por isso a carga deve usar `low_memory=False` ou `dtype=str` nos códigos.
- Os CSVs (332 a 453 MB) ficam fora do Git, e este relatório não depende de nenhum arquivo do repositório além do notebook.

| Ano | Linhas (cursos) | Colunas (cursos) | Cursos distintos | Linhas (IES) | Colunas (IES) |
| --- | --- | --- | --- | --- | --- |
| 2022 | 573.019 | 200 | 45.296 | 2.595 | 81 |
| 2023 | 671.610 | 202 | 46.317 | 2.580 | 84 |
| 2024 | 720.349 | 223 | 46.150 | 2.561 | 84 |

## 3. Comparação do schema dos cursos

**Teste realizado.** Os cabeçalhos dos CSVs foram lidos com `nrows=0` e os conjuntos de nomes de coluna foram comparados entre os anos, sem carregar registros.

**Descobertas.**

- 200 colunas em 2022, 202 em 2023 e 223 em 2024.
- De 2022 para 2023 entram `IN_COMUNITARIA` e `IN_CONFESSIONAL`.
- De 2023 para 2024 saem `QT_ING_RVETNICO`, `QT_MAT_RVETNICO` e `QT_CONC_RVETNICO`.
- De 2023 para 2024 entram **24 colunas**: oito grupos de reserva de vagas (`RVIDOSO`, `RVINTERN`, `RVMEDAL`, `RVPOVT`, `RVPPI`, `RVQUILO`, `RVREFU`, `RVTRANS`), cada um em três versões (`QT_ING_`, `QT_MAT_` e `QT_CONC_`).

**Motivação.** Conhecer as mudanças de formato e escolher campos comuns ou compatíveis entre os anos. A troca da coluna agregada de reserva étnica por categorias detalhadas em 2024 exige tratamento específico antes de qualquer comparação temporal.

## 4. Comparação do schema das IES

**Teste realizado.** Mesma comparação de cabeçalhos para o arquivo de IES.

**Descobertas.**

- 81 colunas em 2022 e 84 em 2023 e 2024.
- De 2022 para 2023 entram `IN_COMUNITARIA`, `IN_CONFESSIONAL` e `TP_REDE`.
- Não há entradas nem saídas entre 2023 e 2024.
- Embora `TP_REDE` só exista no arquivo de IES a partir de 2023, ele **já existe no arquivo de cursos nos três anos**.

**Motivação e implicação.** Saber de onde sai a rede (pública ou privada) em 2022. Como a categoria administrativa existe em todos os anos, a rede passa a ser derivada dela e validada contra `TP_REDE` onde ele existe (seção 12).

## 5. Dicionário de dados: códigos e reserva étnica

**Teste realizado.** Leitura dos dicionários de 2022, 2023 e 2024 para as colunas `TP_` e para as colunas de reserva étnica.

**Descobertas.**

- As listas de códigos de `TP_DIMENSAO`, `TP_REDE`, `TP_CATEGORIA_ADMINISTRATIVA`, `TP_ORGANIZACAO_ACADEMICA`, `TP_GRAU_ACADEMICO`, `TP_MODALIDADE_ENSINO` e `TP_NIVEL_ACADEMICO` são **idênticas nos três anos**. Um único dicionário código → texto serve para todos os anos.
- O dicionário de 2024 ainda lista `QT_ING_RVETNICO`, `QT_MAT_RVETNICO` e `QT_CONC_RVETNICO`, embora elas não existam no CSV de 2024. As posições passam de 158, 164 e 170 (2023) para 158, 172 e 186 (2024), compatível com as colunas novas inseridas.
- A descrição de `QT_CONC_RVETNICO` em 2024 passa a mencionar também “programa diferenciado de destinação de vagas”, o que sugere ampliação do conceito.
- O dicionário **não explica** como as colunas novas de 2024 se relacionam com a antiga.
- `TP_DIMENSAO` tem 4 valores: 1 cursos presenciais no Brasil; 2 cursos a distância no Brasil; 3 cursos a distância com dados somente em nível Brasil; 4 cursos a distância de instituições brasileiras no exterior. O dicionário informa que, para cursos a distância, não é possível quantificar cursos, vagas e inscritos por região, UF ou município.
- O valor “(.)” de `TP_GRAU_ACADEMICO` significa não aplicável.

**Motivação.** Confirmar o significado dos códigos antes de decodificá-los e verificar se algum código muda de sentido entre os anos (o que seria um erro silencioso).

## 6. Localização e classificação das variáveis

**Teste realizado.** Busca por palavra-chave nos nomes de coluna de cada arquivo (região, CINE, FIES, ProUni, raça/cor, reserva, município, UF, capital, gratuito, mantenedora, vagas e inscritos).

**Descobertas.**

- Região: `CO_REGIAO` e `NO_REGIAO`. Município: `CO_MUNICIPIO` e `NO_MUNICIPIO`. UF: `CO_UF`, `NO_UF` e `SG_UF`. Capital: `IN_CAPITAL`. Gratuidade: `IN_GRATUITO`.
- CINE: oito colunas (código e nome de rótulo, área geral, específica e detalhada).
- FIES: três variantes por tipo de aluno (`FIES`, `RPFIES`, `NRPFIES`). ProUni: duas (`PROUNII` e `PROUNIP`, cujo significado precisa ser confirmado no dicionário).
- Raça/cor: `PRETA`, `PARDA` e `INDIGENA`. Reserva: `RESERVA_VAGA`.
- Vagas e inscritos: `QT_VG_TOTAL` e `QT_INSCRITO_TOTAL`, com variantes diurno, noturno e EAD.
- `NO_IES`, `SG_IES` e a mantenedora **não estão no arquivo de cursos**, e sim no de IES (`CO_MANTENEDORA`, `NO_MANTENEDORA`, `SG_UF_IES`, `NO_MUNICIPIO_IES`, `IN_CAPITAL_IES`, entre outras).

**Motivação.** Identificar famílias de variáveis antes de montar o modelo, evitando nomes errados ou dados omitidos por estarem em outro arquivo. Isso justifica usar os dois arquivos (cursos e IES) ligados por `CO_IES`.

## 7. Verificação das colunas escolhidas

**Teste realizado.** Para cada coluna candidata ao modelo, verificou-se a existência nos três anos: `NU_ANO_CENSO`, `CO_CURSO`, `CO_MUNICIPIO`, `CO_IES`, `CO_CINE_ROTULO`, `QT_ING`, `QT_MAT`, `QT_CONC`, `QT_ING_FIES`, `QT_ING_PROUNII`, `QT_ING_PROUNIP`, `QT_ING_PRETA`, `QT_ING_PARDA`, `QT_ING_INDIGENA`, `QT_ING_RESERVA_VAGA`, `TP_GRAU_ACADEMICO`, `TP_NIVEL_ACADEMICO`, `TP_MODALIDADE_ENSINO`, `TP_DIMENSAO`, `TP_REDE`, `TP_CATEGORIA_ADMINISTRATIVA`, `TP_ORGANIZACAO_ACADEMICA`, `CO_REGIAO` e `NO_REGIAO`.

**Descobertas.** Todas as 24 colunas existem nos três anos. As exceções conhecidas continuam sendo as colunas `IN_COMUNITARIA`, `IN_CONFESSIONAL` e as de reserva étnica (seções 3 e 8).

**Motivação.** Garantir que o modelo não dependa de variável inexistente em algum ano, o que causaria falhas na carga ou integrações incompletas.

## 8. Reserva de vagas e distribuição racial

**Teste realizado.** Soma dos ingressantes totais comparada à reserva étnica: `QT_ING_RVETNICO` em 2022 e 2023, e `QT_ING_RVPPI + QT_ING_RVQUILO + QT_ING_RVPOVT` em 2024. Calculou-se também a soma de pretos, pardos e indígenas declarados.

**Descobertas.**

| Ano | Reserva étnica (% dos ingressantes) | Pretos + pardos + indígenas (%) |
| --- | --- | --- |
| 2022 | 1,34% | 34,10% |
| 2023 | 1,45% | 35,39% |
| 2024 | 1,66% | 36,02% |

Em 2024 a soma da reserva é de 83.041 ingressantes: 79.969 em `RVPPI`, 2.314 em `RVQUILO` e 758 em `RVPOVT`.

**Interpretação e limites.** A série é suave, sem salto em 2024, o que torna **plausível** usar a soma como substituta da coluna antiga. Isso não prova equivalência: o dicionário não confirma a correspondência, e persiste o risco de dupla contagem se um aluno constar em mais de um grupo. A reserva étnica (cerca de 1,5%) e a cor/raça declarada (cerca de 35%) medem coisas diferentes e não devem ser tratadas como a mesma série.

**Implicação para o modelo.** Medida derivada `qt_ing_reserva_etnica`, definida como descrito acima, documentada como aproximação.

## 9. Dimensão geográfica, modalidade, vagas e inscritos

**Teste realizado.** Tabelas cruzadas entre `TP_DIMENSAO` e `TP_MODALIDADE_ENSINO` nos três anos, e somas de ingressantes, matrículas, vagas e inscritos por dimensão.

**Descobertas.**

A modalidade é determinada pela dimensão: a 1 é sempre presencial, e as 2, 3 e 4 são sempre a distância.

| Dimensão | Linhas 2022 | Linhas 2023 | Linhas 2024 |
| --- | --- | --- | --- |
| 1 (presencial) | 36.089 | 35.739 | 34.824 |
| 2 (EAD por polo) | 527.328 | 624.836 | 673.756 |
| 3 (EAD nível Brasil) | 9.207 | 10.576 | 11.319 |
| 4 (EAD exterior) | 395 | 459 | 450 |

Em 2023, cada tipo de linha carrega medidas diferentes:

| Dimensão | QT\_ING | QT\_MAT | QT\_VG\_TOTAL | QT\_INSCRITO\_TOTAL |
| --- | --- | --- | --- | --- |
| 1 | 1.679.790 | 5.063.936 | 5.440.999 | 8.627.123 |
| 2 | 3.312.712 | 4.910.515 | 0 | 0 |
| 3 | 0 | 0 | 19.180.966 | 5.887.566 |
| 4 | 1.690 | 2.766 | 0 | 0 |

Os totais de ingressantes (4.994.192) e matrículas (9.977.217) de 2023 batem com a soma das quatro dimensões. Em 2022 o padrão é o mesmo: a dimensão 3 tem zero ingressantes e matrículas, a dimensão 4 tem 1.788 ingressantes e 2.818 matrículas, a dimensão 3 concentra 17.171.895 vagas e 8.176.586 inscritos, e a dimensão 1 tem 5.658.590 vagas e 8.811.102 inscritos. Em 2024, a dimensão 3 tem 18.583.348 vagas e 7.060.934 inscritos, a dimensão 1 tem 5.075.146 vagas e 8.658.561 inscritos, e a dimensão 2 tem apenas 6.925 vagas e 3.590 inscritos.

**Motivação.** Verificar se os valores agregados seguem a classificação geográfica e decidir quais dimensões servem a análises territoriais.

**Implicação para o modelo.** `QT_VG_TOTAL` e `QT_INSCRITO_TOTAL` entram na fato, porque as linhas da dimensão 3 só carregam essas medidas. Vagas de EAD existem apenas em nível Brasil e não podem ser quebradas por região.

## 10. Município nulo e código zero

**Teste realizado.** Tabela cruzada entre `TP_DIMENSAO` e a presença de `CO_MUNICIPIO` em 2023; em 2022, contagem do valor 0 em `CO_MUNICIPIO`, `CO_UF` e `CO_REGIAO`; e verificação de em quais dimensões o 0 ocorre.

**Descobertas.**

| Ano | Sem município | Onde |
| --- | --- | --- |
| 2022 | 0 nulos, mas **código 0** em 9.603 linhas | dimensão 3 (9.207), dimensão 4 (395) e 1 linha da dimensão 2; `CO_UF` e `CO_REGIAO` também 0 |
| 2023 | 11.039 nulos (região nula também em 11.039) | dimensão 3 (10.576), dimensão 4 (459), dimensão 2 (4) |
| 2024 | 11.778 nulos | dimensões 3 e 4 somam 11.769; as 9 restantes provavelmente são da dimensão 2 (não testado) |

Ou seja, o mesmo tipo de linha é representado por **código 0 em 2022 e por nulo em 2023 e 2024**. O nome do município vem vazio nos três anos para essas linhas. Em 2022, a dimensão 3 tem zero ingressantes e matrículas, e a dimensão 4 tem 1.788 ingressantes e 2.818 matrículas. Em 2023, a dimensão 4 tem 1.690 ingressantes (cerca de 0,03% do total).

**Motivação.** O dicionário diz que cursos a distância não podem ser quantificados por município. O teste confirma na prática e identifica o 0 como valor sentinela, que não pode ser tratado como município válido.

**Implicação para o modelo.** As linhas **não são descartadas**: descartá-las perderia as vagas da dimensão 3 e quebraria a conferência de linhas entre ETL e ELT. A `dim_localidade` recebe dois membros especiais, definidos por `TP_DIMENSAO` e não pelo código: dimensão 4 é “Exterior”; dimensão 3, município nulo ou 0 é “Sem município (EAD nível Brasil)”. O impacto no recorte regional da análise 1 é desprezível.

## 11. Duplicidade de registros e chave da fato

**Teste realizado.** Contagem de linhas duplicadas pela combinação `CO_CURSO` + `CO_MUNICIPIO` (por ano), sem e com `TP_DIMENSAO`, e contagem de cursos com mais de uma `TP_DIMENSAO`. As contagens incluem todas as linhas envolvidas em duplicatas, e não só as repetidas.

**Descobertas.**

| Ano | Linhas duplicadas sem `TP_DIMENSAO` | Com `TP_DIMENSAO` | Cursos com mais de uma `TP_DIMENSAO` |
| --- | --- | --- | --- |
| 2022 | 792 | 0 | 9.154 |
| 2023 | 922 | 0 | 10.507 |
| 2024 | 904 | 0 | 11.248 |

Há cerca de 46 mil cursos para mais de 570 mil linhas por ano, porque o EAD aparece uma vez por polo.

**Motivação.** Distinguir duplicidade real de registros legítimos em dimensões diferentes.

**Implicação para o modelo.** A chave da fato é `(ano, CO_CURSO, CO_MUNICIPIO, TP_DIMENSAO)`, única nos três anos. Como a dimensão varia dentro do mesmo curso, `TP_DIMENSAO` fica na fato (via `dim_dimensao`) e não na `dim_curso`. Cursos devem ser contados com `COUNT(DISTINCT CO_CURSO)`, nunca por número de linhas.

## 12. Categoria administrativa e rede

**Teste realizado.** Tabela cruzada entre `TP_CATEGORIA_ADMINISTRATIVA` e `TP_REDE` no arquivo de cursos de 2022 e no de IES de 2023 e 2024.

**Descobertas.** A correspondência é exata, sem exceções:

| Categoria | Rede | Cursos 2022 (linhas) | IES 2023 | IES 2024 |
| --- | --- | --- | --- | --- |
| 1 Pública Federal | Pública | 9.781 | 121 | 122 |
| 2 Pública Estadual | Pública | 7.485 | 138 | 139 |
| 3 Pública Municipal | Pública | 1.001 | 30 | 28 |
| 7 Especial | Pública | 349 | 27 | 28 |
| 4 Privada com fins lucrativos | Privada | 493.177 | 1.473 | 1.486 |
| 5 Privada sem fins lucrativos | Privada | 61.226 | 791 | 758 |

As categorias 6, 8 e 9 existem no dicionário, mas **não aparecem nos dados**.

**Motivação.** Confirmar que categoria e rede são coerentes e resolver o caso da categoria 7, ambígua pelo nome (“Especial”).

**Implicação para o modelo.** A rede é derivada da categoria em todos os anos (1, 2, 3 e 7 públicas; 4 e 5 privadas), com teste que falha se surgir outro código. `TP_REDE` serve de validação em 2023 e 2024.

## 13. Estabilidade dos atributos entre anos

**Teste realizado.** Registros agrupados por `CO_CURSO` e por `CO_IES`; contagem de códigos que apresentam mais de um valor de cada atributo ao longo dos três anos.

**Descobertas.** Foram encontrados 50.577 códigos de curso e 2.792 códigos de IES.

| Atributo | Quantos mudam | Proporção aproximada |
| --- | --- | --- |
| Curso: nível acadêmico, modalidade | 0 | 0% |
| Curso: gratuidade | 53 | 0,1% |
| Curso: nome | 265 | 0,5% |
| Curso: grau acadêmico | 335 | 0,7% |
| Curso: IES | 346 | 0,7% |
| Curso: rótulo CINE | 2.746 | 5,4% |
| IES: organização acadêmica | 37 | 1,3% |
| IES: categoria administrativa | 38 | 1,4% |
| IES: sigla | 153 | 5,5% |
| IES: nome | 171 | 6,1% |
| IES: código da mantenedora | 121 | 4,3% |
| IES: nome da mantenedora | 272 | 9,7% |

**Motivação.** Identificar quais atributos são estáveis e quais variam, para decidir se a modelagem preserva o histórico ou assume só o valor mais recente.

**Implicação para o modelo.** `dim_curso` e `dim_ies` guardam **uma linha por código e por ano**, com a chave substituta formada por (código, ano). Assim a fato aponta para a versão do próprio ano, sem lógica de datas de validade. `CO_IES` e `CO_CINE_ROTULO` ficam como chaves estrangeiras na fato. A mantenedora, que é o atributo mais instável e que nenhuma análise usa, fica fora do modelo.

## 14. Consistência dentro do ano, mudanças de rede e CINE

**Teste realizado.** Dentro de cada ano, verificou-se se um mesmo `CO_CURSO` tinha mais de um valor de IES, CINE, nome, grau, nível, modalidade ou gratuidade. Em seguida, mediram-se as mudanças de rede das IES (e o peso delas nas matrículas) e as mudanças de área e rótulo CINE.

**Descobertas.**

- Nenhum curso tem mais de um valor desses atributos dentro de um mesmo ano. A instabilidade da seção 13 ocorre apenas **entre** anos.
- Só 1 IES mudou de rede, representando 0,01% das matrículas em cada ano.
- 219 cursos (cerca de 0,4%) mudaram de área geral CINE. O número de rótulos CINE distintos quase não oscila (351, 354 e 353).
- Apenas um código de rótulo CINE tem mais de um nome: Engenharia de computação, escrito “Engenharia de computação (DCN Engenharia)” em 2022 e 2023 e “Engenharia de computação” em 2024. É renomeação, não reclassificação.

**Motivação.** Diferenciar mudança real de classificação de inconsistência de descrição, e verificar se a mudança de rede pesa nos dados.

**Implicação para o modelo.** A versão por ano protege a análise de rede, e uma frase no relatório basta para o CINE. `dim_area_cine` guarda uma linha por código, com o nome mais recente.

## 15. Conferência dos totais

**Teste realizado.** Comparação das somas de ingressantes e matrículas lidas dos CSVs com os totais de referência do plano do grupo.

**Descobertas.** Em 2023 os totais de ingressantes (4.994.192) e matrículas (9.977.217) foram reproduzidos exatamente pela soma das dimensões da seção 9. Para 2022 e 2024, a conferência ainda deve ser registrada em notebook, com estes valores de referência:

| Verificação | 2022 | 2023 | 2024 |
| --- | --- | --- | --- |
| Linhas (cursos) | 573.019 | 671.610 | 720.349 |
| Cursos distintos | 45.296 | 46.317 | 46.150 |
| `SUM(QT_ING)` | 4.756.957 | 4.994.192 | 5.010.613 |
| `SUM(QT_MAT)` | 9.444.116 | 9.977.217 | 10.227.266 |

**Motivação.** Provar que a leitura reproduz os números de referência, que serão também a conferência entre ETL e ELT.

## 16. Conclusões e decisões para o modelo

As variáveis essenciais estão disponíveis nos três anos, mas há mudanças estruturais que o modelo precisa tratar:

1. **Reserva étnica:** unificar em `qt_ing_reserva_etnica` (coluna antiga em 2022 e 2023; soma de `RVPPI`, `RVQUILO` e `RVPOVT` em 2024), registrando que é uma aproximação.
2. **Localidade:** tratar o código 0 (2022) e o município nulo (2023 e 2024) com os membros “Exterior” e “Sem município (EAD nível Brasil)”, definidos por `TP_DIMENSAO`. As linhas são mantidas, e não excluídas.
3. **Granularidade:** a fato tem uma linha por curso, município, dimensão geográfica e ano; `TP_DIMENSAO` entra na chave e na fato.
4. **Vagas e inscritos** entram na fato, porque as linhas da dimensão 3 só carregam essas medidas.
5. **Histórico:** `dim_curso` e `dim_ies` com uma linha por código e ano, sem substituir silenciosamente valores históricos.
6. **CINE:** uma linha por código, com o nome mais recente; o código não é alterado.
7. **Rede:** derivada da categoria administrativa, validada por `TP_REDE` em 2023 e 2024, com falha se surgir categoria inesperada.
8. **Contagens:** cursos contados por `COUNT(DISTINCT CO_CURSO)`, evitando supercontagem causada pelo EAD por polo.