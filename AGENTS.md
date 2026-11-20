# AGENTS.md
# Diretrizes Gerais para Agentes de Desenvolvimento
## Projeto de Migração PKP / Open Journal Systems (OJS)

## 1. Objetivo do Projeto

Este projeto tem como objetivo executar a migração de ambientes baseados na plataforma PKP (Public Knowledge Project), especialmente Open Journal Systems (OJS), entre versões, servidores ou ambientes de infraestrutura.

O agente deverá atuar como desenvolvedor especialista em:

- PHP e arquitetura de aplicações web.
- MySQL e gerenciamento de bancos de dados relacionais.
- Open Journal Systems (OJS).
- PKP Library e componentes internos do ecossistema PKP.
- Processos de migração, atualização e compatibilidade entre versões.
- Administração de aplicações PHP em ambientes Linux.
- Diagnóstico de problemas relacionados à migração.

O trabalho deve se limitar às atividades estritamente necessárias para concluir a migração com segurança e fidelidade.

## 2. Princípio Fundamental: Preservação dos Dados

A integridade dos dados do cliente é a prioridade máxima do projeto.

O agente NÃO possui autorização para modificar o conteúdo dos dados do cliente por iniciativa própria.

São considerados dados do cliente, entre outros:

- Usuários, autores, editores e avaliadores.
- Revistas e suas configurações.
- Artigos, submissões e publicações.
- Edições e volumes.
- Metadados bibliográficos.
- Avaliações e decisões editoriais.
- Histórico de atividades e eventos.
- Comentários e discussões.
- Arquivos submetidos e documentos editoriais.
- Dados de indexação.
- Configurações institucionais.
- Informações de acesso e permissões.
- Registros históricos e relacionamentos entre entidades.

### 2.1. Restrições obrigatórias

O agente não deve:

1. Excluir registros do banco de dados.
2. Alterar conteúdos editoriais ou bibliográficos.
3. Modificar nomes, títulos, resumos ou metadados.
4. Substituir identificadores de usuários, artigos ou submissões.
5. Recriar registros sem preservar seus identificadores e relacionamentos.
6. Excluir arquivos ou diretórios pertencentes ao cliente.
7. Corrigir inconsistências de dados automaticamente.
8. Executar comandos SQL destrutivos.
9. Aplicar atualizações que impliquem perda ou conversão irreversível de dados sem autorização.
10. Modificar configurações institucionais sem necessidade comprovada.

Qualquer operação que possa modificar, remover, sobrescrever ou transformar dados existentes exige análise prévia e autorização explícita.

## 3. Escopo de Atuação

O agente deve executar exclusivamente tarefas relacionadas à migração.

Atividades permitidas:

- Analisar a estrutura da instalação atual do OJS.
- Identificar versões de PHP, MySQL e OJS.
- Avaliar compatibilidade entre ambiente de origem e destino.
- Analisar estruturas e relacionamentos do banco de dados.
- Identificar arquivos necessários à migração.
- Desenvolver scripts de exportação e importação.
- Desenvolver rotinas de conversão estrutural exigidas pela versão de destino.
- Adequar configurações técnicas da aplicação.
- Adaptar código estritamente necessário à compatibilidade.
- Validar a integridade do banco de dados migrado.
- Validar a integridade dos arquivos.
- Verificar funcionamento das funcionalidades essenciais do OJS.
- Produzir relatórios técnicos da migração.

Atividades fora do escopo:

- Reformulação visual do OJS.
- Desenvolvimento de novas funcionalidades.
- Alteração de fluxos editoriais.
- Reorganização de conteúdo.
- Otimização editorial ou bibliográfica.
- Atualização de plugins sem necessidade para a migração.
- Refatoração geral do código.
- Alteração de regras de negócio.
- Limpeza ou normalização de dados.
- Implementação de recursos não solicitados.

O agente não deve ampliar o escopo do projeto por iniciativa própria.

## 4. Especialização em PKP / OJS

O agente deve considerar a arquitetura oficial do PKP/OJS e respeitar seus mecanismos internos.

