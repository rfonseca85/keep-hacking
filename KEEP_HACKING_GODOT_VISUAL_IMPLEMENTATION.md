# KEEP HACKING — Implementação visual viva no Godot

> **Documento de implementação para um agente de programação (Codex / Claude Code / Copilot) ou desenvolvedor Godot.**
>
> **Objetivo:** integrar o *Keep Hacking Asset Pack v0.9.1* ao jogo existente, deixando-o com aparência de pixel-art cyberpunk rica, consistente e **viva**, sem substituir o gameplay atual por telas estáticas e sem eliminar nenhuma mecânica.
>
> **Projeto:** `https://github.com/rfonseca85/keep-hacking` — branch `main` pública consultada em 08/10/2026. **Escopo:** mudanças de arte, apresentação, UI, animação e feedback; **não** um redesign dos sistemas de progressão.
>
> **Entrada obrigatória:** o ZIP `Keep_Hacking_Asset_Pack.zip` entregue na conversa. Se ainda não estiver extraído no repositório de trabalho, solicite ao responsável que o disponibilize. Não substitua recursos faltantes por imagens de screenshots.

---

## 0. Comando para o agente que vai implementar

**Execute esta especificação diretamente sobre o repositório existente.** Comece inspecionando `project.godot`, `scripts/GameState.gd`, `scripts/Main.gd`, `scripts/ServerNode.gd`, `scripts/NetworkSelect.gd`, `scripts/SkillTree.gd` e `scripts/Audio.gd`. Crie uma branch dedicada, importe o asset pack e faça as melhorias **por etapas testáveis**. Preserve a API pública, os caminhos das cenas, as fórmulas e os fluxos de interação. Não declare o trabalho concluído apenas porque um mockup ou PNG de tela inteira parece bonito: **a interface final precisa ser construída com nós e componentes reais de Godot, conectados ao estado do jogo em tempo real**.

Ao finalizar, entregue os arquivos Godot implementados, um resumo dos diffs por arquivo, antes/depois capturados **do jogo rodando** e relatório de testes. Se qualquer detalhe deste documento contrariar código mais recente do repositório, **o comportamento funcional do código mais recente prevalece**; adapte a camada visual e registre a diferença.

## 1. Auditoria objetiva do projeto atual

### 1.1 Fundação técnica observada

| Componente | Estado observado | Implicação para a migração |
|---|---|---|
| `project.godot` | Projeto Godot 4.x, feature list `4.7`, renderer `gl_compatibility`, viewport-base `1280×720`, stretch `canvas_items` com aspect `expand` | Usar CanvasItem/Sprite2D/AnimatedSprite2D/Control; não depender de bloom/HDR exclusivo de outro renderer. |
| Autoload `GameState` | `res://scripts/GameState.gd` | Fonte de verdade de moedas, stats, tiers e upgrades. **Não duplicar** estado dentro da UI. |
| Autoload `Audio` | `res://scripts/Audio.gd` | Áudio procedural e ambient já existem; manter as chamadas de SFX. |
| Cena inicial | `res://scenes/NetworkSelect.tscn` | Deve continuar sendo a primeira tela. |
| Outras cenas | `res://scenes/Main.tscn`, `res://scenes/SkillTree.tscn` | Preservar caminhos de transição e nós-raiz. |
| UI / gameplay | Grande parte construída programaticamente nos scripts `.gd` a partir de cenas `.tscn` mínimas | Criar classes de apresentação reutilizáveis; **não** presumir que haverá árvores de `Control` prontas para editar no editor. |
| Arte atual | Predominantemente retângulos e linhas desenhados por código | Substituir gradualmente a parte decorativa por PNGs, Sprite2D e componentes com estilo; preservar hitboxes e lógica. |

### 1.2 Arquivos que o agente precisa preservar e adaptar

| Arquivo real | Responsabilidade atual | Alteração permitida |
|---|---|---|
| `scripts/GameState.gd` | Três recursos, stats, custos, tiers e desbloqueio de redes | Preferencialmente **nenhuma**; somente leitura pelos novos visuais. |
| `scripts/Audio.gd` | `play_tick`, `play_exfiltrate`, `play_exploit`, `play_upgrade`, `play_breach`, `play_denied`, `play_ambient` | Manter API e chamadas; refinar volume apenas se necessário. |
| `scripts/ServerNode.gd` | Estado de cada servidor (`LOCKED`/`READY`), progresso, vulnerabilidade e honeypot | Acrescentar camada visual/novos sinais, sem mudar assinaturas nem regras. |
| `scripts/Main.gd` | Grade, input, cracking, exfiltração, bots, trace, HUD, upgrades, rodada e resultado | Trocar construção visual; preservar as chamadas de gameplay e taxas. |
| `scripts/NetworkSelect.gd` | Renderiza 4 cards de tiers, bloqueio e navegação | Reestilizar cards e acrescentar animações leves; preservar `GameState.try_unlock_tier`. |
| `scripts/SkillTree.gd` | 10 habilidades, compra, níveis, tooltip e navegação | Reestilizar a árvore; preservar IDs, preços, aplicação e interações. |
| `scenes/*.tscn` | Cenas-raiz atuais são `Node2D` com script | Manter as mesmas entradas; permitir instanciar subcenas visuais. |

**Limitação importante:** no código público inspecionado, `GameState` guarda valores em memória e não há implementação de persistência em disco evidenciada. Este trabalho **não deve inventar ou reescrever um sistema de save**. O dicionário local `levels` da `SkillTree.gd` também é reiniciado ao entrar na cena; trate eventual persistência da árvore como ticket separado, **não como efeito colateral da migração visual**.

## 2. Contrato de preservação absoluta do gameplay

Estas são **invariantes de regressão**. Não modificar valores, regras, critérios de unlock ou comportamento de interação:

