# Música sintetizada para Sakura Blitz

Estas faixas foram criadas nesta implementação por síntese de osciladores e ruído, com sequências de notas escritas em `tools/compose_music.py`. Não foram usados samples, gravações, arquivos MIDI ou melodias extraídas de músicas de terceiros.

| Faixa | Uso | Duração aproximada |
| --- | --- | --- |
| bloom_lobby.wav | Lobby e menus | 46,8 s |
| petal_dash.wav | Corridas | 31,0 s |
| neon_skirmish.wav | Combate | 34,3 s |

PCM mono, 22.050 Hz, 16 bits; loops com caudas sobrepostas ao início. As três faixas têm pico normalizado a 0,72. O menu permite desativar música e ajustar seu volume.

Para reproduzir os arquivos, instale NumPy no ambiente Python e execute `python tools/compose_music.py`. O gerador faz parte do projeto e permite modificar os arranjos.

## Ambientes da Vila Floral

`courtyard_water.wav` e `garden_breeze.wav`: loops mono de 8 segundos, 22.050 Hz/16 bits, criados por síntese determinística de ruído filtrado e modulação em `tools/compose_ambience.py`. Não usam gravações externas. São reproduzidos em emissores 3D da praça e do jardim, com volume independente e atenuação pela distância. Para regenerar: `python tools/compose_ambience.py` (biblioteca padrão do Python).

## Movimento

`step_stone.wav`, `step_wood.wav` e `land_soft.wav`: sinais mono de 0,14 / 0,18 / 0,24 segundo, a 22.050 Hz e 16 bits. Síntese de ruído filtrado e osciladores amortecidos, sem samples ou gravações externas, em `tools/compose_combat_audio.py`. São usados no pool espacial de efeitos do mapa. Para regenerar: `python tools/compose_combat_audio.py` (biblioteca padrão do Python).

Os antigos `bgm_sakura.wav` e `bgm_panadero.wav` permanecem no checkout, mas não são carregados pelo jogo e foram excluídos do export web. Esta nota documenta o processo de criação das novas faixas; não certifica a procedência de todos os demais assets herdados do protótipo.

## Arsenal Brisa e Flora

`brisa_shoot.wav` (0,115 s) e `flora_shoot.wav` (0,38 s) foram sintetizados com osciladores amortecidos e ruído determinístico por `tools/compose_weapon_audio.py`. PCM mono, 22.050 Hz/16 bits, pico 0,78; sem samples externos. O primeiro é um disparo curto e seco, o segundo tem corpo grave e cauda mais longa. Carregados no bus Effects, respeitam volume e silenciador. Regenerar: `python tools/compose_weapon_audio.py`.