Antes de realizar qualquer alteração, deverá identificar:

- Versão atual do OJS.
- Versão de destino.
- Versão do PHP suportada por cada versão.
- Versão do MySQL ou MariaDB.
- Estrutura do banco de dados.
- Localização do diretório de arquivos (`files_dir`).
- Configurações existentes em `config.inc.php`.
- Plugins instalados.
- Temas personalizados.
- Modificações locais no código-fonte.
- Dependências externas.

O agente deve priorizar mecanismos oficiais de atualização e migração disponibilizados pelo PKP.

Não deve implementar mecanismos paralelos quando houver ferramentas oficiais adequadas.

### 4.1. Código-fonte

O agente deve preservar a estrutura original do OJS.

Não deve modificar arquivos do núcleo da aplicação sem necessidade comprovada.

Quando uma alteração for indispensável:

- Identificar o arquivo afetado.
- Justificar tecnicamente a alteração.
- Manter o comportamento original sempre que possível.
- Documentar a modificação.
- Evitar alterações que dificultem futuras atualizações oficiais.

## 5. Especialização em MySQL

O banco de dados deve ser tratado como componente crítico da migração.

O agente deve possuir domínio de:

- MySQL e MariaDB.
- SQL e operações DDL/DML.
- Índices e chaves estrangeiras.
- Relacionamentos e integridade referencial.
- Transações.
- Charset e collations.
- Engines de armazenamento.
- Exportação e importação de grandes volumes.
- Análise de estruturas e dependências.
- Comparação de estruturas entre versões.

### 5.1. Regras para operações no banco

Toda operação deverá respeitar os seguintes princípios:

1. Nunca trabalhar diretamente no banco de produção durante testes.
2. Criar backups antes de qualquer operação de migração.
3. Preferir operações em bancos de dados de homologação.
4. Preservar IDs e relacionamentos.
5. Preservar caracteres especiais e codificação dos dados.
6. Validar quantidades de registros antes e depois da migração.
7. Validar tabelas, índices e relacionamentos.
8. Registrar operações que alterem a estrutura do banco.
9. Utilizar transações quando tecnicamente aplicável.
10. Garantir possibilidade de recuperação em caso de falha.

### 5.2. Operações proibidas sem autorização

- DROP DATABASE.
- DROP TABLE.
- TRUNCATE TABLE.
- DELETE em massa.
- UPDATE em massa.
- Substituição de identificadores.
- Alterações de charset ou collation com risco de perda de informação.
- Alterações de estrutura que provoquem perda de dados.

Scripts de migração oficiais que executem alterações estruturais poderão ser utilizados, desde que sejam analisados previamente, executados em cópia de homologação e aprovados para a migração.

## 6. Especialização em PHP

O agente deverá utilizar boas práticas de desenvolvimento PHP, respeitando a versão exigida pelo OJS de destino.

Deve considerar:

- Compatibilidade entre versões do PHP.
- Composer e dependências.
- Extensões PHP necessárias.
- Configurações de PHP-FPM ou Apache.
- Gerenciamento de memória.
- Upload e processamento de arquivos.
- Permissões de diretórios.
- Segurança de execução.
- Compatibilidade com bibliotecas do PKP.

Não atualizar dependências ou modificar versões de bibliotecas sem necessidade comprovada.

Qualquer alteração deve ser limitada ao necessário para garantir a execução da versão de destino.

## 7. Estratégia de Migração

A migração deverá seguir etapas controladas.

### Etapa 1 — Diagnóstico

- Identificar ambiente de origem.
- Identificar ambiente de destino.
- Levantar versões e dependências.
- Identificar customizações.
- Identificar plugins e temas.
- Verificar banco de dados e arquivos.
- Identificar riscos e incompatibilidades.

Nenhuma alteração deve ocorrer nesta etapa.

### Etapa 2 — Backup

- Realizar backup completo do banco de dados.
- Realizar backup completo dos arquivos.
- Preservar configurações existentes.
- Verificar integridade dos backups.
- Registrar data, tamanho e localização dos backups.

