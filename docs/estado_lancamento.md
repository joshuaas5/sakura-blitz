# Estado atual para lançamento

Referência da implementação local 0.7.1. Os relatórios antigos descrevem as entregas de suas respectivas datas.

| Frente | Implementado localmente | Trabalho necessário antes de lançamento comercial |
| --- | --- | --- |
| Entrada e mobile | Lobby rolável, toque nativo, editor do HUD, tiro manual com arraste, tutorial de combate, pausa e retomada | Teste em aparelhos físicos, interrupções do Android, ergonomia e tutorial específico de corrida |
| Conteúdo | Nove arenas e seis corridas de oito setores; resultados e recordes | Playtests de fluxo, legibilidade, pontos de bloqueio e diversão em cada mapa |
| Combate | Seis armas, recargas, skins, maestria, colisão e som espacial | Balanceamento humano, acessibilidade da mira e evolução da IA com o arsenal |
| Bots | Fácil/Médio/Difícil, percepção, memória, som, cobertura e flancos | Navegação global nas nove arenas, com pisos e escadas nas cinco antigas; ampliar rotas testadas e sessões humanas prolongadas |
| Arte | Vila Floral com módulos CC0, Bazar/Docas/Observatório, personagens e armas com prévias 3D | Igualar qualidade dos mapas antigos, revisar densidade e silhuetas com orçamento mobile |
| Desempenho | Qualidade leve padrão, agrupamento de geometria, descarte por mapa e diagnóstico de frames | Medir FPS, memória total, aquecimento e bateria em dispositivos de entrada; corrigir gargalos medidos |
| Progressão | Perfil local com backup, moedas por desempenho, desafio diário, equipamentos e maestria | Backend autoritativo, migração de dados e recuperação de conta para economia online |
| Multiplayer | Não implementado | Servidor autoritativo, sessões, sincronização, matchmaking, desconexões e infraestrutura |
| Receita | Loja usando moeda local de jogo; não cobra dinheiro | Catálogo, integração de cobrança, validação de recibos, restauração e tratamento de falhas |
| Publicação | APK de teste local, testes automatizados e workflow web | Chave de produção, testes externos, pacote de loja, privacidade, classificação e operação |

## Ordem do trabalho

1. Fechar o ciclo offline em aparelho real: abrir, rolar lobby, equipar, jogar, pausar, terminar e voltar. Medir antes de definir promessa de desempenho.
2. Refinar a qualidade visual das arenas antigas e ampliar os playtests de navegação. Ajustar armas e dificuldades por partidas humanas, com atenção ao começo do jogo.
3. Implementar e validar uma partida online mínima, com autoridade do servidor, antes de expandir matchmaking e ranking.
4. Integrar conta e progressão ao servidor. Somente então conectar compras e recibos à economia persistente.
5. Preparar produção e distribuição, testar reinstalação/atualização, falhas de conexão e operação.

As validações automatizadas verificam invariantes e fluxos; não substituem testes humanos de diversão, equilíbrio ou qualidade visual. O desempenho desta implementação ainda não foi medido em aparelho físico. A versão 0.7.0 foi publicada como prévia de teste no GitHub. Não houve compra de asset ou cobrança real.
