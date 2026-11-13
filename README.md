# Sakura Blitz

FPS e corrida de obstáculos em Godot 4.7.2, com controles para celular na horizontal. Esta versão é um jogo local contra bots; multiplayer online, pagamentos e contas ainda não estão implementados.

**Produção atual: modo tiro.** O código local acrescenta duas arenas grandes, lotação por mapa, equipes, captura de bandeira e placar de partida. O APK 0.8.0 abaixo corresponde à entrega anterior; estas mudanças ainda não foram empacotadas. Detalhes em `docs/fps_producao.md`.

## Jogar localmente

No Windows, abra `run.bat`. Ele procura Godot na pasta `../tools/godot/` e depois no PATH. Também é possível importar `project.godot` no Godot 4.7.2 e apertar F5.

O lobby permite escolher modo, mapa e bots **Fácil, Médio ou Difícil**. A dificuldade escolhida vale para a próxima partida. Continuar mantém a partida pausada e sua dificuldade original.

### APK de teste no Android

`export/android/SakuraBlitz-0.8.0-test.apk` — transfira para o aparelho e abra para instalar **Sakura Blitz Teste**. O app usa tela horizontal, ativa controles de toque automaticamente e começa na qualidade leve. A qualidade pode ser alterada em Ajustes no lobby.

Build local de teste: Android 7.0/API 24 ou superior, ARM 32/64 bits, versão `0.8.0-test`, pacote `com.joshuaas5.sakurablitz.test`. Assinatura de depuração local; apenas permissão de vibração. Ainda requer teste de desempenho e ergonomia no aparelho real.

Para regenerar no PC configurado: `./tools/build_android_test.ps1`. O script exporta, verifica assinatura e alinhamento de 16 KB, inspeciona o manifesto e grava SHA256 em `export/android/`. Usa o SDK instalado em `C:/android-sdk`; aceita `-Godot` e `-AndroidSdk` para outros caminhos.

## Conteúdo desta versão

- **Onze arenas:** as nove anteriores, Vale do Chá (96 × 88 m) e Terminal Girassol (112 × 76 m). CQC usa seis bots; arenas táticas, oito; grandes, dezoito por padrão. Nas grandes, também é possível escolher 12, 18 ou 24. As grandes duram até cinco minutos; as compactas, três.
- **Modos de tiro locais:** Cada um por si, Equipes e Captura de Bandeira. Equipes incluem você na divisão equilibrada: 3×3 nas CQC, 4×4 nas táticas e 9×9 nas grandes; Caos permite 12×12. Sem fogo amigo. Bandeiras podem ser roubadas, carregadas, derrubadas, recuperadas e capturadas por jogadores e bots.
- **Seis corridas:** Festival das Nuvens, Telhados do Sol, Oásis das Marés, Órbita Neon, Jardim do Chá e Fábrica de Brinquedos. Cada percurso tem oito setores, sete corredores, checkpoints sequenciais, rota segura e atalhos.
- **Arsenal:** seis armas disponíveis desde o início, incluindo Brisa SMG e Flora escopeta, seleção no lobby, prévias 3D, recargas e maestria por arma. A escolha de combate permanece salva entre sessões e corridas.
- **Bots com níveis:** reação, precisão, frequência de tiro, movimento e velocidade de corrida diferentes; todos têm a mesma vida. Disparos respeitam paredes e os bots também disputam entre si.
- **Mobile:** analógico esquerdo, câmera à direita, pulo com arraste para olhar, tiro manual com arraste para mirar, recarga automática, assistência de subida em obstáculos baixos e tolerância no salto.
- **Perfil local:** moedas, equipamentos, recordes, preferências e maestria salvos com arquivo de recuperação. Ouro aos 50 abates por arma; silenciador cosmético aos 100 abates nas armas de fogo.
- **Economia:** moedas por desempenho, desafio diário resgatável uma vez e loja com cosméticos. Upgrades comprados com moedas de jogo dão até +3% de dano; skins não alteram atributos. Não há compra com dinheiro real nesta versão.
- **Visual e áudio:** Vila Floral com assets CC0 importados, HUD com molduras ilustradas, cinco armas importadas, skins pintadas e prévias 3D reais na loja e três loops musicais sintetizados para o projeto.
- **Porto Cobalto:** contêineres corrugados, escadas e passarelas de aço com guarda-corpos, sinalização, mar, armazéns e guindastes do Factory Kit CC0. Agrupamento por cor de vértice, sombras conforme qualidade, ambiente de ondas e passos metálicos. Detalhes e limites em `docs/porto_atelier.md`.

## Controles

| Entrada | Ação |
| --- | --- |
| WASD / mouse | Andar / olhar |
| Espaço | Pular; manter pressionado repete o salto ao pousar |
| Shift / Ctrl | Correr / agachar |
| Botões esquerdo / direito do mouse | Atirar / mirar |
| 1–6 / Q | Selecionar arma / troca rápida |
| R / F | Recarregar / inspecionar |
| Esc / L | Lobby / loja |
| G / B | Voltar ao checkpoint / reiniciar partida |
| M / N | Trocar modo / próximo mapa |
| Tab / toque no placar | Abrir e fechar a classificação da partida |
| P / V | Música / controles de toque |
| H / 7 | Alternar cosméticos já desbloqueados |

## Desenvolvimento e validação

Execute a partir da raiz, com Godot no PATH:

```powershell
godot --headless --editor --import --path .
godot --headless --fixed-fps 60 --path . -- --test
godot --path . -- --qa
godot --headless --path . --export-release Web build/web/index.html
python -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

O último comando serve o build em `http://127.0.0.1:8765/`. O navegador exige HTTP; não abra o HTML diretamente. A exportação exige os templates 4.7.2. A QA salva capturas ignoradas pelo Git em `shots/foundation_*.png` e imprime métricas do renderizador.