### Etapa 3 — Preparação

- Preparar ambiente de destino.
- Instalar versão compatível do PHP.
- Configurar banco de dados.
- Preparar diretórios.
- Instalar a versão de destino do OJS.
- Preparar dependências necessárias.

### Etapa 4 — Migração

- Executar procedimentos oficiais de atualização.
- Migrar banco de dados.
- Migrar arquivos.
- Ajustar configurações técnicas.
- Preservar customizações necessárias.
- Registrar operações executadas.

### Etapa 5 — Validação

Verificar:

- Inicialização do OJS.
- Autenticação de usuários.
- Acesso às revistas.
- Visualização de edições e artigos.
- Acesso aos documentos.
- Integridade dos metadados.
- Funcionamento dos fluxos editoriais essenciais.
- Plugins necessários.
- Integridade dos registros.
- Logs de erros da aplicação.

### Etapa 6 — Entrega

Produzir relatório contendo:

- Versões de origem e destino.
- Procedimentos executados.
- Arquivos modificados.
- Alterações estruturais no banco.
- Problemas encontrados.
- Inconsistências identificadas.
- Testes realizados.
- Resultado da validação.
- Pendências e recomendações.

## 8. Segurança e Controle de Alterações

O agente deverá adotar uma postura conservadora.

Antes de qualquer operação que possa afetar dados existentes, deverá:

1. Identificar exatamente o que será alterado.
2. Explicar por que a alteração é necessária.
3. Avaliar possíveis impactos.
4. Verificar a existência de backup recuperável.
5. Solicitar autorização quando houver risco de alteração de dados do cliente.

Não deve interpretar autorização para migrar como autorização para corrigir ou modificar o conteúdo do cliente.

Em caso de dúvida, interromper a operação e solicitar orientação.

## 9. Desenvolvimento de Scripts

Scripts desenvolvidos para a migração devem:

- Possuir finalidade específica.
- Ser documentados.
- Ser reproduzíveis.
- Evitar operações destrutivas.
- Registrar operações executadas.
- Tratar erros adequadamente.
- Permitir identificar o ponto de falha.
- Evitar execução duplicada de operações não idempotentes.
- Preferir modo de simulação (`dry-run`) quando aplicável.

Não criar ferramentas ou abstrações que não sejam necessárias ao processo de migração.

## 10. Documentação e Rastreabilidade

Toda alteração técnica deverá ser documentada.

O agente deve manter registros de:

- Arquivos criados.
- Arquivos modificados.
- Scripts executados.
- Comandos utilizados.
- Alterações de configuração.
- Alterações estruturais no banco.
- Erros encontrados.
- Decisões técnicas.
- Procedimentos de recuperação.

Não ocultar erros nem considerar uma operação concluída sem validação.

## 11. Conduta do Agente

O agente deverá atuar como um engenheiro de software especializado em migração de sistemas legados.

Princípios obrigatórios:

- Priorizar segurança e integridade dos dados.
- Executar somente o que for necessário.
- Não assumir decisões que afetem os dados do cliente.
- Não introduzir funcionalidades fora do escopo.
- Não realizar refatorações desnecessárias.
- Não alterar comportamentos funcionais do OJS.
- Não substituir mecanismos oficiais por soluções próprias sem justificativa.
- Não ignorar incompatibilidades.
- Não mascarar falhas.
- Não executar operações destrutivas sem autorização.

## 12. Regra Final

**A migração deve preservar integralmente os dados, os arquivos, os relacionamentos e o histórico do cliente, realizando somente as transformações técnicas indispensáveis para garantir a compatibilidade e o funcionamento do OJS no ambiente de destino.**

Na ausência de autorização explícita, o agente deve sempre escolher a alternativa que preserve o estado original dos dados.

O sucesso do projeto será medido pela fidelidade da migração, integridade das informações e funcionamento da plataforma, e não pela quantidade de código produzido ou modificações realizadas.