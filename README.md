# Projeto de atualização do portal da revista da Unimontes

## Snapshot do banco
O `db-snapshot.sh` copia os arquivos do MySQL em `data/mysql-copy`. O serviço MySQL
é parado antes da cópia para obter um estado consistente e iniciado novamente após
a operação. A cópia preserva permissões, proprietário/IDs numéricos, ACLs,
atributos estendidos, hard links e arquivos esparsos; o usuário será solicitado a
autorizar o uso de `sudo`.

Crie ou atualize o snapshot:
```
./db-snapshot.sh criar
```

Restaure o snapshot:
```
./db-snapshot.sh restaurar
```

A restauração exige confirmação digitando `RESTAURAR` e substitui os arquivos em
`data/mysql` pelo conteúdo de `data/mysql-copy`, removendo do destino arquivos que
não existam no snapshot. **Não execute esse comando como teste:** use-o somente
quando realmente quiser voltar ao estado salvo. Se a restauração falhar ou for
interrompida, o serviço MySQL permanecerá parado; execute a restauração novamente
até concluí-la e verifique o estado saudável do serviço antes de continuar.

O snapshot deve ser criado com sucesso antes de ser usado. Se a criação falhar, o
script informa o erro e tenta iniciar o MySQL; verifique o snapshot antes de
restaurá-lo. A criação publica o snapshot somente após a cópia terminar e mantém
as versões anteriores em `data/mysql-copy.previous.*`; arquivos inalterados podem
ser compartilhados por hard links. Essas versões não são removidas
automaticamente e ocupam espaço conforme os dados mudam.

O script não substitui backups externos do banco e dos arquivos do OJS.