1. **Grade:** 12 colunas × 7 linhas, `CELL = 64`, origem `(160, 140)`; geração atual com aproximadamente 22% de posições vazias.
2. **Interação principal:** pressionar e segurar o clique sobre a área do jogo aumenta o progresso de cracking no raio atual. Servidores no estado `READY` são coletados por clique (e o loop também os coleta sob clique pressionado). Não virar point-and-click de ações diferentes.
3. **Estado do servidor:** `ServerNode.State.LOCKED` → `READY`; `reset_locked(vulnerable: bool, honeypot: bool = false)` e `add_progress(amount: float) -> bool` seguem existentes. Honeypot `READY` expira em **2,6 segundos**.
4. **Recursos:** `credits`, `exploits`, `zerodays`; preservar nomes, fórmulas e modo de obtenção. Não inserir barras fictícias de moedas, energia, experiência ou inventário.
5. **Cracking e extração:** preservar `decrypt_speed`, `decrypt_radius`, `bot_level`, `yield_mult`, recompensa normal, vulnerabilidade/exploit e recompensa de honeypot.
6. **Bots:** continuar a agir automaticamente a cada `max(0.4, 1.6 - bot_level * 0.2)` segundos, com 1 alvo por ciclo ou 2 em tier com `swarm_bots`.
7. **Trace / rodada:** a barra `BACKDOOR CHARGE` cresce por `delta / round_duration` (duração base de 30 s), ganha **+0,06** a cada extração e ganha **+0,12 × honeypot_penalty_mult** no vencimento de honeypot. `trace_progress >= 1.0` encerra a rodada. Não converter a barra silenciosamente em cronômetro.
8. **Upgrades da rodada:** `CRACK SPEED+`, `RADIUS+`, `DEPLOY BOT`; preservar custos de partida, multiplicadores de custo e ganhos de stats. Entradas originais ficam operacionais.
9. **Quatro redes:** `HOME NETWORK`, `OFFICE LAN`, `CORP NETWORK`, `BOTNET ARRAY`; manter multiplicadores, traits, cores de identificação, custos de desbloqueio **0 / 400 / 2500 / 15000**, `chain_crack`, honeypots e swarm exatamente como em `GameState.TIERS`.
10. **Árvore de habilidades:** 10 skills com os IDs `speed1`, `speed2`, `radius1`, `radius2`, `bot1`, `bot2`, `yield1`, `yield2`, `duration1`, `forensics1`. Preservar níveis, preços, upgrades, tooltips e a ausência atual de pré-requisitos rígidos (as linhas hoje são principalmente visuais).
11. **Navegação e resultado:** `NetworkSelect → Main ↔ SkillTree`, voltar às redes, tela `RUN COMPLETE`, resumo de ganhos da run e `BREACH AGAIN` continuam funcionando.
12. **Áudio e debug:** manter todas as chamadas do autoload `Audio` e os argumentos de testes já existentes (`autotest_breach`, `autotest_endround`, `autotest_audio`, `autotest_tier=N`).

**Não adicionar** telas de Inventory, Shop, Achievements, Research, home-office, characters ou hub como funcionalidades falsas só porque aparecem em imagens conceituais do pacote. Elas são referências de direção de arte para projetos futuros; a versão atual do jogo tem **três** telas funcionais principais.

## 3. Importação correta de TODO o asset pack

### 3.1 Caminhos físicos

Extraia apenas a pasta `assets/` do ZIP para um novo namespace, sem sobrescrever o `assets/` existente:

```text
res://
├── assets/
│   └── keep_hacking/
│       ├── props/         # 34 PNGs RGBA 64x64
│       ├── icons/         # 32 PNGs RGBA 32x32
│       ├── tiles/         # 20 PNGs RGBA 32x32
│       ├── fx/            # 26 PNGs RGBA 64x64, divididos em 3 animações
│       ├── ui/            # 16 PNGs (botões, cards, barras, panels, skills)
│       ├── atlases/       # 4 spritesheets opcionais
│       ├── backgrounds/   # 2 fundos demonstrativos: NÃO usar como tela jogável estática
│       └── marketing/     # uso promocional: NÃO importar no runtime
├── scripts/
│   └── visual/            # NOVO: camada de apresentação
└── scenes/
    └── visual/            # NOVO: subcenas reutilizáveis; cenas principais não mudam de caminho
```

**Atenção:** há 34/32/20/26/16 sprites nos grupos acima. Os spritesheets são **cópias organizadas** dos mesmos PNGs; não desenhar o atlas e o PNG individual simultaneamente. Os arquivos `screenshots/`, `concept/`, `assets/asset_catalog.png`, `assets/marketing/`, `prototype.html` e `README_PTBR.md` **não** são elementos de UI executável. Não usar `screenshots/*.png` para simular gameplay.

### 3.2 Parâmetros Godot

- Texturas pixel-art: **Nearest / Point**; desativar filtragem linear nos nós/CanvasItems afetados; considerar pixel snap para evitar jitter e deslocamentos em meio pixel.
- PNGs de props e FX têm transparência; usar canal alpha original e recorte sem bordas indesejadas.
- Props: **64×64** em uma célula de 64×64; tiles: **32×32**, portanto cada célula lógica é composta por **2×2 tiles**; ícones: **32×32**; FX: **64×64**.
- Manter viewport-base 1280×720 e a grade de coordenadas existente. **Não** escalonar os 64px de forma não inteira. Em formatos de tela diferentes, ajustar âncoras/painéis sem deformar os pixels nem mover hitboxes do grid.
- Usar `Sprite2D`, `AnimatedSprite2D`, `AnimationPlayer`, `Tween`, `CPUParticles2D`, `Line2D` e `Control`. Compatível com renderer `gl_compatibility`.
- UI escalável: `NinePatchRect`/`StyleBoxTexture` para bordas e controles; texto e números em `Label`/`RichTextLabel` reais. Um botão **precisa continuar sendo um `Button`** com sinais de input e foco.
- Árvore de UI de decoração deve definir `mouse_filter = Control.MOUSE_FILTER_IGNORE`; controles clicáveis devem receber mouse/teclado normalmente.

### 3.3 Catálogo funcional de sprites — uso por tela

| Categoria do kit | Assets precisos | Integração dinâmica |
|---|---|---|
| Grid / chão | `tiles/grid_a.png`, `grid_b.png`, `circuit_a.png`, `circuit_b.png`, `cable_h.png`, `cable_v.png`, `cable_turn.png`, `grid_alert.png` | TileMapLayer ou desenho em grid com variação seeded; pulsos animados sobre trilhas. |
| Objetos principais | `props/server_rack.png`, `server_cluster.png`, `terminal.png`, `router.png`, `mainframe.png`, `processor.png`, `database.png`, `data_cache.png` | Variações visuais dos `ServerNode` existentes; o gameplay continua igual. |
| Segurança | `props/firewall.png`, `firewall_gate.png`, `secure_node.png`, `encrypted_vault.png`, `security_cam.png`, `vault_door.png` | Visual de bloqueio, alerta e honeypot **sem criar novas regras**. |
| Automação | `props/bot_drone.png`, `proxy_bot.png`, `packet_transmitter.png`, `wifi_beacon.png`, `relay_tower.png` | Ícones/actores que animam os ticks dos bots já existentes. |
| FX | `fx/scan_pulse_00..09.png`, `glitch_00..07.png`, `data_extract_00..07.png` | `AnimatedSprite2D` 1-shot conectado a eventos reais; free ou pool depois do término. |
| HUD | `icons/credits.png`, `exploit.png`, `key.png`, `speed.png`, `scan.png`, `bot.png`, `warning.png`, `network.png`, `tree.png`, `replay.png` | Ícones ao lado dos contadores e botões; valores derivados de `GameState`. O ícone `key` pode representar 0-day com legenda explícita. |
| Cartões / popups | `ui/selection_card.png`, `window.png`, `panel_small.png`, `tooltip.png`, `button_*.png`, `hud_counter.png` | Interfaces compostas, com hover, foco, bloqueio e clique funcionais. |
| Skill Tree | `ui/skill_node.png`, `skill_locked.png`, `skill_available.png`, `skill_active.png`, `icons/bolt.png`, `scan.png`, `bot.png`, `shield.png`, `stealth.png`, `credits.png`, `data.png` | Estados visuais reais dos 10 skills, tooltip com preço e nível atual. |
| Barras | `ui/bar_full.png`, `bar_alarm.png`, `bar_energy.png` | Bordas/molduras; preenchimento gerado por barra real. Não deixar o PNG substituir o valor atualizado. |

