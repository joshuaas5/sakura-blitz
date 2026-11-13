# Direção cozy: primeira integração jogável

> Registro da primeira iteração. HUD, armas e a arena Vila Floral foram posteriormente substituídos pelo [rework Atelier](rework_atelier.md).

As pranchas em `docs/concepts/hud-personagens/` orientam a direção de arte. Esta integração substitui o HUD e os antigos corpos dos bots por componentes reais em Godot. Ainda existe diferença entre a riqueza das ilustrações e a densidade dos cenários jogáveis; as pranchas não são screenshots do jogo.

## Implementado

- `BlossomHud`: desenho vetorial com ícones de salto, tiro, mira, recarga, troca, checkpoint, pausa, vida e escudo; botões circulares, estados pressionados e progresso de recarga.
- PC e mobile compartilham indicadores, mas PC usa dicas de teclado e placar; mobile usa analógico e áreas de toque. Parkour omite armas, vida e munição. Saldo e loja ficam nos menus.
- Minimap esquemático produzido das colisões reais, com localização e orientação do jogador. Não exibe adversários através de paredes. Não é uma imagem de mapa pré-desenhada.
- Corrida exibe posição provisória baseada no avanço longitudinal, tempo e oito checkpoints. A posição final continua determinada pela chegada. Combate mantém o modo individual existente, com meta de 15 abates; não há placar falso de equipes.
- `CozyAvatar`: três famílias de aventureiros com articulação, rosto, cabelo, cachecol, bolsa, broche, botas, capa e óculos. Explorador Imperial é uma variação de catálogo. Os cosméticos de primeira pessoa receberam as mesmas paletas.
- Os detalhes são combinados em uma malha com cores por vértice por articulação. Os seis conjuntos animados compartilham material, evitando uma chamada de desenho por peça de roupa.
- `CozyPortrait`: loja e cabeçalho do lobby renderizam os modelos reais uma vez, atualizando ao redimensionar. Sem simular outra partida nos cartões.
- Cenário: módulos com vigas e floreiras, flores e trepadeiras, copas com mais volumes, bases de pedra sob plataformas, detalhes nos jardins e piso pintado. A textura é limitada a 512 px na importação, com mipmaps.

## Conferência

`--qa` agora também gera `foundation_phone_combat.png`, `foundation_pc_hud.png`, `foundation_avatar_lineup.png` e `foundation_costume_shop.png`, além das capturas anteriores. São imagens do Godot nativo, incluindo simulação de tamanhos de tela, e não fotografias de celulares reais.

`--test` preserva as verificações de toque, colisões, economia, persistência, percursos completos e bots. A reconstrução dos modelos não altera cápsulas físicas, atributos ou tempos de reação. A orientação dos corredores foi ajustada para os novos modelos voltados para +Z.

## Trabalho artístico ainda necessário

Refinar anatomia, expressões e animações; enriquecer materiais de roupa e arquitetura; ajustar a densidade do cenário e cada composição de câmera; substituir o restante das artes antigas da loja; playtests em celular para ergonomia, legibilidade, aquecimento e desempenho. O visual atual é a primeira versão implementada da direção aprovada, não uma reprodução final das pranchas.
