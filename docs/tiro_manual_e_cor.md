# Tiro manual e identidade de cor — 0.7.1

## Controle do disparo

Mirar em um adversário não solicita mais um disparo. O pedido de tiro vem exclusivamente do botão do mouse ou do toque no botão ATIRAR. Armas automáticas continuam disparando enquanto pressionadas; sniper, pistola e escopeta disparam uma vez por toque. Arrastar a partir do botão de tiro controla a câmera com o mesmo dedo, mantendo o analógico livre para o outro polegar.

O pedido de um toque completo entre dois frames é preservado até a próxima atualização de física, evitando perder taps rápidos. Esse pedido é consumido uma vez, respeita cooldown e recarga, e é descartado ao pausar, morrer, entrar em killcam ou trocar o modo de controle. Soltar o dedo fora do botão também interrompe o disparo. Recarga automática ao esvaziar o carregador permanece disponível.

O campo antigo `auto_fire` é lido para compatibilidade, mas passa a ser falso; a opção foi removida dos ajustes e o tutorial explica o controle manual. Essa migração não altera moedas, armas, skins ou maestria. A assistência de mira não dispara e não puxa a câmera móvel parada sem interação.

## Cor e materiais

O shader antigo convertia algumas superfícies horizontais em pedra de pátio e misturava 88% de uma imagem de calcário bege sobre a cor escolhida para o material. Assim, pisos de temas diferentes acabavam parecidos. Agora o tipo de superfície é preservado e a pedra fornece variação de pigmento, mantendo a cor-base.

O Distrito Neon usa pisos metálicos azuis; a emissão dos materiais procedurais foi reduzida para preservar os detalhes claros. Os telhados modulares usam luminância da textura original com paletas rosa, jade, azul e âmbar. Cerejeiras, folhagem, céu e luz da Vila Floral receberam ajustes; Docas mantém seu céu marítimo e as corridas receberam cores de obstáculos mais marcantes. A geometria de colisão não foi alterada nesta entrega.

Não foram adicionados efeitos de tela, luzes extras, assets pagos ou texturas de terceiros. A nova pintura de telhados é um shader do projeto sobre as texturas CC0 já integradas.

## Validação

```powershell
godot --headless --path . --fixed-fps 60 -- --test --manual-fire
godot --path . --fixed-fps 60 -- --qa --manual-fire
godot --path . --fixed-fps 60 -- --qa --color
godot --headless --path . --fixed-fps 60 -- --test
```

Os testes de disparo usam eventos nativos de toque, um bot físico visível, taps rápidos, hold de arma automática, toque por disparo nas semiautomáticas, arraste da câmera, liberação dos dedos em ordens diferentes e pausa. Também verificam a migração de um save com tiro automático previamente habilitado.

Capturas reais de comparação, na mesma câmera e qualidade leve: `shots/color_before_*` e `shots/color_after_*`. As imagens anteriores foram registradas antes de mudar os materiais. Capturas do HUD e do botão manual: `shots/color_manual_mobile_ready.png` e `shots/color_manual_mobile_firing.png`.

Nas quatro vistas observadas, o contador de draw calls permaneceu em 256, 103, 105 e 244 antes e depois. Esse resultado é específico das câmeras e do PC usados; não comprova FPS, bateria ou consumo total de memória em Android. A revisão visual das arenas antigas e as demais pendências de lançamento continuam em `estado_lancamento.md`.

Validação final desta versão: **1.892 verificações**, sem falhas nem erros de script; 19 verificações específicas de disparo manual. O diagnóstico de save corrompido e a rejeição de uma gravação de HUD não permitida são provocados deliberadamente pelos testes de recuperação.
