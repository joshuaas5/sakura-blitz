# Navegação dos bots — entrega 0.7.0

As nove arenas agora fornecem navegação global. Nas cinco arenas antigas, `SurfaceNavigation` constrói um grafo com alturas reais a partir dos colisores estáticos; as quatro arenas mais novas mantêm a navegação já integrada. O grafo distingue pisos sobrepostos, escadas, passarelas e o chão sob as pontes.

## Correções dos espaços

- **Vila Sakura:** pontos de nascimento foram retirados de casas e obstáculos sólidos.
- **Porto Cobalto:** escadas voltadas para os contêineres, quatro conexões entre os telhados e a passarela central, pontos de nascimento fora de contêineres fechados.
- **Cânion Âmbar:** quatro escadas ligam o chão aos flancos elevados; coberturas dos flancos deixam passagem lateral para a cápsula dos atores.
- **Distrito Neon:** a escada inferior parte da abertura central e encontra o mezanino, em vez de permanecer sob o próprio piso. O acesso ao terceiro piso usa as escadas superiores existentes.
- **Estação Aurora:** os dois mirantes foram alargados para encontrar as escadas sem deixar o vão anterior.

São alterações na geometria de colisão e nas malhas visíveis. O jogador também pode usar os acessos corrigidos.

## Movimento e custo

O grafo usa células de 0,5 m, verifica espaço para o corpo e apoio ao redor do centro da cápsula, impede conexões diagonais através de cantos e permite diferenças de altura de até 0,46 m. Piso e teto não se conectam quando não existe um acesso. Caixas e cilindros estáticos são tratados por seus limites globais, de forma conservadora.

O bot consulta o caminho com cooldown. Nas escadas, atualiza a direção a cada frame para evitar ultrapassar um degrau com a direção anterior. A assistência de degrau lê o colisor realmente tocado e testa o deslocamento da cápsula inteira para cima e para frente; teto baixo e obstáculos altos impedem a subida. Não move o ator diretamente para o próximo waypoint. Gravidade e `move_and_slide` continuam ativos.

Os cinco grafos não guardam nós de cena e são reutilizados entre rodadas. O cache tem no máximo um grafo por arena antiga. Sair do modo de combate limpa a referência ativa. A primeira construção, feita de forma síncrona no carregamento, levou aproximadamente 90–250 ms no PC de desenvolvimento; esse tempo precisa ser medido em celulares. Não se executa um bake completo por frame.

## Evidências

```powershell
godot --headless --path . --fixed-fps 60 -- --test --navigation
godot --path . --fixed-fps 60 -- --qa --navigation
godot --headless --path . --fixed-fps 60 -- --test
```

442 verificações específicas cobrem todos os pares de spawns nas cinco arenas, colisão física dos spawns, oito travessias físicas entre locais e pisos, limite de deslocamento por frame, teto baixo, parede fina entre amostras, pisos sobrepostos sem acesso, limpeza e reutilização do cache. A suíte completa passou em **1.873 verificações**, sem falhas e sem erros de script. O diagnóstico esperado de save deliberadamente corrompido faz parte do teste de recuperação.

No ensaio nativo renderizado, um bot chegou à passarela central do Porto em y = 3,30 m e ao piso superior do Distrito Neon em y = 7,25 m. Capturas reais: `shots/navigation_1_stairs.png`, `navigation_1_overview.png`, `navigation_3_stairs.png` e `navigation_3_overview.png`. São ensaios controlados de percurso, não uma avaliação de uma partida humana.

Essa cobertura não significa que todas as rotas possíveis foram testadas. Playtests de combate, refinamento da arte das arenas antigas, desempenho e ergonomia no aparelho físico seguem necessários. Multiplayer, contas e cobrança permanecem fora desta entrega.
