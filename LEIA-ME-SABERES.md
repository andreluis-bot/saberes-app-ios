# App iOS do Saberes (INTERSSAN · UNESP)

Este repositório é o app oficial do Open edX para iOS ([openedx/openedx-app-ios](https://github.com/openedx/openedx-app-ios),
licença Apache 2.0) com a identidade da **Plataforma Saberes** aplicada pelo script oficial de marca branca
(`config_script/whitelabel.py`): cores, ícone, logo, fontes (Inter e Outfit), nome "Saberes", pacote
`org.interssan.saberes` e a configuração do servidor `https://saberes.interssan.org`.

Ele é gerado a partir do projeto do Saberes (pasta `apps-moveis/saberes-ios/` do repositório principal, privado);
não edite aqui à mão — reaplique por lá e publique de novo.

A compilação roda no GitHub Actions (macOS): `.github/workflows/saberes-simulador.yml` gera a versão de simulador,
usada para testar no navegador pelo Appetize.io. Para o iPhone de verdade (TestFlight/App Store) é preciso a conta
Apple Developer do INTERSSAN/UNESP.