**Outros assets do pack não devem ser descartados:** os 34 props, 32 ícones e 20 tiles devem estar importados e mapeados no catálogo central para uso em variantes, ambientação, UI ou eventos. **Não** criar mecânicas extras para forçar o aparecimento de cada imagem numa run. Documentar `asset_coverage.md` com o mapeamento de cada filename para `(tela/componente/futuro uso)`.

## 4. Direção de arte e layout

### 4.1 Identidade visual

- Fundo `#070C1A` / metal `#263952`; texto principal `#D9F5FA`.
- Interação ciano `#45DEF5`; sucesso/READY verde `#42F7A9`; rareza ou exploit roxo `#B26EFF`/magenta `#F14DC9`; honeypot/alarme `#FF5378`; recompensa especial `#FFD971`.
- As **cores por tier de `GameState.TIERS` continuam sendo as cores de identificação das redes**. A paleta do kit complementa, e não substitui, essa semântica.
- Visual limpo e legível em pixel art com densidade de detalhes nas bordas; grade de servidores é o foco, não a decoração.
- Preferir luzes pequenas, partículas, linhas pulsantes, hover responsivo, sombras desenhadas em 2D e animações discretas. Não cobrir valores ou alvos com efeitos.
- Componentes de UI têm bordas de pixel, relevo/normal/hover/pressed e contraste real. A interface não deve parecer uma única ilustração parada.

### 4.2 Mapa de espaço da tela Main (1280×720)

```text
┌──────────────────── HUD TOP 0..115 ────────────────────────────┐
│ counters                    BACKDOOR CHARGE       tier info    │
├────────────┬───────────────────────────────┬──────────────────┤
│ rig visual │ GRID 12x7  | 64px por célula  │ tier / alerts    │
│ x≈28..140  │ x=160..928, y=140..588        │ / run complete   │
│            │ 24x14 tiles de 32px           │ x≈964..1264      │
├────────────┴───────────────────────────────┴──────────────────┤
│ bottom controls / upgrades / navigation: y≈624..720          │
└───────────────────────────────────────────────────────────────┘
```

**Não mover a grade por estética.** O input atual usa posições de servidores no mundo; mudanças de câmera/layout exigem atualizar conversão de coordenadas de input e validação por teste. Com o grid fixo, utilize o espaço lateral para equipamentos decorativos e painéis vivos, sem aumentar o número de nodes lógico-funcionais.

## 5. Arquitetura de implementação (sem reescrever o jogo)

Criar uma camada de **views** separada das regras:

```text
scripts/visual/
    KHArt.gd                   # caminhos de PNG + factory de SpriteFrames
    KHVisualTheme.gd           # paleta, texturas, estados e StyleBoxes reutilizáveis
    NetworkBackdrop.gd         # floor tiles + linhas de rede + energia/pacotes
    ServerNodeVisual.gd        # Sprite2D/FX/barras/hover; nenhuma lógica econômica
    VisualFX.gd                # animações one-shot, pooling/caps, floating texts opcionais
    HackingCursorVisual.gd     # aro do raio e scan ao segurar o clique
    BotVisual.gd               # projéteis/drone de representação do tick do bot
    NetworkCardVisual.gd       # background/ícone/animações de cada tier
    SkillNodeVisual.gd         # skin da habilidade; tooltip ligado ao model
    HUDFactories.gd            # buttons/panels/counters com inputs reais

scenes/visual/
    ServerNodeVisual.tscn      # recomendado; instanciado como filho do ServerNode
    ScanFX.tscn                # opcional; cada ciclo dura pouco
    DataExtractFX.tscn        # opcional
    GlitchFX.tscn             # opcional
    BotVisual.tscn             # opcional
```

Os nomes novos são uma **proposta de organização**; se o agente escolher outra composição, deve manter separação `Model/Logic` versus `View/FX`, documentar os nomes e não alterar o comportamento de scripts existentes.

### Regras de ligação (importantíssimas)

1. **Model manda; View observa.** `GameState` e os campos atuais de `ServerNode` continuam sendo a origem de `Label`, progresso e cor.
2. A View **não** modifica `GameState.credits`, `GameState.exploits`, `GameState.zerodays`, `ServerNode.progress`, trace, costs ou states.
3. `reset_locked()` é chamado em `Main._build_grid()` **antes** do `ServerNode` entrar na árvore. Portanto, `ServerNode._ready()` precisa criar/sincronizar seu visual com o estado que já existe; não se apoiar apenas em sinais emitidos durante `reset_locked()`.
4. `Main._exfiltrate()` deve disparar a animação de extração **antes ou durante** o reset, preservando os dados de tipo (`was_honeypot`, `is_vulnerable`) e posição que darão cor ao efeito.
5. Objetos puramente decorativos não podem receber input do usuário no lugar dos nós nem consumir cliques sobre `Button`.
6. `Main` continua administrando round, bot ticks, input, câmera e recompensas; `ServerNode` administra seu próprio progresso/timeout.
7. Não migrar os controles dos upgrades para cenas novas que obriguem o jogador a mudar de tela a cada compra.

## 6. Fase P0 — Backup, import e checagem de comportamento

