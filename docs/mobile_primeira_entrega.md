# Mobile — primeira entrega da etapa 1

Implementação local em 13/11/2026, versão Android `0.3.0-test` / versionCode 2.

## Recursos entregues

- Editor em **Ajustes → Organizar botões na tela**. Arrastar pulo, tiro, mira, recarga, troca de arma, analógico e checkpoint; ajustar tamanho e opacidade; alternar destro/canhoto e prévia tiro/corrida. A pausa fica fixa.
- Salvar, cancelar e restaurar padrão. Validação de sobreposição para ambos os modos. Preferências normalizadas pela área segura e persistidas no perfil existente. Falha de escrita mantém o editor aberto e preserva o layout anterior.
- `MobileLayout` fornece a geometria para prévia, desenho e toque. Em outro formato de tela, uma configuração que passe a sobrepor controles usa o padrão da mão escolhida até ser reorganizada.
- Área segura Android convertida de pixels para coordenadas da interface. Controles, indicadores e margens do lobby respeitam seus limites. Automação permite simular recortes; ainda exige confirmação em aparelho real.
- Treino guiado de combate na Vila Floral: andar, olhar, pular e acertar um bot. A progressão acompanha deslocamento, câmera, salto e confirmação de acerto. Bots ficam parados nos primeiros passos e usam dificuldade fácil na prática. Sair antes do final não marca conclusão. Pode ser repetido nos Ajustes; o lobby oferece convite enquanto não estiver concluído.
- Perda de foco e suspensão liberam os dedos, pausam a partida e retornam ao lobby. O botão Voltar do Android abre a pausa ou cancela o editor. Retomar a partida é uma ação explícita.
- Diagnóstico local opcional: FPS, p95 dos quadros recentes e quantidade de quadros acima de 50 ms. Amostragem começa após 2 segundos de aquecimento, pausa nos menus e reinicia ao mudar mapa/qualidade. p95 e média usam até 600 amostras recentes; o contador de lentidão cobre a sessão medida.
- **Ajustes → Copiar diagnóstico da última partida** copia o relatório e também o grava em `user://diagnostico_sakura.txt`. Contém sistema/modelo, GPU, mapa, qualidade, dimensão da interface e métricas. Não envia dados pela rede. Memória estática é identificada como métrica do Godot, não RAM total.

## Código

`scripts/mobile_layout.gd`, `hud_editor.gd`, `training_guide.gd`, `frame_diagnostics.gd`; integração em `sakura_blitz_main.gd`, `sakura_hub.gd`, `atelier_hud.gd` e `player_profile.gd`.

## Validação

```powershell
godot --headless --path . --fixed-fps 60 -- --test
godot --headless --path . --fixed-fps 60 -- --test --mobile
godot --path . -- --qa --mobile
./tools/build_android_test.ps1
```

- 700 verificações da base + 68 de bots + 331 das arenas + 57 mobile = **1.156, zero falhas**.
- Novos testes cobrem geometrias em quatro tamanhos de tela e duas mãos, recortes simulados, persistência e dados inválidos, toque simultâneo, interrupção, cancelar/salvar, falha de escrita, tutorial e cálculo do diagnóstico.
- Mensagens `EXPECTED DIAGNOSTIC` identificam corrupção deliberada do save e falha deliberada de escrita. São cenários de recuperação testados.
- Cinco capturas nativas: `shots/mobile_controls_right.png`, `mobile_controls_left_safe.png`, `mobile_hud_editor.png`, `mobile_training.png`, `mobile_settings.png`. A janela com layout móvel e o recorte são simulados no PC.
- APK com assinatura v2/v3 e alinhamento de 16 KB verificados, ARM 32/64 bits. Mesmo pacote e chave do APK anterior para permitir atualização. O arquivo anterior permanece disponível.

## Próxima validação física

Instalar a atualização, reorganizar botões e reabrir o app para conferir persistência; experimentar o treino, jogo com dois dedos, botão Voltar, troca de aplicativo e retomada; jogar ao menos 20 minutos no perfil leve, copiar o diagnóstico e registrar modelo do telefone e desconfortos encontrados.

Esta entrega implementa a base mobile da etapa 1. Desempenho, ergonomia e recortes físicos continuam pendentes de aparelho real. Tutorial específico de corrida, polimento artístico de referência, navegação tática ampliada, online, contas e cobrança continuam no plano das próximas entregas.
