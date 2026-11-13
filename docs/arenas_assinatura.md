# Bazar Solar, Docas do Festival e Observatório Lunar

Três arenas locais de combate, IDs 6–8, disponíveis no início da lista do lobby.
Continuam usando partidas de três minutos / 15 abates e seis bots com a dificuldade escolhida no lobby.

## Identidade e circulação

| Arena | Leitura visual | Estrutura de combate |
| --- | --- | --- |
| Bazar Solar | Pedra quente, reboco, cúpulas turquesa, tecidos listrados, palmeiras e pavilhão de chá | Quatro quarteirões deslocados, passagem central interrompida pelo pavilhão, cruzamentos e flancos externos |
| Docas do Festival | Veleiros, farol, madeira, armazéns, bandeirolas e carga | Dois armazéns em diagonal, corredor de carga quebrado por pilhas, mercado central e laterais do cais |
| Observatório Lunar | Módulos industriais, planetário, colunata, galerias cobertas e jardins | Centro circular com várias entradas, laboratórios opacos, rota externa coberta e bolsões de cobertura |

As casas e laboratórios são volumes fechados. Portas decorativas não abrem. Os barcos são cenário externo; não são áreas jogáveis. As rotas desta etapa ficam no mesmo nível, com subida nas coberturas baixas pelas mecânicas existentes. Não há multiplayer online nesta entrega.

## Referências de projeto

Os layouts foram escritos para este projeto. A pesquisa serviu para estudar legibilidade, risco de travessia, distâncias de combate e flancos, sem importar plantas, nomes comerciais, texturas ou modelos dos jogos citados pelo usuário.

- [Activision: Tactical Map Intel — Shipment](https://blog.activision.com/call-of-duty/2019-12/Modern-Warfare-Tactical-Map-Intel-Shipment): encontros curtos e cobertura interrompendo linhas de tiro.
- [Valve: notas de atualização de 2014, incluindo Train](https://blog.counter-strike.net/date/2014/): ajustes de passagens, visibilidade e colisão.
- [Phantom Forces, página oficial](https://www.roblox.com/games/292439477/Phantom-Forces): referência de experiência geral solicitada pelo usuário; nenhum asset foi extraído.

## Implementação

- `scripts/signature_arenas.gd`: composição original com módulos CC0, colisões, atmosfera, placas, mercado e planetário.
- `scripts/arena_navigation.gd`: AStarGrid2D com células de 1 m, margem de 0,65 m em torno das caixas sólidas e diagonais que não cortam cantos bloqueados.
- `scripts/enemy_bot.gd`: usa caminhos quando não vê o alvo, preserva reação e precisão por dificuldade e evita escolher o próprio entorno como destino de patrulha.
- `scripts/imported_scenery_batch.gd`: agrupa superfícies por material, formato de vértice e célula; descarte diferido dos meshes originais corrige encerramento nativo observado no Godot 4.7.2 durante a montagem.
- `scripts/map_postcard.gd`: usa fotografias do jogo para os novos cartões do lobby.
- `tools/prepare_arena_assets.py`: extração reproduzível da seleção CC0, licenças originais e SHA256. Downloads não entram no export.

## Validação reproduzível

```powershell
godot --headless --path . --fixed-fps 60 -- --test
godot --headless --path . --fixed-fps 60 -- --test --arenas
godot --path . -- --qa --arenas
godot --headless --path . --export-release Web build/web/index.html
```

A suíte verifica todos os pares de spawns, folga física da cápsula ao longo dos caminhos, travessia real de um bot de ponta a ponta de cada arena e limpeza da navegação ao trocar de modo. O teste focado simula 30 segundos por mapa. A suíte completa também cobre modos anteriores, controles, perfil, dificuldade, HUD e armas.

Capturas `shots/arena_{6,7,8}_{pc,mobile,hero}.png`: PC 1280×720 e janela 844×390 com controles móveis. São capturas nativas no PC, não screenshots de um telefone. Logs em `build/arenas_full_validation.log` e `build/arenas_capture_final.log`.

## Limites

Ainda é necessário jogar partidas para avaliar equilíbrio, spawn camping, vantagens de armas e qualidade dos encontros. Os testes de circulação não demonstram equilíbrio competitivo. Não há promessa de viralidade ou retenção.

O PC de captura usa uma Radeon RX 9060 XT em OpenGL Compatibility. Draw calls e memória estática registrados pelo Godot não representam FPS em celulares, nem consumo total de RAM/VRAM. Nenhum dispositivo Android/iOS foi medido nesta etapa. Exportar para Web verifica empacotamento; não substitui validação no navegador e em aparelhos reais.

## Resultado em 12/11/2026

- 700 verificações de integração + 68 de bots + 331 das novas arenas: **1.099, zero falhas**.
- Nove capturas das arenas e captura adicional do lobby.
- Draw calls em PC 1280×720, qualidade alta: Bazar 512, Docas 315, Observatório 415. Valores de um enquadramento, não benchmark de partida.
- Janela 844×390 com HUD móvel, no mesmo PC: 511 / 304 / 407 draw calls. Não é medição de celular.
- Export Web local; sem publicação.

## APK de teste — 13/11/2026

- `export/android/SakuraBlitz-0.2.0-test.apk`, 77.809.890 bytes.
- Assinatura APK v2/v3 verificada com apksigner; alinhamento de 16 KB verificado com zipalign.
- Integridade ZIP, bibliotecas ARM 32/64 bits e inclusão dos scripts das novas arenas verificadas.
- Manifesto: API mínima 24, target 36, orientação landscape, somente permissão de vibração.
- ETC2/ASTC habilitado para permitir a exportação Android; chave de debug já instalada no Godot.
- Sem instalação ou medição em telefone nesta etapa. APK e Web são artefatos locais.
