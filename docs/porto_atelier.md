# Porto Cobalto — revisão 0.8.0

A arena antiga usava caixas lisas, escadas de blocos e um perímetro fechado sem relação com o tema. O rework mantém sete contêineres de combate, spawns e as rotas principais, acrescentando estrutura e contexto industrial.

## Implementação

- Contêineres próprios com corrugação, cantos reforçados, portas, travas, costuras e identificação. Quatro continuam atravessáveis; três permanecem coberturas fechadas.
- Passarelas de aço com placas procedurais, pilares, bases, guarda-corpos e escadas com marcação de degrau. Os elementos sólidos têm colisão correspondente e entram no grafo de navegação.
- Cerca vazada sobre mureta com o perímetro sólido anterior. Guindastes, armazéns, carga e equipamentos formam um cenário externo decorativo. O exterior não é uma nova área jogável.
- Factory Kit 3.0 do Kenney, CC0, com arquivos originais, licença e hashes de origem. Sem compra de assets.
- Mar animado por shader, horizonte marítimo e iluminação diurna. Som ambiente de ondas e passos metálicos nas superfícies elevadas, sintetizados no projeto e sujeitos aos volumes existentes.
- Pintura das malhas próprias em cores de vértice e agrupamento espacial por material. Modelos importados mantêm proporções uniformes. Nenhuma luz pontual dinâmica nova. O preset leve continua sem sombras direcionais.

## Verificação

`--test --harbor` verifica interiores, cobertura fechada, passagem sob a passarela, cerca, guarda-corpo, ausência de colisores no cenário externo, agrupamento da pintura, qualidade, áudio e descarte ao mudar de mapa. `--test --navigation` verifica percursos entre spawns e movimentação física de bots, incluindo subida e descida no Porto.

Capturas reais, sem composição ou retoque: `--qa --harbor`, arquivos `shots/harbor_after_*.png`. Os arquivos `harbor_before_*` foram capturados antes de substituir a construção antiga. O parâmetro `--before` só muda o prefixo da captura; não restaura uma implementação anterior.

Métricas nativas em PC, AMD Radeon RX 9060 XT, Godot Compatibility: a vista geral foi de 274 para 159 chamadas entre a primeira montagem detalhada e a revisão agrupada; a vista de combate mobile leve, de 368 para 326. São medidas de chamadas de desenho, não de FPS em Android. O cenário adicional aumenta o trabalho em relação à arena original simples.

A suíte completa passou em 1.933 verificações. Após acrescentar os pilares finais, os 442 testes de navegação e os 19 testes do Porto foram repetidos, sem falhas; as capturas também foram regeneradas.

## Ainda falta

Medir FPS, memória total, bateria e aquecimento em celulares de entrada. Avaliar alturas, contraste, cercas e rotas com jogadores humanos. As outras arenas antigas e as corridas ainda precisam da mesma revisão de arte; personagens, armas, animações e HUD também têm espaço para acabamento. Multiplayer online, contas e pagamentos continuam ausentes.