- [ ] Criar branch `feature/live-visual-overhaul`; manter tag/commit base para comparação.
- [ ] Executar a versão atual do jogo e registrar screenshots/gravação curtas de **NetworkSelect, Main, SkillTree e RUN COMPLETE**.
- [ ] Registrar saldo/custos/stats antes e depois de 1 compra de cada upgrade; preservar resultados.
- [ ] Copiar o asset pack para `res://assets/keep_hacking/`, verificar texturas e `.import` no editor.
- [ ] Configurar pixel filtering nos sprites e subcenas importados; evitar blur.
- [ ] Criar `KHArt.gd` com caminhos centralizados e nomes exatos (veja §11).
- [ ] Criar `KHVisualTheme.gd` com estilos e fábrica de botão/label/contador, sem trocar semântica de tiers.
- [ ] Não trocar a cena inicial ou alterar autoloads existentes.

**Critério P0:** projeto abre sem erros, assets importados, gameplay idêntico e sem screenshots estáticos no runtime.

## 7. Fase P1 — Servidores realmente vivos (`ServerNode.gd`)

**Este é o trecho de maior impacto na percepção visual do jogo.** O arquivo atual desenha caixas e fechaduras com `_draw()`; deve evoluir para uma composição de sprites sobre a mesma lógica.

### 7.1 Hierarquia proposta do `ServerNode`

```text
ServerNode (Node2D)             # MANTER nome, class_name, métodos e estado
└── VisualRoot (Node2D)
    ├── Shadow (Sprite2D ou desenho procedural)
    ├── Device (Sprite2D)       # PNG 64x64 do pack
    ├── Accent (Node2D/Line2D)  # círculo/outline pulsante por estado
    ├── Progress (ProgressBar)  # reflete ServerNode.progress, 0..1
    ├── ReadyGlow (Sprite2D ou textura + alpha)
    ├── StatusIcon (Sprite2D)   # lock/unlock/warning, 32px ou menor
    ├── HoneypotTimer (Node2D) # arco 2,6s, visível só quando aplicável
    └── LocalFX (AnimatedSprite2D) # scan/glitch/extraction se necessário
```

### 7.2 Escolha e estado de um servidor

- Dispositivos variam entre `terminal`, `server_rack`, `server_cluster`, `router`, `database`, `processor`, `data_cache`, `mainframe`, `access_port`, `code_console`, `secure_node` e semelhantes.
- Escolher a **variante de sprite** de forma reproduzível por célula e tier, usando um `RandomNumberGenerator` local com seed visual. Isso **não deve consumir** o gerador global usado pela criação de nodes, recompensas e bot targets.
- `LOCKED`: prop normal, contorno ciano discreto, cadeado pequeno e progresso real na base.
- `LOCKED` vulnerável (`is_vulnerable`): contorno magenta, pequenos artefatos de glitch; não alterar chance de aparecimento.
- `LOCKED` honeypot: marcador vermelho suficiente para sinalização, mas sem mudar a regra de quando ele é criado.
- `READY` normal: pulso verde, LED aceso, outline suave, micro-levitação visual apenas no Sprite2D (não mover `ServerNode.position`/hitbox).
- `READY` vulnerável: combinar status READY com identidade visual magenta de exploit; manter recompensa de exploit.
- `READY` honeypot: vermelho pulsando mais rápido e arco de timeout **sincronizado com `HONEYPOT_LIFETIME`**.
- `reset_locked()`: interromper animação anterior, zerar barra/overlay, sincronizar nova aparência; limpar Tweens antigos.
- `add_progress()`: refletir continuamente `progress`; transição LOCKED→READY ativa **uma única** animação curta, não a cada frame.
- `honeypot_expired`: continuar emitindo o sinal original uma vez e deixar `Main._on_honeypot_expired` executar a penalidade.

### 7.3 Vida contínua, sem efeitos cansativos

- LEDs piscando em ciclos defasados por célula (0,7 a 2,5s).
- Progresso de cracking claramente visível, com scan_pulse que segue o input (não um loop eterno sobre todas as células).
- Hover: borda/cursor que acende e tooltip rápido `LOCKED`, `READY`, `EXPLOIT` ou `HONEYPOT` quando aplicável; não bloquear visão da célula.
- READY: pulse de escala **1.0 → 1.045 → 1.0** ou alpha; duração 0,8–1,3s, com diferença entre dispositivos.
- Redução de piscadas intensas; opção visual *Reduced Motion* sem impacto na simulação.

**Critério P1:** 50+ servidores na tela podem apresentar estados diferentes; cada um permanece clicável na mesma posição lógica; extração/timeout/reset geram visual consistente. Nenhuma textura de screenshot substitui `ServerNode`.

## 8. Fase P2 — Tabuleiro como sistema de rede ativo (`Main.gd`)

### 8.1 Chão / cenário

Substituir apenas `Main._build_background()` e partes decorativas de `_draw_circuit_decor`/`_draw_grid_lines` por uma camada com tiles. **Manter** `GRID_COLS`, `GRID_ROWS`, `CELL` e `GRID_ORIGIN`.

- Para a área exata da grade, desenhar 24×14 tiles de 32px com `grid_a`, `grid_b`, `deck_a`, `deck_b`, `circuit_a/b`. Alternar variações seeded, sem flicker aleatório do chão.
- Cabos `cable_h`, `cable_v`, `cable_turn` conectam alguns nodes. Renderizar linhas/pacotes móveis por cima dos cabos, por baixo dos dispositivos.
- Sombreamento, rack lateral e equipamentos decorativos usam `server_cluster`, `cooling_fan`, `satellite_dish`, `relay_tower`, `antenna`, `neon_crate`, `signal_orb` etc., **fora da área clicável** quando forem props decorativos.
- Cada rede pode ter quantidade/cores de detalhes distinta, mas **não** alterar spawn/celularidade do jogo por causa da arte.
- A imagem `backgrounds/ui_blue_background_1280x720.png` não deve ser o gameplay inteiro: é referência de composição, não substituta de um ambiente construído em layers.

### 8.2 Movimento ambiental real

- **Network packets:** pontos verdes/cianos com `Line2D` ou sprites pequenos movendo-se nas linhas entre equipamentos (20–40 partículas máximas em qualidade alta; menos em baixo).
- **Scanner:** aro no cursor usando `GameState.decrypt_radius` e `mouse_pos`, efeito intermitente quando `is_decrypting == true`; **não** criar raio de scanner fictício.
- **Data exfiltration:** `data_extract_00..07` + partículas que se deslocam do node para o HUD ao exfiltrar (apenas apresentação); número flutuante é a recompensa real retornada por `_exfiltrate()`.
- **Bots:** representar ticks de `bot_timer` com um drone/pacote saindo da lateral e indo ao alvo que `_find_locked_node()` **já escolheu**. Nunca deixar o drone escolher outro alvo para mudar gameplay.
- **Honeypot:** `glitch_00..07`, rápida virada da cor do tile sob o servidor, efeito de alarme quando `honeypot_expired` é emitido.
- **End round:** breve wave de scan com `_end_round()` e depois exibir summary animado, sem atrasar transição lógica.
- **Feedback dos tiers:** leve variação de tonalidade, backgrounds e props; não ocultar o status por estética.

