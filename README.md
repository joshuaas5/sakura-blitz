# SAKURA BLITZ — Mobile-First F2P Crossplay FPS & Mega Parkour

![Godot 4.7](https://img.shields.io/badge/Godot-4.7.2-478cbf?logo=godotengine&logoColor=white)
![Platform](https://img.shields.io/badge/Platforms-Mobile%20(iOS%2FAndroid)%20%7C%20PC%20Crossplay-brightgreen)
![Cloudflare Pages](https://img.shields.io/badge/Cloudflare_Pages-sakura--blitz.pages.dev-f38020?logo=cloudflare&logoColor=white)
![Build](https://img.shields.io/badge/CI%2FCD-GitHub_Actions_%E2%9E%9E_Cloudflare_Pages-blue)

**SAKURA BLITZ** é um jogo competitivo, ágil e viciante em **3D Low-Poly / Retro-Moderno**, projetado com foco **Mobile-First** para **iOS (Safari / PWA / App Store)**, **Android (Chrome / PWA / Google Play)** e **PC Desktop Crossplay**.

O jogo conta com **dois modos de jogo completamente distintos**, cada um com sua dinâmica, atmosfera e progressão:

---

## 🎮 Teste Online no Navegador (Cloudflare Pages)

Acesse diretamente em qualquer celular ou PC:
👉 **[https://sakura-blitz.pages.dev/](https://sakura-blitz.pages.dev/)**

> Cada commit enviado para a branch `main` no GitHub dispara automaticamente o GitHub Actions, que compila o export Web do Godot 4 e faz o deploy instantâneo na Cloudflare Pages.

---

## 🕹️ Dois Modos de Jogo Completamente Diferentes

### 1. 🎯 Modo Tiro / Combate Letal (Estilo Phantom Forces / BO2)
*Disputa intensa de PvP contra bots inteligentes com foco em dopamina pura de eliminações.*

- **4 Arenas Táticas**:
  1. **Vila BO2 (Nuketown / Hijacked)**: Pátio central com bunkers, passarelas superiores e faixas de callouts vibrantes.
  2. **Shipment CQC**: Labirinto de contêineres e corredores estreitos para confrontos corpo a corpo alucinantes.
  3. **Sniper Canyon**: Vale aberto cercado de torres altas e linhas de visão longas para duelos de AWP.
  4. **Cyber-Vertigo 3-Floor**: Complexo vertical de três andares com elevadores, rampas e combate multinível.
- **Dopamina de Abate (Phantom Forces)**:
  - **Kill Siphon**: +30 HP curados instantaneamente + 25 de Escudo + recarga imediata de munição a cada abate.
  - **Burst de Adrenalina**: +35% de velocidade de corrida por 2 segundos após matar.
  - **Ragdoll Físico 3D**: O bot derrotado é arremessado fisicamente para trás pela inércia do tiro fatal.
  - **Stack de Pontos no Centro da Tela**: Notificações empilhadas de pontuação (`INIMIGO ELIMINADO +100`, `HEADSHOT FATAL +50`, `DOUBLE KILL +100`, `LONGSHOT +75`).
  - **Placar Dinâmico ao Vivo**: Tabela no topo da tela exibindo as eliminações em tempo real entre você e os 6 bots da partida.
- **Arsenal Balanceado**:
  - **AK-47**: Dano 42 (3.2x Headshot fatal).
  - **AWP Sniper**: Dano 140 (1-shot fatal em qualquer parte do corpo).
  - **Deagle .50**: Dano 58 (3.0x Headshot fatal).
  - **Karambit Tática**: Dano 110 (1-hit kill nas costas e combate corpo a corpo).

---

### 2. 🏃 Modo Corrida Parkour (Estilo Fall Guys Marathon)
*Corrida pura de habilidade e reflexos contra 7 bots corredores sem tiros ou mortes por PvP.*

- **Zero Mortes por Tiro**: No modo parkour não há armas de fogo — a disputa é exclusivamente de agilidade, saltos e timing.
- **Portão de Largada com Contagem Regressiva**:
  - `5... 4... 3... 2... 1... VAI!` com trava física de largada que abre para todos os corredores simultaneamente.
- **7 Bots Corredores Competitivos**:
  - Cada bot possui inteligência de navegação em tempo real, pulando nos tambores, calculando desvios e disputando o 1º lugar até a linha de chegada.
- **4 Maratonas Longas e Difíceis (335m a 380m cada)**:
  1. **Mega Marathon Fall Guys (350m)**: Tambores elásticos Lily-Leaper, martelos gigantes giratórios (Big Yeetus), pêndulos balançantes, empurradores hidráulicos e piso de azulejos falsos (Tip-Toe).
  2. **Cozy Rooftops Skyline (335m)**: Telhados em alturas vertiginosas, chaminés de vapor com impulso ascendente, tirolesas e gaps técnicos de bunnyhop.
  3. **CS:GO KZ & Surf Valley (380m)**: Rampas de surfe com física de atrito nulo, escadas KZ de precisão cirúrgica e jump pads hipersônicos.
  4. **Cyber-Vertigo Spiral (340m)**: Espiral futurista ascendente de plataformas móveis, lasergates de repulsão e ventoinhas de salto.

---

## 📱 Controles Mobile-First (iOS & Android)

A HUD do jogo foi concebida para touch nativo com alta sensibilidade:
- **Analógico Virtual 360° (Lado Esquerdo)**: Posicionamento dinâmico ao toque, com anel externo para corrida automática (Auto-Sprint).
- **Controle de Mira com Aim-Assist (Lado Direito)**: Arraste livre para mirar, com magnetismo suave de mira sobre alvos próximos.
- **Disparo em Garra (Claw Button)**: Botão de tiro tático no canto superior esquerdo para mira e disparo simultâneos com 3 ou 4 dedos.
- **Auto-Fire Opcional**: Disparo automático inteligente ao passar a mira sobre um bot adversário no modo de tiro.
- **Troca Rápida de Modos e Fases**: Botões dedicados no topo para alternar instantaneamente entre Modo Tiro e Modo Parkour, trocar de mapa ou reiniciar a corrida.

---

## 💻 Controles de Teclado & Mouse (PC)

| Tecla | Ação |
|---|---|
| `W, A, S, D` | Movimentação / Strafing |
| `Espaço` | Pulo / Bunnyhop |
| `Shift` | Correr / Adrenalina |
| `Ctrl / C` | Agachar |
| `LMB (Botão Esquerdo)` | Disparar / Golpear com Faca |
| `RMB (Botão Direito)` | Mirar (Sight Red Dot 3D / Luneta AWP) |
| `R` | Recarregar Arma |
| `1, 2, 3` | Primária (AK/AWP), Secundária (Deagle), Faca (Karambit) |
| `TAB` | Alternar entre Modo Tiro e Modo Parkour |
| `M` | Próximo Mapa / Fase daquele Modo |
| `P` | Ligar / Desligar Rádio dos Mapas |
| `V` | Alternar Exibição dos Controles Touch na Tela |

---

## 🛠️ Tecnologias e Arquitetura

- **Engine**: Godot Engine 4.7.2 Stable (GL Compatibility Mobile Renderer).
- **Single-Thread Web Build**: Roda em 60/120 FPS sem bloqueios de segurança em navegadores móveis.
- **Shader Analítico PSX-Pro**: Iluminação 100% calculada por pixel no mundo, sem artefatos de flickering em sombras e texturas.
- **Hospedagem & CI/CD**: Cloudflare Pages + Edge Worker streaming com WebAssembly compactado via gzip (redução de 38MB para 9.5MB).
