# Relatório de migração do portal

## Revitas do portal classificadas por estado


| ID | Sigla | Nome da Revista | Status |
| :---: | :--- | :--- | :---: |
| 1 | `alteridade` | Revista Alteridade | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 2 | `araticum` | Revista Araticum | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 3 | `argumentos` | Argumentos - Revista do Departamento de Ciências Sociais da Unimontes | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 4 | `caminhosdahistoria` | Caminhos da História | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 5 | `cerrados` | Revista Cerrados | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 6 | `ciranda` | Revista Ciranda | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 7 | `clique` | Revista Clique | <span style="color: #cf222e; font-weight: bold;">Inativa</span> |
| 8 | `rds` | Revista Desenvolvimento Social | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 9 | `direito` | Revista do Curso de Direito da Universidade Estadual de Montes Claros | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 10 | `emd` | Educação Matemática Debate | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 11 | `rees` | Educação, Escola & Sociedade | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 12 | `renef` | RENEF | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 13 | `intercambio` | Revista Intercâmbio | <span style="color: #cf222e; font-weight: bold;">Inativa</span> |
| 14 | `multitexto` | Revista Multitexto | <span style="color: #cf222e; font-weight: bold;">Inativa</span> |
| 15 | `poiesis` | Revista Poiesis | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 16 | `renome` | Revista Renome | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 17 | `sesoperspectiva` | Revista Serviço Social em Perspectiva | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 18 | `unicientifica` | Revista Unimontes Científica | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 19 | `verdegrande` | Revista Verde Grande: Geografia e Interdisciplinaridade | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 20 | `economiaepoliticaspublicas` | Revista Economia e Políticas Públicas | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 21 | `revistaterceiramargem` | Revista Economia: Terceira Margem | <span style="color: #cf222e; font-weight: bold;">Inativa</span> |
| 22 | `noticias` | Periódicos Notícias | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |
| 24 | `mandragora` | Revista Mandrágora | <span style="color: #cf222e; font-weight: bold;">Inativa</span> |
| 25 | `revistamandragora` | Revista Mandrágora | <span style="color: #2ea043; font-weight: bold;">Ativa</span> |

```
SELECT 
    j.journal_id AS id,
    j.path AS sigla,
    COALESCE(js_pt.setting_value, js_any.setting_value, 'Sem título') AS nome_revista,
    CASE j.enabled
        WHEN 1 THEN 'Ativa'
        ELSE 'Inativa'
    END AS status
FROM journals j
LEFT JOIN journal_settings js_pt 
    ON j.journal_id = js_pt.journal_id 
    AND js_pt.setting_name = 'name' 
    AND js_pt.locale = 'pt_BR'
LEFT JOIN (
    SELECT journal_id, MAX(setting_value) AS setting_value
    FROM journal_settings
    WHERE setting_name = 'name'
    GROUP BY journal_id
) js_any ON j.journal_id = js_any.journal_id
ORDER BY 
    j.enabled DESC, 
    nome_revista ASC;
```

## Total de usuário ativos por perfil

| Perfil | Total |
| :--- | ---: |
| Administrador do Portal | 9 |
| Gerente de Assinaturas | 50 |
| Assistente Editorial | 88 |
| Editor de Seção | 114 |
| Gerente da Revista | 123 |
| Avaliador | 4.593 |
| Autor | 5.683 |
| Leitor | 15.700 |

```
SELECT 
    CASE ug.role_id
        WHEN 1 THEN 'Administrador do Portal'
        WHEN 16 THEN 'Gerente da Revista'
        WHEN 17 THEN 'Editor de Seção'
        WHEN 4096 THEN 'Avaliador'
        WHEN 4097 THEN 'Assistente Editorial'
        WHEN 65536 THEN 'Autor'
        WHEN 1048576 THEN 'Leitor'
        WHEN 2097152 THEN 'Gerente de Assinaturas'
        ELSE CONCAT('Outro (', ug.role_id, ')')
    END AS perfil,
    COUNT(DISTINCT u.user_id) AS total
FROM user_groups ug
INNER JOIN user_user_groups uug ON ug.user_group_id = uug.user_group_id
INNER JOIN users u ON uug.user_id = u.user_id
WHERE u.disabled = 1
GROUP BY ug.role_id
ORDER BY total ASC;
```

## Total de usuários por perfil inativos

| Perfil | Total |
| :--- | ---: |
| Gerente da Revista | 1 |
| Editor de Seção | 1 |
| Assistente Editorial | 1 |
| Gerente de Assinaturas | 1 |
| Autor | 6 |
| Avaliador | 259 |
| Leitor | 1.128 |

```
SELECT DISTINCT
    u.user_id,
    u.username,
    u.email,
    us_given.setting_value AS nome,
    us_family.setting_value AS sobrenome,
    j.path AS revista_sigla
FROM users u
INNER JOIN user_user_groups uug ON u.user_id = uug.user_id
INNER JOIN user_groups ug ON uug.user_group_id = ug.user_group_id
LEFT JOIN journals j ON ug.context_id = j.journal_id
LEFT JOIN user_settings us_given 
    ON u.user_id = us_given.user_id 
    AND us_given.setting_name = 'givenName' 
    AND us_given.locale = 'pt_BR' -- Altere para o idioma principal do portal, se necessário
LEFT JOIN user_settings us_family 
    ON u.user_id = us_family.user_id 
    AND us_family.setting_name = 'familyName' 
    AND us_family.locale = 'pt_BR'
WHERE ug.role_id = 1048576 -- ID da role Autor
  AND u.disabled = 0     -- Apenas usuários ativos (remova se quiser incluir inativos)
ORDER BY nome ASC, sobrenome ASC;
```

