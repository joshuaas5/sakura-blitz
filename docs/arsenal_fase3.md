# Arsenal — entrega local 0.6.0

O lobby ganhou a página Arsenal, com seis armas, prévias das malhas reais e seleção persistente para as arenas. Todas as armas básicas estão disponíveis sem cobrança. As corridas continuam usando a karambit, preservando a escolha de combate para a próxima arena. Ajustar opções ou escolher um equipamento durante uma corrida pausada mantém a faca na corrida.

## Funções das armas novas

| Arma | Função inicial | Carregador | Cadência | Recarga | Dano corporal |
| --- | --- | --- | --- | --- | --- |
| Brisa SMG | Mobilidade e curta distância | 28 | 0,065 s entre tiros | 1,5 s | 24 até 12 m, reduzindo a 12 aos 32 m |
| Flora escopeta | Impacto próximo, intervalo entre disparos | 8 | 0,72 s entre tiros | 2,1 s | 8 × 14 até 5 m, reduzindo a 8 × 3 aos 20 m, se todos os projéteis acertarem |

São parâmetros iniciais, sujeitos a partidas humanas. Não representam balanceamento competitivo concluído. A compensação por abate limita a munição adicional das novas armas a quatro balas na SMG e uma cartucha na escopeta.

Cada cartucho resolve oito raios com dispersão em disco; mirar reduz a dispersão. Todos são consultados antes de aplicar dano, evitando que uma morte no primeiro projétil altere as colisões dos seguintes. Os impactos são somados por vítima, com bônus de cabeça calculado individualmente e aplicado uma única vez. Um alvo produz um evento de dano e, quando derrotado, um abate e um incremento de maestria. No máximo três traçantes e três impactos em paredes são criados por disparo. Paredes bloqueiam os raios.

## Apresentação e integração

Modelos CC0 Flat Guns West de Pichuliru, originais preservados com licença e hashes em `assets/third_party/pichuliru_guns`. Os derivados preparados têm carregador e ferrolho separados, com animação de recarga, recuo, mãos e amuleto. Skins existentes e silenciadores de maestria funcionam nos novos modelos; loja e Arsenal renderizam as próprias armas. Sons originais sintetizados por `tools/compose_weapon_audio.py`, com atenuação pelo silenciador e volume de efeitos.

PC: teclas 1–6 selecionam as armas; H alterna skins já obtidas; a evolução com moedas fica na loja. No celular, o botão de arma percorre as seis opções, e a página Arsenal permite equipar diretamente antes da partida.

`WeaponCatalog` concentra os parâmetros. Os índices antigos 0–3 permanecem intactos, incluindo faca no índice 3. O leitor migra arrays antigos para seis posições com valores iniciais nas novas armas, preservando carteira, skins, maestria e upgrades. A lista de propriedade de skins continua separada da lista de armas.

## Validação reproduzível

```powershell
godot --headless --path . --fixed-fps 60 -- --test --arsenal
godot --path . --fixed-fps 60 -- --qa --arsenal
godot --headless --path . --fixed-fps 60 -- --test
./tools/build_android_test.ps1
```

Os testes específicos usam raios físicos contra um bot: 112 de dano corporal no disparo próximo, 146 quando os oito projéteis acertam a cabeça, cartucho único, cooldown, cobertura sólida e recompensa única. Também verificam recarga interrompida, conservação de munição, migração de saves, persistência dos desbloqueios e seleção por eventos nativos de toque em 844 × 390.

Capturas reais em `shots/arsenal_*`. O ensaio renderizado usa GPU desktop; não comprova FPS ou ergonomia no celular. O APK mantém pacote e chave de depuração das versões anteriores, com versionCode 6.

Validação final: 1.431 verificações na suíte completa, zero falhas e zero SCRIPT ERROR; 37 verificações específicas passaram também no jogo nativo renderizado. APK gerado: `export/android/SakuraBlitz-0.6.0-test.apk` (78.244.894 bytes), assinatura v2/v3 e alinhamento de 16 KB verificados. Nenhuma validação em aparelho físico foi realizada nesta entrega.
