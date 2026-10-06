# ZVS-26 backup helper

`export.sh` загружает переносимый snapshot базы знаний с административного backup endpoint.

GitHub Actions затем:

1. шифрует snapshot;
2. удаляет plaintext;
3. создаёт новый orphan commit;
4. force-push'ит его в ветку `backup`.

В результате в доступной истории ветки всегда одна актуальная копия.

## Restore

После получения файла из ветки `backup`:

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 250000 \
  -in zvs26-latest.tar.gz.enc \
  -out zvs26-latest.tar.gz \
  -pass pass:'YOUR_BACKUP_PASSWORD'
```

Пароль нельзя хранить в репозитории. Он хранится в GitHub Actions Secret и отдельно у администратора группы.