### 8.3 Implicações do `Main` atual

- `_build_grid()` chama `ServerNode.new()`, seta `position`, chama `reset_locked(...)` antes de `add_child(n)`, conecta `honeypot_expired` e adiciona o servidor ao `nodes_layer`. Integrar por `ServerNodeVisual` sem quebrar esta sequência.
- `_exfiltrate(n)` dá créditos/exploits, aumenta `trace_progress`, cria `_spawn_burst`, `_spawn_floating_text`, reseta o node e às vezes dá `CHAINED`. **Acrescentar** FX visuais aos pontos já existentes em vez de reescrever os cálculos.
- `_process(delta)` cuida de input, automação, trace e câmera. Mover apenas renderização muito cara para os componentes visuais. Não introduzir um segundo tick de jogo em `VisualFX`.
- `_draw()` desenha aro do clique; caso se substitua por componente de cursor, manter update de raio em tempo real e coordenadas no mesmo espaço visual do grid.
- Preservar câmera e shake já existentes, refinando amplitude visual sem causar erros de hitbox.

**Critério P2:** de forma contínua há LEDs, trilhas de rede e bot animations mesmo sem clicar, e há resposta imediata durante o hacking. Ao desligar/reduzir os FX, o gameplay funciona sem diferenças.

## 9. Fase P3 — HUD real, com arte de UI, sem números falsos

### 9.1 Header

- **Contadores reais:** `GameState.credits`, `GameState.exploits`, `GameState.zerodays`; ícones `credits`, `exploit`, `key` com texto explícito de cada recurso.
- Cada contador recebe um *pop* de ~140ms ao mudar e cor contextual do ganho. Não interpolar saldo como se ele fosse o valor lógico, só interpolar o número **exibido** se isso não gerar confusão.
- **Trace:** moldura `ui/bar_full.png` / `bar_alarm.png` e `ProgressBar` real com valor **`trace_progress` de 0 a 1**. Estado visual muda com progressão (verde→amarelo→vermelho) por thresholds cosméticos; o tempo da rodada continua igual.
- O texto `BACKDOOR CHARGE` e o nome/trait real do tier permanecem visíveis.

### 9.2 Rodapé

- Botões atuais `CRACK SPEED+`, `RADIUS+`, `DEPLOY BOT`, `SKILL TREE`, `NETWORKS` continuam no mesmo fluxo. Usar `ui/button_primary/secondary/disabled.png` com `StyleBoxTexture` ou `NinePatchRect` como fundo e um `Button` real acima.
- Exibir ícones `speed.png`, `scan.png`, `bot.png`, `tree.png` junto de label e custo real.
- Botões indisponíveis ficam desaturados mas legíveis; custo atualizado **depois** de comprar. Hover/pressed com resposta em menos de 100ms e sem alterar compra.
- `mouse_filter` correto: nenhum clique nos botões pode iniciar cracking atrás do HUD.

### 9.3 Painel de fim de rodada

- Fazer do `summary_panel` uma janela com `ui/window.png` e **Labels reais** conectadas aos valores já calculados de `round_start_*` e `GameState`.
- Animar entrada, borda de sucesso, escala dos números e botões `BREACH AGAIN`/navegação. Não contar duas vezes os recursos nem mudar quando `_end_round()` é chamado.
- Usar `fx/data_extract` apenas como feedback, nunca substituir o panel por uma imagem pronta.

**Critério P3:** contadores, custos e barra respondem aos eventos do jogo e os botões continuam clicáveis via mouse/teclado; nenhuma barra do mockup é decorativa fingindo dados.

## 10. Fase P4 — Seleção de redes (`NetworkSelect.gd`)

- Manter 4 cards e posições responsivas. Usar `ui/selection_card.png` como base com NinePatch se necessário e os sprites `server_cluster`, `router`, `firewall_gate`, `mainframe` como emblemas **com pequenas animações de luz**.
- Preservar nome, trait, multiplicador, custo, lock status de **cada `GameState.TIERS[i]`**, sem inventar outras redes.
- Unlocked: `BREACH ▸` chama `_on_breach(i)`; Locked: `UNLOCK` chama `_on_unlock(i)` e `GameState.try_unlock_tier(i)`.
- Card hover: transição de borda/iluminação e pacote que percorre linha vertical; card locked: contraste suficiente, cadeado `icons/lock.png`, leve pulsação lenta.
- Os três contadores do rodapé têm valores reais e `SKILL TREE` segue abrindo `scenes/SkillTree.tscn`.
- Cursor de terminal e fundo de grid podem continuar animados; trocar linhas primitivas por ambiente em camadas, **sem** usar uma imagem completa da tela como background.

**Critério P4:** as quatro redes continuam funcionando nos mesmos custos/fluxos; bloqueios permanecem bloqueios; a tela parece viva mesmo quando nenhuma rede é clicada.

## 11. Fase P5 — Skill Tree (`SkillTree.gd`)

- Manter os **10 IDs** e suas posições/fluxos de clique; valor e efeito vêm de `SkillDef` e `GameState` atuais.
- Visual dos nós: `skill_locked`, `skill_node`, `skill_available`, `skill_active` e ícone conforme skill. IDs antigos têm ícones `bolt2`, `scan2`, `bot2`, `cash`, `diamond`, `clock` que **não existem com esses nomes** no pack: mapear apenas visuais (`bolt2→bolt`, `scan2→scan`, `bot2→bot`, `cash→credits`, `diamond→data`, `clock→stealth`) sem renomear IDs ou mudar efeitos.
- Linhas entre os nós: mover pequenos pacotes/pulsos; linha acesa para habilidade comprada, mas **não sinalizar pré-requisitos falsos**: o jogo atual permite comprar qualquer skill desde que o jogador tenha créditos e não esteja no nível máximo.
- `tooltip.png` como moldura: título, efeito, nível atual, próximo custo, máximo. O texto sempre é derivado de `SkillDef` e `levels[s.id]`.
- Hover anima glow; aquisição dispara expansão breve/ripple no nó correspondente e reproduz o `Audio.play_upgrade()` existente.
- Botões de voltar ao jogo/rede permanecem funcionais e preservam os caminhos de cena.

**Ponto de atenção:** `levels` é atualmente um dicionário de instância reinicializado em `_define_skills()`. Não salvar/recuperar níveis como uma alteração escondida de arte. Se o responsável desejar corrigir persistência depois, abrir uma tarefa separada com migração de estado e testes.

