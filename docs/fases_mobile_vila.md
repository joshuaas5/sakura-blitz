# Continuação das fases — APK 0.4.0

## Bloqueio de navegação no Android

O usuário relatou que não conseguia rolar o menu inicial nem entrar numa partida. A configuração global de emulação de mouse por toque estava desativada e cartões decorativos interrompiam a propagação do gesto antes do ScrollContainer.

A emulação foi habilitada para os controles nativos da interface. A entrada da partida ignora a cópia de mouse gerada pelo motor e continua tratando cada dedo real separadamente. Os cartões e botões que ficam em áreas roláveis propagam os gestos ao contêiner. A base de comportamento do ScrollContainer foi conferida no [código oficial do Godot](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/scene/gui/scroll_container.cpp).

O lobby agora mantém marca, abas e acesso ao treino fora da área rolável. Cartões compactos exibem miniatura, nome e botão de jogar. O primeiro botão cabe na tela horizontal de teste sem rolagem. Loja, editor, tutorial e resultados usam a mesma entrada nativa. Os resultados de partida têm tamanho limitado à área segura e conteúdo rolável.

## Referência visual e circulação: Vila Floral

- Casa do chá com duas portas abertas, mesa, bancos, louças, prateleiras, piso de madeira e iluminação interna.
- Passagem conecta o flanco à praça; a mobília deixa o corredor central livre. Paredes e teto têm colisões próprias.
- A navegação por caminhos, antes integrada às três arenas novas, também foi aplicada à Vila Floral. As colisões e obstáculos da navegação compartilham a mesma origem.
- Placas, bancos, vasos e lanternas acrescentados à praça, com materiais compartilhados e agrupamento estático.
- Fonte e jardim com fontes de áudio 3D e atenuação pela distância. Dois loops originais sintetizados por `tools/compose_ambience.py`, sem gravações externas.
- Volumes independentes para música, efeitos e ambiente. Ambiente silenciado nos menus.

Esta entrega avança a referência da fase 2; não encerra a direção de arte de todos os mapas. Mais interiores, animações, sons posicionais de combate, navegação vertical nas arenas antigas, multiplayer, contas e compras continuam pendentes.

## Validação

- `tests/menu_checks.gd`: injeta toques e arrastes por `Input.parse_input_event`, atravessando entrada, GUI e callbacks. Não chama `pressed.emit()` para fingir interação.
- No PC, habilita a simulação de touchscreen do próprio motor e restaura a configuração ao terminar. Usa o transform de viewport para converter as coordenadas da UI em pixels.
- Confere arraste sobre miniatura e botão, ausência de partida acidental, troca de aba, entrar numa arena, não duplicar dedos, rolar loja, abrir/cancelar editor, entrar/sair do treino e retornar ao lobby pelos resultados de combate e corrida.
- `tests/village_checks.gd`: percurso planejado pelo interior, movimento físico do jogador atravessando ambas as portas, piso, fontes sonoras, mixer e limpeza ao trocar de mapa.
- `tests/arena_checks.gd`: travessia de ponta a ponta também na Vila Floral.
- Build de APK rejeita erros de script mesmo que o exportador retorne código zero. Workflow Web passa a importar e testar antes de exportar/publicar; execução remota ainda não foi realizada.

Comandos:

```powershell
godot --headless --path . --fixed-fps 60 -- --test
godot --path . --fixed-fps 60 -- --test --menus
godot --path . -- --qa --phase2
./tools/build_android_test.ps1
```

700 verificações da base + 68 de bots + 441 de arenas + 57 mobile + 9 da vila + 21 de menus: **1.296, zero falhas**. Logs em `build/phase2_validation_final.log` e `build/phase2_capture_final.log`.

As mensagens `EXPECTED DIAGNOSTIC` identificam corrupção proposital e escrita impossível no perfil de teste; a recuperação é verificada. Capturas `shots/phase2_*.png` são do Godot nativo no PC, incluindo janela de 844×390.

## APK

`export/android/SakuraBlitz-0.4.0-test.apk`, versionCode 3. Mesmo pacote e chave de teste dos APKs anteriores. Novos sons e scripts são incluídos no pacote; arquivos de build e capturas não são incluídos.

É necessário repetir no telefone o caminho: abrir app → rolar cartões → jogar → terminar → voltar ao lobby. A reprodução e os testes no PC não substituem a confirmação no aparelho que apresentou o problema, nem medição de aquecimento/FPS.
