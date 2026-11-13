# Rework Atelier — implementação local

## Interface

`AtelierHud` substitui o antigo desenho de painéis e ícones dentro de `_draw`. Usa controles persistentes: NinePatchRect para painéis, TextureRect para molduras e SVGs, Label para texto. A fonte Nunito Sans tem peso configurado por tag OpenType. Só minimapa, retícula e arco de recarga usam desenho dinâmico.

O minimapa continua baseado nas colisões reais. Vida, escudo, munição, cronômetro, progresso da corrida, ranking e feed de abates usam dados da partida. Combate continua individual; a interface não inventa equipes. Botões e áreas de toque compartilham os mesmos retângulos. No parkour aparecem salto e retorno ao checkpoint, sem controles de armas.

## Armas e skins

Três modelos importados substituem os corpos procedurais do fuzil, sniper e pistola. Carregador e ferrolho continuam animados. Mira telescópica, reflex e silenciador também são assets importados. Efeito do disparo acompanha a ponta do cano de cada arma. A faca conserva a geometria e a animação anteriores.

Laca Imperial usa arte floral vinho, marfim e ouro. Porcelana da Aurora usa flores azuis sobre marfim. Ouro e Brasa usam variações de material da arte floral. Projeção triplanar evita depender de UVs ausentes nos modelos originais. Não há bônus de atributos nas skins. A loja agora renderiza a arma selecionada com a skin real, inclusive no cartão de upgrade; a prévia só atualiza ao ser criada ou redimensionada.

## Vila Floral

A arena de índice 5 foi reconstruída como praça de vila, com arquitetura do Medieval Village MegaKit, natureza do Ultimate Stylized Nature, toldos, fonte, casas de um ou dois pisos e árvores floridas. Permanece acessível pelo lobby em Combate → Vila Floral; aparece primeiro na lista de arenas.

Materiais equivalentes são compartilhados e superfícies estáticas agrupadas por material e região. Colisões permanecem separadas. Sombras direcionais ficam desligadas no preset gráfico mais leve. As outras cinco arenas e os seis percursos ainda usam a direção de cenário anterior; esta reconstrução não foi aplicada a todos os mapas.

## Reprodução

```powershell
godot --headless --path . --editor --import
godot --headless --fixed-fps 60 --path . -- --test
godot --path . -- --qa
godot --path . -- --qa --art
godot --headless --path . --export-release Web build/web/index.html
```

`--qa --art` gera capturas reais da vila, três armas, inspeção, porcelana, mira, HUD PC/mobile e loja em `shots/atelier_*.png`. As capturas são do Godot nativo em resoluções diferentes. Os modos de automação usam perfil descartável.

A suíte inclui recarga das peças importadas, consumo de munição, posição do efeito do cano, silenciador, chão dos spawns, colisão da fonte, botões dentro da tela sem sobreposição e entrada pelo novo botão de pausa. A mensagem de erro precedida por EXPECTED DIAGNOSTIC testa recuperação de save e é intencional.

## Limites da validação

Exportar para web não substitui jogar no navegador. Desempenho, aquecimento, ergonomia e legibilidade ainda precisam ser medidos em celulares reais. As capturas de alta qualidade usam sombras; não são evidência de 60 FPS em aparelhos fracos. As skins continuam compradas com moedas locais; cobrança real, contas e servidor autoritativo não foram implementados nesta etapa.

Créditos e licenças: `THIRD_PARTY_LICENSES.md`. O jogo continua em desenvolvimento artístico; as pranchas conceituais não são screenshots nem promessa de fidelidade final.

## Resultado desta validação

- 688 verificações de integração + 68 de bots: 756, zero falhas.
- Importação, QA visual e exportação Web concluídas sem erros de script/renderização.
- Pacote `build/web/index.pck`: 16.534.956 bytes (15,77 MiB); engine/JS/WASM são arquivos adicionais.
- Texturas auxiliares do cenário limitadas a 256 px; maior parte dos albedos a 512 px; piso e pinturas das armas a 1024 px. Os arquivos-fonte permanecem intactos.
- Revisão visual de três armas, recarga via teste, mira do fuzil, porcelana, inspeção, loja, combate PC/mobile e parkour mobile.
- Sem publicação, compra de assets ou alteração da cobrança real.