**Critério P5:** toda skill compra exatamente os mesmos upgrades pelo mesmo preço e as linhas/ícones da árvore respondem ao status real, sem adicionar novos bloqueios.

## 12. Fase P6 — Biblioteca de FX e movimento

### 12.1 Sequências presentes no kit

| Nome base / PNGs | Frames | FPS proposto | Evento real |
|---|---:|---:|---|
| `scan_pulse_00.png` ... `_09.png` | 10 | 15–18 | Início do scanning no cursor / avanço de hacking. |
| `glitch_00.png` ... `_07.png` | 8 | 14–18 | Node vulnerável / honeypot, alarme, bloqueio negado. |
| `data_extract_00.png` ... `_07.png` | 8 | 16–20 | `_exfiltrate` recompensa recebida ou chain. |

**Importante:** não disparar `scan_pulse` novo a cada `_process` de 60 FPS. Limitar taxa (cooldown) e/ou instanciar uma única animação persistente no cursor durante `is_decrypting`. `AnimatedSprite2D` one-shot precisa liberar o nó quando terminar (`animation_finished`).

### 12.2 Tabela de triggers completa

| Trigger do código atual | Feedback visual | Sons existentes | Mudanças permitidas |
|---|---|---|---|
| Mouse down no grid | scan circle pulsa + efeito de pulso | `play_tick` em intervalos do código | Somente apresentação. |
| Progresso de node `LOCKED` | barra enche, luz aumenta de brilho | tick já existente | Não alterar `decrypt_speed`. |
| `add_progress` atinge 1.0 | flash green, status `READY`, pequena faísca | pode reutilizar evento visual | Nenhuma recompensa antes de exfiltrar. |
| `_exfiltrate` normal | partícula de dados + número real | `play_exfiltrate` | Manter `credits` exatos. |
| `_exfiltrate` vulnerável | efeito roxo e `+1 EXPLOIT` | `play_exploit` | Manter exploit +1. |
| `_exfiltrate` honeypot | vermelho, reward real, glitch | `play_exploit` | Preservar ganho e reset. |
| `_on_honeypot_expired` | flash de alerta/red floor/shake | `play_denied` | Preservar penalidade do trace. |
| Tique automático bot | drone ou pacote via tween até target escolhido | nenhum som obrigatório | Manter alvo/intervalo/dano originais. |
| Chain crack | pulso ciano até node auto-crackeado | som existente opcional | Preservar chance e target. |
| Upgrade compra sucesso | botão se acende + ripple ícone | `play_upgrade` | Preservar fórmula. |
| Compra falha | vermelho breve no botão | `play_denied` | Preservar saldo. |
| `_end_round` | onda geral + summary real | `play_breach` | Preservar rewards e duração. |

### 12.3 Comportamento vivo obrigatório, inclusive com ocioso

Pelo menos **quatro** tipos simultâneos e independentes de movimento devem existir em Main quando a rodada está ativa, **mesmo sem clicar**: (1) LEDs e monitores dos props piscando em tempos diferentes; (2) pacotes de dados circulando em cabos reais desenhados; (3) contador/trace/tier reagindo em tempo real; (4) elementos ambientais leves (ventoinha girando, oscilação de antena, scan de radar ou monitor animado). Quando existe ação do jogador, acrescentar FX de cracking/extraction e bots.

**Proibido:** plano de fundo de screenshot com overlays de números, sprite de tela completa sendo a interface, vídeo pré-renderizado como gameplay, animações sem correlação com os estados reais ou CanvasItem `_draw()` redesenhando centenas de texturas sem motivo a cada frame.

## 13. Snippets GDScript de referência (Godot 4.x)

> Estes snippets são **pontos de partida** para implementação, não substituem a inspeção das cenas e a validação no editor Godot. Adapte tipos/nomes conforme necessário, evitando lógica duplicada.

### 13.1 `scripts/visual/KHArt.gd`

```gdscript
extends RefCounted
class_name KHArt

const ROOT := "res://assets/keep_hacking/"

static func tex(group: String, name: String) -> Texture2D:
    var path := "%s%s/%s.png" % [ROOT, group, name]
    if not ResourceLoader.exists(path):
        push_warning("Missing Keep Hacking asset: " + path)
        return null
    return load(path) as Texture2D

static func fx_frames(prefix: String, count: int, fps: float = 16.0) -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.add_animation(&"run")
    frames.set_animation_speed(&"run", fps)
    frames.set_animation_loop(&"run", false)
    for i in range(count):
        var img := tex("fx", "%s_%02d" % [prefix, i])
        if img != null:
            frames.add_frame(&"run", img)
    return frames
```

**Nota de performance:** prefira cachear cada `SpriteFrames` em um dicionário/Resource comum, em vez de recriar frames/`load` para cada trigger de efeito. Verificar `get_frame_count("run") > 0` antes de dar `play()`.

### 13.2 Exemplo de FX one-shot sem screenshot

```gdscript
# Função a ser alojada numa classe de VisualFX; "parent" é um Node2D
# já inserido na árvore de cena; global_position deve estar em mundo 2D.
static func play_fx(parent: Node2D, world_pos: Vector2,
        fx_name: String, count: int, fps: float = 18.0) -> void:
    var frames := KHArt.fx_frames(fx_name, count, fps)
    if frames.get_frame_count(&"run") == 0:
        return
    var sprite := AnimatedSprite2D.new()
    sprite.sprite_frames = frames
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    parent.add_child(sprite)
    sprite.global_position = world_pos
    sprite.z_index = 15
    sprite.animation_finished.connect(sprite.queue_free, CONNECT_ONE_SHOT)
    sprite.play(&"run")

# Pontos de ligação sugeridos, sem alterar cálculos:
# Main._exfiltrate(n): VisualFX.play_fx(fx_layer, n.global_position, "data_extract", 8)
# Main._on_honeypot_expired(n): VisualFX.play_fx(fx_layer, n.global_position, "glitch", 8)
# Cursor (throttled): VisualFX.play_fx(fx_layer, mouse_pos, "scan_pulse", 10)
```

Se o método for `static`, valide no editor o acesso a `CONNECT_ONE_SHOT`/constantes; alternativamente use `Object.CONNECT_ONE_SHOT` conforme a API exata do build instalado.

### 13.3 Adicionar sinais visuais sem quebrar `ServerNode`

