# Fase 3 — reaparecimento, percepção e áudio

Entrega local Android `0.5.0-test` / versionCode 4. Mantém o mesmo pacote e chave de teste das versões anteriores.

## Reaparecimento

`SpawnDirector` avalia os pontos já definidos em cada mapa: chão, folga da cápsula, distância dos adversários, exposição por linha de visão e uso recente. Remove o deslocamento aleatório que podia empurrar bots para obstáculos. Os candidatos são verificados fisicamente após o primeiro tick do mapa; no carregamento inicial, os bots continuam confirmando chão e espaço no primeiro tick próprio.

O jogador deixa de reaparecer sempre no ponto inicial. Posição do mundo e câmera são atualizadas junto com o corpo; a câmera se volta para o centro. A proteção inicial existente é mostrada no HUD e termina ao executar um ataque válido, incluindo arma branca. Um gatilho rejeitado por cooldown não encerra a proteção.

É uma classificação de risco, não garantia de invulnerabilidade ou equilíbrio: se todos os pontos estiverem pressionados, ainda é preciso escolher entre eles. Se não houver candidato físico válido, o ponto original é o fallback. Os testes encontraram candidatos válidos nas nove arenas.

## Bots

- Campo de visão frontal e verificação de obstáculos para adquirir um alvo.
- Memória da última observação com duração limitada por dificuldade. Um adversário escondido não atualiza continuamente essa posição.
- Tiros e passos do jogador geram pistas sonoras; o bot investiga a posição do evento, sem ganhar um alvo visível automaticamente. Paredes reduzem o alcance dessas pistas; silenciador reduz a pista do disparo.
- Fácil mantém comportamento simples. Médio e Difícil podem buscar uma posição que bloqueie a linha de visão do adversário quando feridos.
- Difícil pode tentar uma aproximação lateral à última observação nas arenas com navegação global integrada.
- Consultas de cobertura limitadas a quatro obstáculos próximos por decisão, com cooldown; evita varredura de toda a cena a cada frame.

As decisões são verificadas contra geometria real. Flancos usam o caminho existente. Na entrega inicial, a navegação global atendia Vila Floral, Bazar, Docas e Observatório. A entrega 0.7.0 acrescentou navegação com pisos e escadas nas cinco arenas antigas, descrita em `navegacao_fase3.md`. O arsenal foi ampliado na entrega 0.6.0, documentada em `arsenal_fase3.md`.

## Som

O SubViewport do mundo agora tem escuta 3D habilitada. `CombatAudio` mantém um pool fixo de 16 emissores por mapa, no bus Effects, com distância máxima de 45 m. Tiros dos bots e passos têm posição; um obstáculo entre fonte e jogador reduz o volume na emissão. Passos do jogador alternam pedra/madeira no cais e na casa do chá; uma descida seguida de contato com o chão solicita som de aterrissagem.

`step_stone.wav`, `step_wood.wav` e `land_soft.wav` são sons curtos sintetizados por `tools/compose_combat_audio.py`, sem gravações externas. A percepção dos bots é uma regra de gameplay e independe do volume escolhido pelo usuário.

## Validação

```powershell
godot --headless --path . --fixed-fps 60 -- --test
godot --headless --path . --fixed-fps 60 -- --test --combat
godot --path . -- --qa --combat
./tools/build_android_test.ps1
```

83 verificações novas de combate, incluindo chão/cápsula nas nove arenas, preferência por spawn encoberto, rejeição de spawn bloqueado, campo de visão, memória que expira, investigação por som, cobertura e flanco percorridos fisicamente, mixer 3D, atenuação por parede, pool de áudio, descida/aterrissagem e proteção encerrada ao atacar.

A soma com as suítes anteriores é 1.379 verificações. Logs de regressão: `build/combat_release_validation.log`. Mensagens marcadas EXPECTED DIAGNOSTIC correspondem aos testes deliberados de perfil corrompido e escrita impossível.

QA nativa em PC: uma simulação de aproximadamente 10 segundos registrou 10 abates creditados aos bots e duas mortes do personagem parado. É uma amostra de funcionamento; não mede dificuldade para um jogador, equilíbrio de armas ou retenção. Capturas em `shots/combat_*.png`.

Continua necessário testar instalação, toque, áudio com fones, FPS e aquecimento no telefone. O APK anterior ainda não havia sido testado pelo usuário no início desta entrega. Não houve publicação, implementação de multiplayer, contas ou cobrança.
