# Mira mobile — 0.7.2

## Referências e decisão

O [guia da Activision sobre COD Mobile](https://blog.activision.com/ca/en/call-of-duty/2019-10/Getting-a-Grip-on-the-Call-of-Duty-Mobile-Controls) descreve personalização do HUD e sensibilidade de mira. A [diretriz de controles da Microsoft](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107) mostra opções de toque, pressão e modo híbrido nesse jogo. Serviram como referência de interação, sem copiar seu HUD.

Adotamos **híbrida** como padrão: tocar em MIRAR mantém a mira; um segundo toque fecha. Segurar ou arrastar a partir de MIRAR usa a aproximação enquanto o dedo está pressionado; soltar encerra. Um arraste curto não é confundido com um toque que deve manter a mira. Ajustes oferece também os modos exclusivos Tocar e Segurar.

O tiro continua manual e separado. Mirar não solicita disparo nem consome munição. Isso permite tocar MIRAR e voltar a usar o polegar direito para atirar/arrastar, com o esquerdo no analógico. Não adicionamos um disparo automático nem obrigamos a mirar para atacar.

## Feedback e controle

- Botão padrão maior, identificado como MIRAR; o estado ativo mostra MIRANDO, borda de progresso e cor própria.
- Vibração curta ao abrir/fechar, respeitando a preferência de vibração. A resposta do hardware ainda precisa de conferência no aparelho.
- O próprio dedo em MIRAR pode arrastar a câmera; ao soltá-lo, um dedo de tiro ainda pressionado pode assumir a câmera.
- Sensibilidade interpolada com a aproximação e com o campo de visão da arma; a sniper permite ajustes mais finos que o fuzil.
- Um aviso de primeiro uso explica onde tocar e desaparece após usar o botão.
- A intenção de mirar cancela a corrida no combate. Corrigir isso elimina o bloqueio circular em que correr impedia a mira de abrir e a mira nunca atingia o estado necessário para parar a corrida.

Pausar, perder foco, morrer ou entrar em killcam limpa a intenção de mira. Toques cancelados não deixam uma mira nova presa. O modo de toque e o aviso de primeiro uso são persistidos. Layouts antigos com botão de mira personalizado preservam sua escala original; Restaurar no editor adota as novas dimensões.

## Verificação

```powershell
godot --headless --path . --fixed-fps 60 -- --test --aim
godot --path . --fixed-fps 60 -- --qa --aim
godot --headless --path . --fixed-fps 60 -- --test
```

22 verificações específicas usam eventos nativos de toque para cobrir os três modos, mira enquanto o analógico tenta correr, ausência de disparo ao mirar, controle simultâneo de movimento/mira/tiro, cancelamento, persistência, layouts antigos e sensibilidade de zoom. Capturas reais em `shots/aim_mobile_ready.png`, `aim_mobile_aimed.png` e `aim_mobile_settings.png`.

O ensaio renderizado usa o PC com viewport de celular; não substitui o teste de conforto, alcance dos polegares, precisão ou vibração no aparelho físico.

Resultado final: **1.914 verificações** na suíte completa, zero falhas e zero erros de script. As 22 verificações de mira passaram também no executável nativo renderizado. APK de teste 0.7.2, versionCode 9.
