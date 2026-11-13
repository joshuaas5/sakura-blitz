# Expansão local: lobby, bots e conteúdo mobile

## Entrega implementada

O projeto passou de quatro arenas e quatro maratonas para seis arenas e seis percursos reconstruídos em oito setores. As corridas oferecem uma rota acessível contínua e atalhos com obstáculos. Sete bots competem fisicamente, saltam, caem e retornam a seus checkpoints; a classificação depende da chegada real.

O lobby reúne seleção de modo, mapa e dificuldade, ajustes, loja, maestria e desafio diário. Abrir menus pausa a simulação. Retrato mostra o lobby e solicita girar o aparelho antes de jogar. A HUD usa áreas independentes por dedo, evitando que soltar o analógico cancele o pulo ou o tiro.

As duas arenas novas são Estação Aurora, com trilhos, trens e passarelas, e Jardim de Vidro, com estufa, jardins e mirantes. Os percursos usam temas, obstáculos e props próprios. Corredores receberam silhuetas arredondadas, rostos e acessórios. Armas receberam padrões de acabamento e silenciadores cosméticos.

## IA e competição

| Parâmetro | Fácil | Médio | Difícil |
| --- | --- | --- | --- |
| Reação inicial | 0,95 s | 0,52 s | 0,24 s |
| Intervalo de tiro | 1,15 s | 0,72 s | 0,42 s |
| Dispersão relativa | 1,25 | 0,60 | 0,23 |
| Velocidade base na corrida | 5,2 | 6,0 | 6,7 |
| Vida | 100 | 100 | 100 |

O combate usa percepção por linha de visão, memória da última posição, patrulha, deslocamentos laterais e recuo com pouca vida no nível Difícil. Paredes bloqueiam projéteis. Abates entre bots não dão moedas nem maestria ao jogador. O antigo placar aleatório foi removido.

É uma IA local por estados e sondas de colisão. Ainda exige sessões humanas para ajustar justiça, leitura visual, flancos e capacidade de sair de cantos em todas as arenas; não é um sistema completo de navegação tática em malha.

## Progressão e economia

O perfil salva moedas, níveis, cosméticos, dificuldade, música, sensibilidade, recordes e maestria. Usa escrita temporária e backup. Os testes não acessam o perfil real.

Ouro exige 50 abates com a arma; silenciador cosmético exige 100 abates nas armas de fogo. Skins não modificam velocidade ou dano. Upgrades custam moedas obtidas jogando e concedem +1% de dano por nível adicional, com teto de +3%. Corridas não recebem bônus de velocidade por equipamento.

O desafio diário exige dez abates OU uma corrida terminada e paga 300 moedas uma vez por dia UTC. Anéis só pagam uma vez por tentativa, checkpoints seguem ordem e o prêmio de conclusão é processado uma vez. Atalhos de teclado só alternam cosméticos já adquiridos.

Ainda não há dinheiro real, anúncios, passe pago, caixas pagas, autenticação ou backend. Para monetizar, uma próxima entrega pode usar compra direta de conjuntos visuais, passes com recompensas conhecidas e salas privadas. Catálogo, preço e recibos devem ser integrados a um backend antes de vender; saves locais são editáveis e não servem como autoridade de uma economia online.

## Desempenho e validação

Props decorativos usam MultiMesh por setor, e caixas estáticas compartilham malhas/materiais. Recursos GLTF agora são PackedScenes importados. Limpar um mapa também limpa seus props, evitando mistura de cenários e crescimento de nós entre partidas. Materiais de armas são reutilizados. Há presets de resolução para aparelhos distintos.

A suíte cobre persistência, recuperação de backup, recompensas únicas, toque, pausa, subida em obstáculos com teto, pisos e saltos reais nos 48 setores, troca repetida dos 12 mapas, níveis dos bots, projéteis contra paredes, resultados de combate e corridas autônomas completas. Nos ensaios locais, quatro bots Difíceis terminaram cada mapa entre 48,8 e 55,2 segundos; Fácil e Médio concluíram o primeiro em 69,4 e 65,6 segundos. Esses tempos são evidência de navegação, não avaliação humana de diversão.

QA nativa renderizada em AMD Radeon RX 9060 XT, com capturas de lobby, seis corridas, três arenas, loja, maestria, resultados e layouts 540×960/844×390. Nas capturas da primeira medição, o contador variou aproximadamente entre 200 e 620 draw calls; a Vila Sakura segue sendo um alvo de otimização. O monitor de memória estática do Godot indicou aproximadamente 64–69 MiB, mas não representa RAM total do processo, memória de GPU ou consumo web.

Exportação web validada pelo Godot. Teste interativo no navegador pendente: o acesso ao navegador não estava disponível nesta sessão. 60 FPS, bateria, aquecimento, multitouch e recuperação após trocar de aplicativo precisam de testes em Android/iPhone reais.

## Pendências para um lançamento comercial

1. Playtests em aparelhos de entrada e intermediários; ajustar câmera, percurso, dificuldade e duração com jogadores reais.
2. Servidor autoritativo, salas, sincronização, reconexão, contas e proteção de placares/economia.
3. Pipeline de loja e recibos, catálogo final de cosméticos e identidade visual própria consistente.
4. Revisão de procedência dos assets herdados: não há arquivos de licença junto aos modelos na pasta Kenney deste checkout. As novas músicas têm gerador e procedência documentados; isso não resolve automaticamente a auditoria do acervo antigo.
5. Mais animações, variação de rotas, opções de acessibilidade e mixagem de áudio após testes de uso.

O relatório anterior em `relatorio_diagnostico_lancamento_sakura_blitz.md` permanece como registro histórico. Esta nota descreve a expansão local; nenhum deploy foi realizado nesta etapa.