```gdscript
# Acrescentar ao ServerNode.gd (sem remover os métodos existentes):
signal visual_state_changed
signal visual_progress_changed(value: float)

# Ao fim de reset_locked():
visual_state_changed.emit()
visual_progress_changed.emit(progress)

# Em add_progress(), depois da atualização do progresso:
visual_progress_changed.emit(progress)
# No trecho em que state vira READY:
visual_state_changed.emit()

# Em ServerNode._ready(), depois de instanciar a view:
# view.sync_from_model(state, progress, is_vulnerable,
#     is_honeypot, honeypot_t, HONEYPOT_LIFETIME)
```

Não mudar `honeypot_expired(node)` nem sua conexão em `Main._build_grid`. Se a view optar por ler o modelo no `_process`, fazer isso apenas para interpolação cosmética; ela não pode alterar o modelo.

### 13.4 Input robusto, mantendo clique e segurar

`Main.gd` hoje usa `_input(event)` com `event.position` para procurar nodes. Se o HUD receber novos componentes clicáveis, a maneira mais segura é **avaliar** migrar o input da jogabilidade para `_unhandled_input(event)` e usar a posição correta na mesma coordenada de `ServerNode.position` (por exemplo, `get_global_mouse_position()` após transformação da câmera). Essa migração deve preservar exatamente estes resultados:

- clicar `READY`: chama `_exfiltrate(node)` e não inicia ação de compra;
- pressionar em chão sem node READY: inicia `is_decrypting = true`;
- soltar: para `is_decrypting`;
- clicar botões UI: aciona só o botão, sem cracking inadvertido;
- mover o mouse com o clique segurado: o raio acompanha o mouse no espaço do tabuleiro;
- camera shake não desloca a seleção para um servidor vizinho.

**Atenção:** não trocar `_input` por `_unhandled_input` sem testar controles, `mouse_filter`, press/release em HUD e cena principal após camera shake.

### 13.5 Estados cosméticos não determinísticos ≠ RNG de gameplay

```gdscript
# Exemplo de escolha reprodutível de sprite local à view.
# "visual_seed" pode vir do índice da célula e selected_tier.
func pick_visual_variant(visual_seed: int) -> String:
    var options := ["terminal", "server_rack", "router", "database",
        "processor", "server_cluster", "mainframe", "data_cache"]
    var rng := RandomNumberGenerator.new()
    rng.seed = visual_seed
    return options[rng.randi_range(0, options.size() - 1)]
```

Não chamar `randomize()` nem consumir o `randf()` global **a mais** durante inicialização das views, pois a ordem de random no jogo decide quantos nodes aparecem, quais são vulneráveis e os próximos targets dos bots.

## 14. Performance, experiência e acessibilidade

### 14.1 Orçamento recomendado

- Alvo: 60 FPS em desktop 1080p com `gl_compatibility`, mantendo input suave.
- Até ~65 nodes típicos visíveis; sprites estáticos apenas mudam textura/cor quando o estado muda.
- 1 efeito de cursor persistente enquanto cracking; até 20–30 partículas móveis ambientais; até 20 FX one-shot simultâneos, cap/pool quando necessário.
- `NetworkBackdrop` estático não usa `queue_redraw()` todo frame. Separar `BackdropStatic` de `BackdropAnimated`.
- Nenhum `Tween` criado toda frame para o mesmo LED; 1 Tween de loop por elemento necessário ou pulso por `sin(TIME + phase)` atualizado de forma econômica.
- O visual pode ser atenuado/desativado sem modificar `GameState`; opção `FX Low/Medium/High` e `Reduced Motion` pode ser local ao processo.
- Texto legível com fundos escuros; ícones **sempre acompanhados de label ou tooltip** para interpretação de recursos.
- Teclado/foco dos `Button` não pode regredir; hover/touch devem ter estados equivalentes quando aplicável.

### 14.2 Atenção ao renderer e resolução

- O projeto já usa `gl_compatibility`; não exigir glow HDR/CompositorEffect para que o visual funcione. Em vez disso, usar duplicação moderada do sprite para glow 2D, alpha blend, linhas leves e partículas normais.
- Pixel snap e filtros nearest evitam borrão; testar efeitos de movimento com snapping para não dar tremedeira.
- Testar `1280×720` e uma tela widescreen maior; o tabuleiro mantém proporção 1:1 e as áreas extras têm decoração, **não** jogo deslocado.
- Desativar interações em decorações para não atrapalhar o input.

## 15. Sequência de implementação sugerida

1. **Commit A — Import + Theme:** asset pack e `KHArt/KHVisualTheme`; sem alterações perceptíveis de gameplay.
2. **Commit B — ServerNodeVisual:** 12×7 grid com sprites, barra real, lock/ready/vulnerable/honeypot; screenshot comparativa.
3. **Commit C — Board + Network FX:** pisos, cabos, animações de ambiente, scan sob input, exfil e bots.
4. **Commit D — HUD + Summary:** contadores e progressbar reais com UI do kit; nenhum input atrás de botão.
5. **Commit E — NetworkSelect:** cards das quatro redes com pulse/hover/lock; desbloqueios idênticos.
6. **Commit F — SkillTree:** 10 skills, estados e tooltip; sem mudar skill effects/prices.
7. **Commit G — Polish + Accessibility + QA:** otimização, screenshot/capture real, áudio, verificações de regressão e documentação de cobertura de assets.

Cada commit deve passar um smoke test. Se um passo falhar, desfazer **apenas o componente visual** do passo, nunca desabilitar regra do jogo para a arte parecer correta.

## 16. Testes de regressão (obrigatórios)

### 16.1 Baseline técnico

Com Godot instalado no ambiente de implementação, verificar projeto e cenas. Os argumentos `autotest_*` já constam no código atual; usar, quando possível, a execução via debug e observar o console:

```bash
# Ajustar o caminho de godot/godot4 conforme o executável do ambiente.
godot --headless --path . --quit-after 120 -- autotest_breach
godot --headless --path . --quit-after 120 -- autotest_endround
godot --headless --path . --quit-after 120 -- autotest_audio
```

**Nota:** `--headless` serve para import/parser/smoke de lógica e não prova qualidade visual. Inspecionar manualmente o jogo rodando com renderização gráfica real. O projeto pode não ter testes automatizados completos; não reportar coverage inexistente.

### 16.2 Plano de QA funcional

