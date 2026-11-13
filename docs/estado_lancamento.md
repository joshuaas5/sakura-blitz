# Estado atual — candidato offline de tiro

Referência: 13/11/2026, código na branch `codex/mobile-foundation`, versão de teste 0.9.0. O escopo vigente exclui multiplayer, contas online e cobranças. O parkour existente foi preservado; a produção está concentrada no FPS. O APK de teste 0.9.0 foi solicitado para esta entrega, com verificação de assinatura, manifesto e alinhamento.

## Entregue e integrado

- Onze arenas de tiro, com mapas compactos, verticais e dois distritos grandes. Todos usam a navegação correspondente à geometria de colisão. Vila Sakura, Porto, Cânion, Neon e Aurora receberam reconstruções; os demais mapas têm módulos, mobiliário e paisagismo próprios.
- Cada um por si, equipes e captura de bandeira locais, sem fogo amigo. População por mapa, três dificuldades e opções de 12/18/24 bots nos grandes em FFA; em equipes, a contagem inclui o jogador para formar lados iguais.
- Seis armas disponíveis desde o início, disparo manual, mira tátil com modos selecionáveis, assistência limitada, recarga, inspeção, cosméticos e maestria local.
- Bots com percepção, memória, audição, cobertura/flancos, papéis de rifle/precisão/SMG, aviso de disparo de precisão e recargas finitas. As armas importadas são agrupadas na malha articulada da mão. Os bots percorrem escadas e transportam bandeiras.
- Lobby rolável com navegação fixa; tutorial com alvo físico importado; pausa/retomada e tratamento de interrupções; HUD editável e modo canhoto; placar tátil; abertura de partida e resultados roláveis com ações sempre visíveis.
- Perfil com backup, desafios e recompensas por desempenho; moedas exclusivamente locais. Nenhuma integração de pagamento ou multiplayer foi acrescentada.
- Suprimentos, coletas, impulsos, alvos, projéteis e veículos com modelos/sprites licenciados; impactos reutilizáveis; música sintetizada original e áudio espacial.

## Validação concluída no PC

Suíte completa no Godot 4.7.2: **6.059 verificações, zero falhas**. Inclui 448 verificações e percursos físicos das arenas com andares, 3.720 nas arenas grandes e 355 de equipes/bandeiras. O carregamento de todos os mapas, armas, salvamento/recuperação e gestos de toque no lobby, ajustes e resultados também foi exercitado.

O treino foi verificado com um disparo real do sistema de armas contra o alvo físico. Acertar um bot fora do exercício não conclui o tutorial. As recargas de NPCs foram verificadas pela simulação, incluindo bloqueio de tiros e congelamento durante pausa. Os 11 mapas foram exercitados com transporte físico de bandeira por bot até captura por proximidade.

Capturas nativas em 1280×720 e 844×390, com qualidade alta e leve, estão em `shots/offline_*`; os mapas grandes e o HUD de equipes em `shots/large_*` e `shots/teams_*`. São imagens reais do jogo. Os logs detalhados permanecem em `build/polish_full_validation.log` e `build/polish_render_final.log`. Os diagnósticos deliberados de save corrompido e caminho de gravação inválido são parte dos testes de recuperação.

## O que impede chamar isto de lançamento validado

A validação automatizada no PC não comprova diversão, balanceamento humano nem desempenho Android. Falta jogar no aparelho físico: abrir/rolar o lobby, mirar e atirar com dois polegares, completar partidas, suspender/retomar, verificar áudio, aquecimento, memória e FPS. Nenhum aparelho foi validado nesta entrega. Não existe promessa comprovada de 60 FPS em celulares de entrada.

Depois dessa sessão, devem ser corrigidos os problemas observados e ajustados dificuldade, tempos de confronto e recompensas. Preparação de distribuição comercial é uma etapa separada. Multiplayer e compras ficam fora do trabalho atual por decisão do usuário.

O lote 0.9.0 reduz desenhos no Vale do Chá e no modo leve do Terminal, guarda geometria do minimapa em cache, reutiliza efeitos e refina recuo, troca, alcance e rajadas. As medições e o custo adicional de arte na qualidade alta estão registrados em [polimento_offline_090.md](polimento_offline_090.md).
