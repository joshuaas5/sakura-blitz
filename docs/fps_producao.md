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

## Validação pendente do lote

Antes da última ampliação de cenário e HUD, houve verificações focadas de equipes e bandeiras, incluindo transporte físico por bots; percursos das arenas grandes também foram exercitados. A primeira suíte geral detectou uma expectativa antiga de seis bots na Estação, atualizada para oito. A suíte geral final ainda não foi repetida após o lote mais recente, por orientação do usuário. Não tratar esta produção como release validada.

Continuam pendentes testes humanos de diversão e equilíbrio, medição em celular, multiplayer online, contas, cobrança e preparação de produção. A implementação atual é local contra bots.