- [ ] `NetworkSelect`: todas as quatro redes aparecem; locked/unlocked correto; unlock desconta valor correto; status muda após compra; `BREACH` entra no tier selecionado.
- [ ] `Main`: spawn mantém 12×7/64; posição do cursor/raio bate com sprites; click hold cracka locked; READY extrai; progressbar do node enche e zera no reset.
- [ ] Resources: créditos normais, exploit quando vulnerável, honeypot e 0-days refletem o **modelo**, não valores de screenshot.
- [ ] Trace: aumenta no tempo, em cada exfil e em honeypot timeout nas mesmas quantidades do código-base; termina uma vez.
- [ ] Bot: automático continua operando e visual segue o **mesmo alvo** da lógica; `swarm_bots` tem dois alvos por ciclo.
- [ ] Tier trait: lateral movement/chain crack e honeypots funcionam como antes.
- [ ] In-run upgrades: custos base e multiplicadores preservados; compra bem-sucedida e compra sem saldo corretas; botões nunca disparam cracking atrás.
- [ ] `SkillTree`: 10 skills; preços e níveis; `MAX`; tooltip correto; links decorativos não bloqueiam compra; voltar ao jogo/redes funciona.
- [ ] Round end: `RUN COMPLETE`, ganhos medidos desde o início da run, `BREACH AGAIN`, navegação e SFX.
- [ ] FX: animações terminam e fazem `queue_free`; não acumulam nós indefinidamente; todos os PNGs usados têm alpha e filtro nearest.
- [ ] Zero screenshots estáticos no runtime: `res://assets/keep_hacking/backgrounds/*`, `concept/*` e `screenshots/*` não são cenas de gameplay prontas.
- [ ] Acessibilidade: leitura de texto, contraste de locks/READY/honeypots, reduced motion, input do mouse, foco de teclado.
- [ ] Performance: comparação de frame time, nodos vivos, memória e contagem de FX após 10 minutos de jogo.
- [ ] Crashes/errors/warnings: nenhum novo erro de parser GDScript, recurso inexistente ou `Node freed` nos efeitos.

### 16.3 Matriz visual: captura do jogo em execução

| Capture obrigatória | O que deve comprovar |
|---|---|
| Main sem clique | Cabos/pacotes/LEDs/ambiente se movem; nada é screenshot colado. |
| Main segurando clique | Scanner no cursor com raio real e progressbars reativos. |
| Main READY / exploit / honeypot | Estados visualmente diferentes e fáceis de ler. |
| Main bot ativo | Movimento do bot aponta ao alvo realmente escolhido. |
| Main rodada finalizada | Summary animado, dados verdadeiros e ação BREACH AGAIN. |
| NetworkSelect | 4 cards reais com locked, desbloqueado e hover. |
| SkillTree | 10 skills, preços e tooltip, linhas animadas sem dependência falsa. |

**Melhor evidência:** gravação de 15–30 segundos do jogo real mostrando ao mesmo tempo ambiente ocioso, hacking manual, exfil, bot e UI reagindo.

## 17. Definição de concluído (DoD)

A migração está completa **somente** se todos os itens forem verdadeiros:

- [ ] O projeto importa/roda no Godot configurado e tem todas as texturas necessárias sem faltas.
- [ ] Gameplay, quantidades, compras, runtime states, cena inicial, navegação e áudio permanecem iguais ao baseline.
- [ ] Os scripts `GameState.gd` e `Audio.gd` mantêm suas APIs e o jogo usa os mesmos recursos sem estado duplicado.
- [ ] As três telas reais (`NetworkSelect`, `Main`, `SkillTree`) receberam skin visual consistente do asset pack.
- [ ] O tabuleiro de 12×7 tem dispositivos visuais por node, highlights de status, barras de progresso ligadas ao model e FX por evento.
- [ ] A interface é funcional e montada de componentes Godot; **nenhuma screenshot, imagem única de UI, mockup nem vídeo** serve de gameplay.
- [ ] Existem LEDs, pacotes, efeitos/scan, bots e transições com movimento independente no cenário.
- [ ] `RUN COMPLETE`, upgrades, unlock de tiers e tooltips mostram dados reais.
- [ ] O jogo roda com 60 FPS-alvo na máquina de referência, sem geração excessiva de nós por frame.
- [ ] O desenvolvedor entregou vídeos/screenshots do runtime, lista de arquivos modificados e checklist de regressão preenchido.

## 18. Pendências propositalmente FORA do escopo

1. Alterar economia, chances, dificuldade, velocidades, round duration, desbloqueios ou tipos de recurso.
2. Adicionar cenas de Hub/Shop/Inventory/Research/Achievements, personagens ou história que ainda não existem.
3. Criar/refatorar save persistente; corrigir o `levels` da SkillTree sem aprovação explícita.
4. Remover os testes de debug existentes.
5. Usar imagens promocionais e screenshots do asset pack como UI jogável.
6. Substituir o jogo atual por outro protótipo, mesmo que visualmente semelhante aos conceitos do pacote.

## 19. Recursos para consulta

**Código-base consultado:**

- `project.godot`: https://github.com/rfonseca85/keep-hacking/blob/main/project.godot
- `GameState.gd`: https://raw.githubusercontent.com/rfonseca85/keep-hacking/main/scripts/GameState.gd
- `Main.gd`: https://raw.githubusercontent.com/rfonseca85/keep-hacking/main/scripts/Main.gd
- `ServerNode.gd`: https://raw.githubusercontent.com/rfonseca85/keep-hacking/main/scripts/ServerNode.gd
- `NetworkSelect.gd`: https://raw.githubusercontent.com/rfonseca85/keep-hacking/main/scripts/NetworkSelect.gd
- `SkillTree.gd`: https://raw.githubusercontent.com/rfonseca85/keep-hacking/main/scripts/SkillTree.gd
- `Audio.gd`: https://raw.githubusercontent.com/rfonseca85/keep-hacking/main/scripts/Audio.gd

**Godot 4 — referências de API:**

- `AnimatedSprite2D`: https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html
- `SpriteFrames`: https://docs.godotengine.org/en/stable/classes/class_spriteframes.html
- `NinePatchRect`: https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html
- `TileMapLayer / TileMaps`: https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html
- `Control` / `mouse_filter`: https://docs.godotengine.org/en/stable/classes/class_control.html

**Fontes internas do kit:** `Keep_Hacking_Asset_Pack/manifest.json` (names/dimensions), `README_PTBR.md` e `assets/asset_catalog.png`. Estes são artefatos auxiliares, não dependências de gameplay.

---

### Resultado desejado

O jogador continua **jogando o mesmo Keep Hacking**, com a mesma grade, o mesmo clique pressionado, os mesmos bots, os mesmos 4 tiers e as mesmas 10 habilidades. A diferença é que agora ele vê um **ambiente hacker vivo**: servidores animados, linhas de dados e packets, scanner que acompanha o mouse, recursos que reagem às ações, firewalls/alerts contextualizados, interfaces com sensação de profundidade, bot automation visível e partículas ligadas às extrações. **Tudo em tempo real, tudo montado no Godot, sem telas de gameplay estáticas.**