## Classificação de usuários por atividade 

| Perfil | Com Atividade | Sem Atividade | Total |
| :--- | ---: | ---: | ---: |
| Administrador do Portal | 2 | <span style="color: #d97706; font-weight: bold;">7</span> | 9 |
| Assistente Editorial | 82 | <span style="color: #d97706; font-weight: bold;">7</span> | 89 |
| Autor | 4.563 | <span style="color: #d97706; font-weight: bold;">1.126</span> | 5.689 |
| Avaliador | 3.343 | <span style="color: #d97706; font-weight: bold;">1.509</span> | 4.852 |
| Editor de Seção | 101 | <span style="color: #d97706; font-weight: bold;">14</span> | 115 |
| Gerente da Revista | 105 | <span style="color: #d97706; font-weight: bold;">19</span> | 124 |
| Gerente de Assinaturas | 50 | <span style="color: #d97706; font-weight: bold;">1</span> | 51 |

```
SELECT 
    CASE ug.role_id
        WHEN 1 THEN 'Administrador do Portal'
        WHEN 16 THEN 'Gerente da Revista'
        WHEN 17 THEN 'Editor de Seção'
        WHEN 4096 THEN 'Avaliador'
        WHEN 4097 THEN 'Assistente Editorial'
        WHEN 65536 THEN 'Autor'
        WHEN 2097152 THEN 'Gerente de Assinaturas'
    END AS perfil,
    COUNT(DISTINCT CASE WHEN atividade.user_id IS NOT NULL THEN u.user_id END) AS com_atividade,
    COUNT(DISTINCT CASE WHEN atividade.user_id IS NULL THEN u.user_id END) AS sem_atividade_nunca_atuou,
    COUNT(DISTINCT u.user_id) AS total_perfil
FROM user_groups ug
INNER JOIN user_user_groups uug ON ug.user_group_id = uug.user_group_id
INNER JOIN users u ON uug.user_id = u.user_id
LEFT JOIN (
    -- União de todas as tabelas que registram atividade editorial no OJS 3.4
    SELECT user_id FROM stage_assignments
    UNIONs
    SELECT reviewer_id AS user_id FROM review_assignments
    UNION
    SELECT editor_id AS user_id FROM edit_decisions
    UNION
    SELECT uploader_user_id AS user_id FROM submission_files WHERE uploader_user_id IS NOT NULL
    UNION
    SELECT author_id AS user_id FROM submission_comments
    UNION
    SELECT user_id FROM event_log WHERE user_id IS NOT NULL
    UNION
    SELECT user_id FROM notes WHERE user_id IS NOT NULL
    UNION
    SELECT user_id FROM query_participants
) atividade ON u.user_id = atividade.user_id
WHERE ug.role_id <> 1048576 -- Exclui o perfil Leitor
GROUP BY ug.role_id
ORDER BY total_perfil DESC;
```



#Queries Individualizadas por Perfil (Para Auditoria e Sanitização)
#Avaliadores (role_id = 4096) que NUNCA receberam ou fizeram avaliação
SELECT DISTINCT u.user_id, u.username, u.email, u.date_registered, u.date_last_login
FROM users u
INNER JOIN user_user_groups uug ON u.user_id = uug.user_id
INNER JOIN user_groups ug ON uug.user_group_id = ug.user_group_id
LEFT JOIN review_assignments ra ON u.user_id = ra.reviewer_id
WHERE ug.role_id = 4096
  AND ra.review_id IS NULL;

#Autores (role_id = 65536) que NUNCA submeteram ou participaram de submissão
SELECT DISTINCT u.user_id, u.username, u.email, u.date_registered, u.date_last_login
FROM users u
INNER JOIN user_user_groups uug ON u.user_id = uug.user_id
INNER JOIN user_groups ug ON uug.user_group_id = ug.user_group_id
LEFT JOIN stage_assignments sa ON u.user_id = sa.user_id
LEFT JOIN submission_files sf ON u.user_id = sf.uploader_user_id
WHERE ug.role_id = 65536
  AND sa.stage_assignment_id IS NULL
  AND sf.submission_file_id IS NULL;

#Equipe Editorial (role_id 16, 17, 4097) sem decisões, atribuições ou logs
SELECT DISTINCT u.user_id, u.username, u.email, ug.role_id, u.date_registered, u.date_last_login
FROM users u
INNER JOIN user_user_groups uug ON u.user_id = uug.user_id
INNER JOIN user_groups ug ON uug.user_group_id = ug.user_group_id
LEFT JOIN stage_assignments sa ON u.user_id = sa.user_id
LEFT JOIN edit_decisions ed ON u.user_id = ed.editor_id
LEFT JOIN event_log el ON u.user_id = el.user_id
WHERE ug.role_id IN (16, 17, 4097)
  AND sa.stage_assignment_id IS NULL
  AND ed.edit_decision_id IS NULL
  AND el.log_id IS NULL;
