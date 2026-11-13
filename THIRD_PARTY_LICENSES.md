# Assets incorporados no rework Atelier

Nenhum asset pago foi comprado nesta integração. As licenças originais acompanham os arquivos.

| Conteúdo | Autor / fonte primária | Licença | Uso |
| --- | --- | --- | --- |
| Medieval Village MegaKit Standard | [Quaternius](https://quaternius.com/packs/medievalvillagemegakit.html) | CC0 1.0 | Casas modulares, telhados, janelas, carroças, cercas, caixas e trepadeiras da Vila Floral |
| Ultimate Stylized Nature | [Quaternius](https://quaternius.com/packs/ultimatestylizednature.html) | CC0 1.0 | Árvores, arbustos, flores e grama; folhagem de bordo recebe recoloração no shader |
| Flat Guns East | [Pichuliru](https://opengameart.org/content/cc0-flat-guns-east) | CC0 1.0 | Rifle_Assault_East, base visual do fuzil |
| Flat Guns West | [Pichuliru](https://opengameart.org/content/cc0-flat-guns-west) | CC0 1.0 | Sniper_Rifle_West, Pistol_Full_West, SMG_Full_West e Shotgun_Auto_West |
| Flat Gun Attachments | [Pichuliru](https://opengameart.org/content/cc0-flat-gun-attachments) | CC0 1.0 | Scope_West, Reflex_West e Suppressor_West |
| Nunito Sans | [Google Fonts / projeto Nunito Sans](https://github.com/google/fonts/tree/main/ofl/nunitosans) | SIL Open Font License 1.1 | Tipografia do HUD; OFL.txt acompanha a fonte |
| Modular Sci-Fi MegaKit Standard | [Quaternius](https://quaternius.itch.io/modular-sci-fi-megakit) | CC0 1.0 | Módulos de paredes, pisos, colunas, consoles, ventilação e carga do Observatório Lunar |
| Pirate Kit 2.1 | [Kenney, publicação do autor](https://opengameart.org/content/pirate-kit) | CC0 1.0 | Veleiros, barcos, palmeiras, carga, bandeiras, farol e equipamento das Docas do Festival e do Bazar Solar |
| Factory Kit 3.0 | [Kenney, publicação do autor](https://opengameart.org/content/conveyor-kit) | CC0 1.0 | Guindastes, equipamentos, barreiras, consoles e estruturas industriais do Porto Cobalto; licença original e hashes em `assets/third_party/kenney_factory` |
| Blaster Kit 2.1 | [Kenney, publicação do autor](https://opengameart.org/content/blaster-kit) | CC0 1.0 | Modelos de estojos, carregadores, projéteis e alvos; sprites originais de munição e caixa. Licença, atlas e hashes em `assets/third_party/kenney_blaster` |
| Platformer Kit 1.1, seleção de itens | [Kenney, publicação do autor](https://opengameart.org/content/platformer-kit) | CC0 1.0 | Modelos e sprites de coração, moeda, joia e botão de impulso. Nenhuma fase de parkour nova. Licença original e hashes em `assets/third_party/kenney_items` |
| Car Kit 3.1 | [Kenney, publicação do autor](https://opengameart.org/content/car-kit) | CC0 1.0 | Veículos de cobertura da Vila Sakura; licença original, atlas e hashes em `assets/third_party/kenney_car` |
| Train Kit, seleção | [Kenney, publicação do autor](https://opengameart.org/content/train-kit) | CC0 1.0 | Vagões e trilhos da Estação Aurora; licença original, atlas e hashes em `assets/third_party/kenney_train` |

Os arquivos GLB originais das armas são preservados em `assets/third_party/pichuliru_guns`. `tools/prepare_weapon_models.py` gera os derivados em `prepared/`: separa peças rígidas pelos pesos de osso, mantém normais e materiais, e acrescenta UV planar. O jogo anima carregador e ferrolho separadamente. Os nomes de gameplay não representam identificação exata dos modelos reais de fábrica.

As pastas dos packs contêm hashes e referências de procedência. O License.txt fornecido pelo autor no diretório de natureza menciona outro pack no cabeçalho; foi mantido intacto. A página primária do Ultimate Stylized Nature também declara CC0.

`tools/prepare_arena_assets.py` extrai uma seleção dos arquivos originais de arquivos ZIP mantidos fora do export, em `build/asset_downloads/`. Os modelos são redimensionados e agrupados apenas em runtime. As texturas do Sci-Fi têm limite de importação de 512 px para cor e 256 px para mapas auxiliares, com mipmaps; os PNGs originais são preservados. As miniaturas em `assets/ui/maps` são capturas reais do próprio jogo.

As molduras de HUD e as duas pinturas de armas são imagens geradas para este projeto, com prompts em `assets/ui/blossom/README.md` e `assets/textures/cozy/ATELIER.md`. Os ícones SVG são desenhos originais do projeto. A arquitetura e as armas não foram extraídas de outros jogos.
