# SecureLab Mobile

Cliente Flutter usado pelo administrador do SecureLab. O backend é sempre o
diretório irmão `../backend`; o firmware é `../firmware`.

## Executar durante o desenvolvimento

Com a API em execução em outro terminal:

```powershell
flutter pub get
flutter run -d chrome
```

O endereço padrão da API no navegador é `http://localhost:8000`. Para
alterá-lo, use a opção de servidor na tela de login.

## Ferramentas

- `INICIAR_SECURELAB.bat`: inicia o backend e o aplicativo juntos.
- `RODAR_SECURELAB.bat`: atalho para o mesmo processo.
- `SIMULAR_DIGITAL.bat`: envia uma leitura de teste, pedindo ID e chave de
  API do dispositivo.
- `GERAR_PACOTE.bat`: gera o build web em `build/web`.

O guia completo do sistema está em [`../README.md`](../README.md).
