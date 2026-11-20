# 1. Auditoria e Validação de Usuários

## 1.1. Objetivo

A primeira atividade do projeto será realizar uma auditoria dos usuários cadastrados no OJS, com o objetivo de identificar contas potencialmente suspeitas, considerando a reclamação do cliente sobre possíveis cadastros automatizados por robôs.

A auditoria deverá ser exclusivamente consultiva.

**É expressamente proibido excluir, bloquear, desativar, editar ou modificar qualquer conta de usuário durante essa etapa.**

## 1.2. Características do Banco de Dados

O banco de dados possui aproximadamente 1 GB de informações.

O agente deverá considerar esse volume ao elaborar consultas e scripts.

Requisitos:

- Não exportar o banco inteiro para realizar a auditoria.
- Não carregar todos os registros em memória desnecessariamente.
- Utilizar consultas SQL específicas.
- Priorizar índices existentes.
- Evitar operações que provoquem bloqueios ou degradem o banco.
- Executar consultas exclusivamente de leitura.
- Não criar índices ou alterar estruturas sem autorização.
- Quando necessário, executar a auditoria em uma cópia do banco.

## 1.3. Identificação dos Usuários

Antes de desenvolver qualquer consulta, o agente deverá analisar a estrutura real do banco de dados da versão instalada do OJS.

Identificar:

- Tabela de usuários.
- Identificador primário.
- Nome de usuário.
- Nome e sobrenome.
- Endereço de e-mail.
- Data de cadastro, se disponível.
- Estado da conta, se disponível.

Não presumir nomes de tabelas ou colunas sem verificar a estrutura existente.

## 1.4. Critérios de Classificação dos E-mails

Os endereços serão classificados em três categorias:

### A. Domínios de provedores conhecidos

Utilizar uma lista configurável de provedores de e-mail conhecidos, incluindo, entre outros:

- gmail.com
- hotmail.com
- outlook.com
- live.com
- yahoo.com
- icloud.com
- me.com
- proton.me
- protonmail.com
- uol.com.br
- bol.com.br
- terra.com.br

A lista poderá ser ampliada mediante identificação de provedores legítimos.

Não considerar automaticamente todos os domínios Google Workspace ou Microsoft 365 como confiáveis.

### B. Domínios educacionais e brasileiros

Considerar válidos os endereços cujo domínio atenda aos seguintes critérios:

- Terminação `.edu`.
- Terminação `.edu.br`.
- Terminação `.br`.

A validação deverá ser realizada sobre o domínio completo do endereço.

### C. Domínios fora dos critérios

Classificar como fora dos critérios todos os endereços que não se enquadrarem nas categorias anteriores.

Esses registros deverão compor a lista de análise do cliente.

A classificação não representa confirmação de fraude ou atividade automatizada.

## 1.5. Relatórios

O agente deverá produzir os seguintes relatórios:

1. Quantidade total de usuários.
2. Quantidade de usuários com e-mails dentro dos critérios.
3. Quantidade de usuários com e-mails fora dos critérios.
4. Quantidade de usuários sem e-mail.
5. Quantidade de e-mails duplicados.
6. Distribuição de usuários por domínio.
7. Relação individual dos usuários com e-mails fora dos critérios.

A relação individual deverá apresentar:

- ID do usuário.
- Username.
- Nome.
- Sobrenome.
- E-mail.
- Domínio identificado.
- Data de cadastro, quando disponível.
- Classificação atribuída.

Os relatórios deverão ser disponibilizados em CSV e, quando viável, XLSX.

## 1.6. Regras de Segurança

- Utilizar exclusivamente operações SELECT.
- Não modificar registros.
- Não executar DELETE, UPDATE, INSERT ou REPLACE.
- Não desativar contas.
- Não alterar senhas.
- Não modificar permissões.
- Não executar rotinas de limpeza.
- Não tentar validar a existência de caixas postais por envio de mensagens.
- Não realizar verificações externas de usuários sem autorização.

## 1.7. Entrega da Auditoria

Antes de concluir, o agente deverá apresentar:

- Metodologia utilizada.
- Consultas executadas.
- Quantidade total de registros analisados.
- Critérios de classificação.
- Resultados consolidados.
- Lista de e-mails fora dos critérios.
- Arquivos gerados.
- Confirmação de que nenhum dado foi modificado.

A execução desta etapa deverá ser considerada concluída somente após a geração dos relatórios e a confirmação da preservação integral do banco de dados.