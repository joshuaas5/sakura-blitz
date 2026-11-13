# Revisão de estabilidade — 0.5.1

Revisão local dos fluxos completos após a entrega de combate. Foram escritos testes de regressão antes das correções; a reprodução inicial falhou em 9 dos 13 cenários observados.

## Correções

- Morte e reaparecimento liberam os donos de todos os dedos e limpam tiro, salto, movimento, mira, salto em buffer e estado do gatilho semiautomático. Soltar um dedo da vida anterior não interfere na nova.
- Pausa e transições de interface zeram movimento horizontal residual, preservando a velocidade vertical de um salto que será retomado.
- Botão Voltar do Android fecha a loja atual, respeitando o contexto anterior, em vez de abrir o lobby por trás dela.
- Interrupção com loja aberta fecha a loja e deixa somente o lobby pausado. O editor de HUD continua preservando o rascunho, encerrando apenas o arraste ativo.
- Dano tardio é ignorado durante pausa, menus, corrida ou partida já encerrada.
- Diagnóstico identifica cada instância de partida, mesmo em revanche no mesmo mapa. Reinicia também quando a resolução de render muda, limpa o texto anterior e exclui integralmente o frame que termina o aquecimento.
- Duração medida é a soma dos frames efetivamente amostrados. Tempo em menus não é contado.

## Verificação

`tests/quality_checks.gd` cobre 15 cenários. Usa o estado real do jogador, callbacks de dano, notificações de navegação e controlador de interface; evita escrever no perfil do usuário.

```powershell
godot --headless --path . --fixed-fps 60 -- --test --quality
godot --headless --path . --fixed-fps 60 -- --test
./tools/build_android_test.ps1
```

Log da suíte completa: `build/quality_release_validation.log`. A soma com as suítes anteriores é 1.394 verificações. Os diagnósticos esperados de save corrompido/escrita impossível permanecem identificados no log.

Artefato: `export/android/SakuraBlitz-0.5.1-test.apk`, versionCode 5. É uma atualização de manutenção do mesmo pacote de teste. As nove falhas reproduzidas foram corrigidas; ainda é necessário verificar os fluxos no aparelho real. Esta revisão não conclui as etapas pendentes de arsenal, navegação vertical, multiplayer, contas e cobrança.
