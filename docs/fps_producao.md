# Produção do modo tiro

## Direção vigente

Priorizar criação, conteúdo e acabamento do FPS. Parkour existente permanece disponível, com expansão adiada. A pedido do usuário, a bateria de testes fica após a implementação em lote; novos APKs dependem de novo pedido. O último instalador publicado continua sendo o 0.8.0.

## Arenas e populações

| Arenas | Cada um por si | Equipes / bandeira, incluindo você |
| --- | --- | --- |
| Vila Sakura e Porto Cobalto | 6 bots | 3 × 3 |
| Cânion, Neon, Estação, Vila Floral, Bazar, Docas e Observatório | 8 bots | 4 × 4 |
| Vale do Chá e Terminal Girassol | 18 bots por padrão; 12/18/24 selecionáveis | 9 × 9 por padrão; 6×6, 9×9 ou 12×12 |

Vale do Chá: 96 × 88 m, nove setores, casas de chá atravessáveis, pavilhão central, estufas, fonte, bosques, pergolado, mercados, bancos e portais. Terminal Girassol: 112 × 76 m, seis setores, quatro oficinas com interiores, quatro bondes, plataforma coberta, bilheterias, carrinhos, carga, guindastes e relógio de fachada animado por shader. Cada mapa tem aproximadamente 5,9 vezes a área de combate nominal do Porto (38 × 38 m); personagens e construções mantêm sua escala.

Os dois mapas recebem rotas de navegação com limites próprios, pontos de patrulha e trinta candidatos de entrada, contando o jogador. Pintura das peças próprias usa cores de vértice e agrupamento espacial. Personagens distantes usam uma malha única compartilhada por família visual, mantendo colisão e IA; a percepção é distribuída entre frames em partidas cheias.

## Partidas

- Cada um por si mantém pontuação individual, com limite de 15 abates nas antigas e 20 nas grandes.
- Equipes Menta e Coral pontuam por eliminações adversárias, até 40 nas antigas ou 60 nas grandes. O jogador pertence à Menta; o número de bots é ajustado para lados iguais.
- Captura de Bandeira exige trazer a adversária para a base enquanto a própria estiver em casa. Captura por proximidade, queda ao morrer, recuperação por aliado, retorno automático em 25 segundos e meta de três capturas. Bots transportam, escoltam e recuperam bandeiras. Eliminações não contam como capturas.
- O jogador recebe moedas e progressão por capturas; participação em objetivos também permite a recompensa de conclusão, mesmo sem abates.
- Sem dano aliado: proteção na origem do dano, seleção de alvos da IA, projéteis e assistência de mira. Identificação por cores e diamantes sobre os personagens.
- Entrada por metade do mapa nos modos de equipe, com escolha de pontos contra adversários. Lotação alta respawna bots mais rapidamente.

## Apresentação

Lobby abre em tiro e separa modo, dificuldade e lotação. HUD mostra placar real dos times, meta, setor e orientação de bandeira com distância e indicação fora da tela. Tab ou toque no placar abre a classificação com colunas separadas, abates, mortes e capturas, mantendo a partida em andamento. N troca de arena.

Indicador direcional de dano, ícones separados de tiro e munição, metal e laca com acabamento refinado, bandeiras animadas e relógio de fachada. O resultado usa a vitória da equipe, inclui empates e exibe os dois lados.

## Lote de acabamento: Cânion, combate e itens

O Cânion Âmbar foi reconstruído com rochas estratificadas, mirantes cobertos, ponte de madeira, postos botânicos, riacho e cenário externo. A ponte, os acessos e os três níveis de combate continuam conectados. Abertura de três segundos com instruções do modo e número de jogadores; jogadores e bots aguardam a mesma fase de preparação, sem gastar tempo da partida.

Bots de assalto, precisão e avanço usam intervalos, alcance preferido, dano e áudio diferentes. O atirador de precisão sinaliza o disparo antes de atirar. Impactos de superfície usam um conjunto reutilizável de 32 marcas; disparos não criam cubos novos a cada colisão.

Resultados com ações fixas, classificação expansível, acertos por cartucho, melhor sequência, capturas, ganhos da sessão e progresso real de maestria. Gastos na loja não diminuem o total exibido como ganho da partida.

### Arte de itens obrigatória

Requisito do usuário: nenhum item novo com arte provisória. Os pontos de suprimento que usavam uma arma feita de blocos foram substituídos por estações com estojo, carregadores, coração, sprites e indicação de reposição. Os cubos de coleta viraram estojos de campo com arte importada; discos de impulso foram trocados por botões modelados. Projéteis usam o modelo de dardo do pack. O estande de treino tem um alvo importado, com posição física e área de acerto correspondentes. A reprise usa o mesmo avatar acabado do jogo.

Blaster Kit 2.1 e seleção de itens do Platformer Kit 1.1, publicados pelo Kenney e baixados das páginas do autor no OpenGameArt. Originais, sprites, atlas, licenças CC0 e hashes acompanham os assets. `ItemArt` centraliza o catálogo: não gera cubos substitutos quando falta arte. `SupplyStation` preserva seus modelos e animação no agrupamento do cenário. Licenças incluídas nos presets de export, sem gerar APK nesta etapa.

Revisão visual nativa e captura dos componentes realizadas. Os 442 percursos e verificações de navegação passaram após a reconstrução do Cânion. A revisão geral foi concluída no fechamento offline descrito abaixo.

## Fechamento offline — Vila, Neon e Aurora

Vila Sakura recebe fachadas modulares com portas, janelas, trepadeiras, terraços de madeira, veículos do Car Kit e escadas com patamares. Duas aproximações opostas permitem que os bots subam aos terraços sem teletransporte; caixas mantêm atalhos de salto para o jogador. O limite de cenário é arquitetura visível de 6,5 m, acima dos telhados acessíveis.

Distrito Neon passa a ser um átrio tecnológico de três níveis: módulos Sci-Fi, pilares, painéis, guarda-corpos, jardim suspenso e faixas de cor por andar. As peças planas ficam sobre o piso físico, e a largura dos módulos segue seu eixo original. Caixas de cobertura foram afastadas dos pontos de entrada. Estação Aurora usa vagões e trilhos do Train Kit, plataformas cobertas, passarelas e escadas, fachadas de estação, relógios e sinalização. Os quatro bondes do Terminal Girassol também usam vagões importados. Car Kit 3.1 e Train Kit 1.0 são seleções CC0, com originais, atlas e hashes preservados.

NPCs usam armas importadas por classe, agrupadas na malha articulada da mão, mantendo o orçamento de desenhos do personagem. Rifles, armas de precisão e SMGs têm carregadores e tempos de recarga próprios; sem munição, não disparam. No Médio/Difícil, podem buscar cobertura durante a recarga; os objetivos de bandeira mantêm prioridade.

A revisão consolidada terminou com **6.050 verificações, zero falhas**. Inclui controles e menus por toque, tutorial com tiro real, recargas, perfil, arsenal, navegação, mapas grandes e captura física por bots nas 11 arenas. Uma bancada no Vale foi deslocada para liberar uma entrada/patrulha. Há capturas reais do jogo em `shots/offline_*`, incluindo PC, celular e modelos de NPCs, e novas miniaturas das três arenas no lobby.

Multiplayer e compras foram excluídos do escopo vigente; não foi gerado novo APK. O ciclo offline está integrado para avaliação humana. Ainda é necessário teste em celular e sessões humanas para medir ergonomia, desempenho e equilíbrio; a suíte no PC não comprova esses aspectos. Estado consolidado em `docs/estado_lancamento.md`.