`--test` usa perfil descartável e simula percursos completos. Uma mensagem `EXPECTED DIAGNOSTIC` seguida de erro de leitura é intencional: verifica a recuperação de um save corrompido. O resultado final e o código de saída determinam sucesso ou falha.

Detalhes e próximos passos: [expansão mobile](docs/expansao_mobile.md). Procedência dos novos áudios: [músicas originais](assets/audio/original/README.md).

## Estado da publicação

O repositório contém um workflow de deploy para Cloudflare Pages ao enviar mudanças para `main`. Alterações locais não atualizam o [site publicado](https://sakura-blitz.pages.dev/). Esta expansão foi validada no Godot nativo e exportada para web; compatibilidade no navegador e desempenho em celulares reais ainda precisam de testes. Não há garantia de 60 FPS em aparelhos de 3–4 GB.

## Rework Atelier

Abra `run.bat`, selecione **Combate → Vila Floral** e use **L** para a loja ou **F** para inspecionar. A Vila Floral aparece primeiro na lista de arenas. O novo HUD funciona em todos os mapas; o cenário reconstruído está concentrado nessa arena.

Capturas adicionais: `godot --path . -- --qa --art`. Detalhes: [implementação Atelier](docs/rework_atelier.md). Licenças: [assets de terceiros](THIRD_PARTY_LICENSES.md).

## Novas arenas temáticas

No lobby, escolha **Combate** e selecione **Bazar Solar**, **Docas do Festival** ou **Observatório Lunar**. Cada uma tem composição própria, assets CC0 e navegação por caminhos para os bots. Detalhes e limites da validação em [docs/arenas_assinatura.md](docs/arenas_assinatura.md).

## Mobile 0.3.0

Em **Ajustes**, use **Organizar botões na tela** para mover os controles, ajustar tamanho/opacidade e escolher modo canhoto. **Treino guiado** ensina movimento, câmera, salto e tiro na Vila Floral. O HUD salvo acompanha o perfil local.

Ative **Mostrar FPS e tempo dos quadros** para medir no aparelho. Após jogar, abra **Copiar diagnóstico da última partida** e cole o relatório para análise. Detalhes e limites: [mobile_primeira_entrega.md](docs/mobile_primeira_entrega.md).

## Menu e Vila Floral — 0.4.0

Navegação por toque corrigida no lobby, loja e resultados; abas fixas e cartões compactos no celular. A Vila Floral recebeu uma casa do chá atravessável, navegação por caminhos para os bots, mobiliário e ambientação sonora 3D. Ajustes incluem volumes independentes de efeitos e ambiente. [Implementação e validação](docs/fases_mobile_vila.md).

## Combate 0.5.0

Reaparecimento avalia distância dos adversários, exposição e espaço livre nas nove arenas. Bots têm campo de visão, memória limitada, investigação por sons e busca de cobertura; no Difícil, podem procurar flancos onde há navegação integrada. Passos e tiros de bots têm posição 3D. A proteção ao nascer aparece no HUD e termina ao atacar. [Implementação e limites](docs/combate_fase3.md).

## Estabilidade 0.5.1

Corrigidos comandos residuais após morte/pausa, navegação pelo botão Voltar na loja e separação das medições entre partidas repetidas. Dano tardio não altera o jogador nos menus. [Reprodução e validação](docs/revisao_estabilidade.md).

## Arsenal 0.6.0

Brisa e Flora usam modelos CC0, peças animadas e efeitos sonoros sintetizados próprios. A escopeta resolve oito projéteis por cartucho, com queda de dano pela distância e um único evento de dano/abate por vítima. Saves antigos de quatro armas migram preservando os índices originais, a carteira e os desbloqueios. Detalhes em [arsenal_fase3.md](docs/arsenal_fase3.md); visão geral de lançamento em [estado_lancamento.md](docs/estado_lancamento.md).

## Navegação 0.7.0

As nove arenas têm navegação global. Nas cinco antigas, os bots agora seguem rotas entre pisos e sobem escadas com teste da cápsula contra colisões. Foram corrigidos acessos do Porto Cobalto, Cânion Âmbar, Distrito Neon e Estação Aurora, além de spawns bloqueados. A suíte completa passou em 1.873 verificações. Detalhes e limitações em [navegacao_fase3.md](docs/navegacao_fase3.md). O APK continua sendo uma versão de teste local contra bots, sem contas, multiplayer ou compras reais.

## Tiro manual e cor 0.7.1

O jogador controla o disparo pelo botão de tiro ou mouse; mirar em inimigos não dispara mais a arma, inclusive após atualizar saves antigos. Armas automáticas atiram enquanto o botão está pressionado; pistola, sniper e escopeta respondem uma vez por toque. O botão de tiro também permite arrastar a câmera. A paleta dos pisos agora é preservada pelo shader, os telhados têm famílias de cor distintas e a Vila Floral, Docas e corridas receberam ajustes de cor. Detalhes em [tiro_manual_e_cor.md](docs/tiro_manual_e_cor.md).

## Mira mobile 0.7.2

MIRAR ficou maior e identificado, com feedback visual e vibração opcional. A mira híbrida permite tocar para manter ou segurar/arrastar até soltar; Ajustes também oferece Tocar e Segurar. Mirar enquanto corre agora abre a mira corretamente. O tiro permanece manual. Referências, controles e validação em [mira_mobile.md](docs/mira_mobile.md). O [norte criativo](docs/direcao_criativa.md) registra MicroVolts como referência de espírito arcade, preservando primeira pessoa e mapas próprios.
