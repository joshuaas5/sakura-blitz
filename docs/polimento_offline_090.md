# Polimento offline — 0.9.0-test

## Renderização e custo por partida

O agrupamento do cenário passa a reconhecer materiais StandardMaterial3D equivalentes pelas propriedades de renderização, preservando textura, UV, transparência, relevo e emissão. A cor base é incorporada aos vértices. Cada lote tem origem no próprio setor, permitindo descarte por distância coerente; flores e trepadeiras têm distância menor no modo leve, sem retirar paredes, cobertura ou colisão.

As peças rígidas das mãos e armas são agrupadas dentro de cada junta animada e papel cosmético. Carregadores, ferrolhos, mãos, pingentes e acessórios continuam separados por suas articulações; skins continuam editáveis. O minimapa guarda os polígonos estáticos recortados por arena e atualiza os marcadores sem repetir recortes geométricos em cada frame.

Sons fora do alcance audível não consultam oclusão; a audição dos bots rejeita primeiro fontes fora de alcance. Impactos usam um pool fixo de 96 sprites em MultiMesh, além das 32 marcas de superfície existentes, evitando criar uma malha para cada fragmento de um acerto.

Comparação nativa em 844×390, mesma câmera e bots pausados; inclui o HUD e o novo acabamento de cenário:

| Cena | Antes: chamadas de desenho | Depois | Variação |
| --- | ---: | ---: | ---: |
| Vale do Chá, leve | 671 | 575 | −14,3% |
| Vale do Chá, alta | 1.017 | 857 | −15,7% |
| Terminal Girassol, leve | 554 | 544 | −1,8% |
| Terminal Girassol, alta | 603 | 622 | +3,2% |

O acréscimo de fachadas e bandeirolas no Terminal consome parte do ganho: a qualidade alta tem mais desenhos que antes. Estas são medições do renderizador no PC, não FPS ou memória total de um celular. Os logs estão em `build/polish_render_before.log` e `build/polish_render_final.log`. O custo ainda exige medição em Android.

## Apresentação, combate e ritmo

Os distritos recebem bandeirolas com emblemas próprios de folhas e sol, movimento discreto do tecido e materiais compartilhados. As oficinas do Terminal ganham portais e painéis modulares Sci-Fi. Não foram acrescentadas luzes pontuais ou colisões decorativas aos caminhos.

O HUD distingue acerto, headshot e eliminação por forma, cor e duração do marcador. O recuo da câmera devolve suavemente 40% do impulso vertical depois da rajada, com recuperação acumulada limitada a 0,08 rad; o restante exige controle do jogador. Pausa, morte e partida nova limpam o retorno pendente. O disparo continua manual.

A troca de arma tem duração por classe: pistola 0,26 s, SMG 0,29 s, fuzil 0,34 s, escopeta 0,40 s, faca 0,45 s e precisão 0,48 s. A arma fica pronta após 65% da animação; trocar não permite disparo imediato durante o saque. Uma nova vida limpa recarga e cooldown residuais.

Fuzil, pistola e precisão agora têm queda de dano por distância. Fuzil: 42 até 24 m, caindo a 24 aos 65 m; pistola: 58 até 14 m, caindo a 26 aos 40 m; precisão: 140 até 60 m, caindo a 85 aos 110 m. SMG e escopeta preservam suas curvas próprias. Bots de fuzil e SMG fazem rajadas de três e cinco tiros com pausas graduadas pela dificuldade, além das recargas. Os ajustes são uma base para playtest humano, sem alegação de balanceamento concluído.

## Verificação e APK

Suíte completa no Godot nativo: 6.059 verificações, zero falhas. Os testes adicionais exercitam equivalência e separação de materiais, preservação da posição e das cores do cenário, cache do minimapa, limite/expiração dos efeitos, prontidão após troca e limpeza de recarga. A navegação e o transporte físico de bandeiras nas 11 arenas continuam na suíte.

APK de teste solicitado: `export/android/SakuraBlitz-0.9.0-test.apk`, código 11, mesmo pacote e assinatura de depuração usados anteriormente. A rotina de export verifica assinatura, alinhamento de 16 KB, manifesto e SHA256. Não houve multiplayer ou compras reais neste lote. O jogo permanece offline e ainda precisa de avaliação humana em celular para desempenho, aquecimento e ergonomia.
