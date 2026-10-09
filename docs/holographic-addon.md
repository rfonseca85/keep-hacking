# Keep Hacking — Holographic Network (Conceito 2)

## 1. Objetivo e critério de sucesso

Aplicar ao jogo existente a estética da **segunda imagem aprovada**: mapa holográfico, HUD modular, consoles neon, dados circulando, transições visualmente ricas, mas com legibilidade e espaçamento para o jogo de verdade. **Não construir gameplay a partir de uma screenshot**. Não modificar nenhuma mecânica ou a identidade dos recursos existentes.

O resultado deve ser uma **interface Godot real e animada** que acompanha 52 texturas novas (com subset utilizado na v1 e demais assets disponíveis para evolução) e aproveita as classes e animações pré-existentes do projeto.

## 2. Leitura do repositório no momento da preparação

Projeto público: <https://github.com/rfonseca85/keep-hacking>. Foram revisados `project.godot`, `scenes/Main.tscn`, `scripts/game/Main.gd`, `scripts/game/ServerNode.gd`, `scripts/game/NetworkSelect.gd` e `scripts/game/SkillTree.gd` em 09/10/2026. O projeto declara Godot 4.7, renderer GL Compatibility, base 1280×720. Pode haver alterações adicionais posteriores: **o código atual do seu checkout é sempre a fonte da verdade**.

- `Main.gd` possui `GRID_ORIGIN = (160, 140)`, `CELL = 64`, grade lógica de 12×7 e `cells: Array[ServerNode]` com quantidade controlada por `GameState.max_nodes`.
- `Main.gd` usa `KHArt`, `VisualFX`, `Audio`, `HunterLayer`, HUD real, botões de navegação e ultimato. A renderização do grid e elementos do Rig já é procedural.
- `ServerNode.gd` concentra o estado `LOCKED/READY`, vulnerabilidade, honeypot, `add_progress`, `reset_locked` e o método `_draw_device`, que desenha `device_tex` numa área normal de **42×42 px**. Por isso os 12 sprites pequenos têm precisamente 42×42 pixels.
- `NetworkSelect.gd` e `SkillTree.gd` têm UI que precisa continuar viva e clicável. **Não remover suas cenas, botões, slots de habilidade, verificações de desbloqueio ou efeitos de som.**
- Atenção: a Skill Tree do repositório publicado hoje inclui funcionalidades além das descritas no `KEEP_HACKING_GODOT_VISUAL_IMPLEMENTATION.md` antigo. Use os IDs, níveis e regras do checkout mais recente; **não** os congele a uma lista antiga.

## 3. Fluxo de instalação seguro

```bash
# Faça um commit no projeto antes de qualquer alteração.
python3 install.py --repo /path/to/keep-hacking --dry-run
python3 install.py --repo /path/to/keep-hacking
# Abra o project.godot no Godot e deixe terminar a importação.
```

O instalador confere a existência dos três arquivos, localiza pontos de inserção precisos, faz backup dos originais e adiciona um pequeno trecho após a chamada:

| Arquivo | Ponto exato | Conteúdo injetado |
| --- | --- | --- |
| `scripts/game/Main.gd` | após `_setup_hud()` da função `_ready()` | instancia `HoloRuntime` e fornece o nó `Main` |
| `scripts/game/NetworkSelect.gd` | após `_style_bottom_bar()` em `_ready()` | instancia `HoloMenuRuntime` |
| `scripts/game/SkillTree.gd` | após `_bind_skill_cards()` em `_ready()` | instancia `HoloMenuRuntime` |

O conteúdo funcional pré-existente não é substituído. **O instalador não é um patch validado numa cópia local do GitHub** porque não foi possível clonar o repositório neste ambiente; seus pontos de inserção foram conferidos nos arquivos públicos. Se não encontrar exatamente um marcador, interrompe a instalação antes de editar os arquivos. Execute sempre `--dry-run` primeiro.

O argumento `--main-only` permite aplicar apenas o primeiro gancho. `--remove-hook` remove o bloco de código `KH_HOLOGRAPHIC_BEGIN/END` com backups, preservando os assets no disco. Para um rollback completo, prefira também `git restore` sobre os três scripts e remova `addons/kh_holographic/` após confirmar que não há dependências.

## 4. Arquitetura dos componentes vivos

| Componente | Responsabilidade | Atualização | Input |
| --- | --- | --- | --- |
| `HoloRuntime.gd` | bootstrap e aplicação de estilos | uma vez | nenhum |
| `HoloNetwork.gd` | trilhas, pulsos nas conexões, scanline móvel, animação READY, sprite mapping | render a até 30 FPS, busca estados a ~5,5 Hz | nenhum |
| `HoloTelemetry.gd` | mapa, radar, lista dos nós, barras de progresso e log de ganhos reais | render a até 20 FPS, lê recursos a ~5,5 Hz | `MOUSE_FILTER_IGNORE` |
| `HoloStyler.gd` | StyleBoxTexture em `Panel`, `Button`, `ProgressBar`; estados normal/hover/pressed | uma vez | preserva botões nativos |
| `HoloMenuRuntime.gd` | skin parcial de NetworkSelect e SkillTree | uma vez | nenhum |
| `HoloMenuAmbient.gd` | partículas sutis no fundo dos menus | render a até 20 FPS | nenhum |

Importante: as conexões entre os nós são uma **visualização cosmética de proximidade**; não representam uma regra de roteamento ou recursos inventados. O mapa à direita é a *base visual* de um minimapa, e o radar é desenhado dinamicamente por Godot; o jogo ainda não oferece mapa mundial funcional. O log mostra apenas deltas efetivos de `GameState.credits`, `GameState.exploits` e `GameState.zerodays` (além do evento inicial “LINK ESTABLISHED”). Não gera eventos de gameplay falsos.

## 5. Como o visual dos nós se conecta à mecânica real

`HoloNetwork` observa a coleção de `ServerNode` sem emitir sinais novos nem mexer em seus timers. Uma vez por novo nó, associa apenas `device_tex` a uma textura opcional do pacote `sprites_game`, com fallback para os sprites originais (`KHArt`) caso a variante não possua correspondência. A nova textura respeita a mesma área de desenho de `ServerNode`, portanto não altera hitboxes, raio de cracking ou distâncias lógicas.

A transição efetiva `LOCKED → READY` desencadeia uma onda radial cosmética. Um `READY` com `is_honeypot` gera pulso vermelho, e um nó comum gera pulso verde. O código de gameplay original continua responsável por extração, timeout de honeypot, FX e música; este pacote **não** duplica a recompensa nem despacha cliques.

## 6. Layout para 1280×720

| Região | Coordenadas | Conteúdo |
| --- | --- | --- |
| HUD principal existente | topo / esquerda | três recursos e estabilidade, mantendo seus valores |
| Rig existente | x≈28–140 | stats e leds já renderizados pelo jogo |
| Gameplay existente | x=160–928, y=140–588 | grid lógico 12×7 / nós atuais, sem alteração de posição |
| **NOVO painel de telemetria** | x=949–1257, y=137–555 | mapa com radar animado, lista de nós ativos e ganhos |
| Botões existentes | faixa direita inferior | NETWORKS e SKILL TREE preservados e reestilizados |

O painel deve ficar entre grid e botões atuais. Em aspect ratios diferentes, é necessário revisar as margens de HUD e a posição do painel; o add-on prioriza o layout nativo 1280×720. Não aumentar a quantidade de nós nem inventar sistemas só para copiar a densidade de servidores do conceito aprovado.

## 7. Direção de arte e importação

- Base: azul quase preto (`#061221`), metal azul (`#12304A`), cyan interativo (`#2FE8F2`), verde READY (`#39F7AE`), magenta para exploração (`#F8419F`), âmbar para prioridade (`#F5CC56`), vermelho para alarme.
- Os PNGs de 128×128 são artmasters para decoração e futura UI; os PNGs de 42×42 são renderizados dentro do `ServerNode` atual. Ambas as versões têm alfa real.
- `CanvasItem.TEXTURE_FILTER_NEAREST` é aplicado explicitamente nos nós que recebem sprites de hardware novos. Para demais elementos de pixel-art, selecionar **Nearest** no import/texture filter (sem blur, sem mipmap indevido).
- Os componentes NinePatch (por exemplo, `panel_9slice.png`) viram `StyleBoxTexture` com `texture_margin_all=12` ou 15; botões continuam sendo `Button` com seus sinais originais.
- Não carregar `reference/*.png`, `reference/*.gif`, nem o catálogo de sprites na tela como UI. Estes arquivos são material de referência.
- Ao implementar efeitos adicionais, dar preferência a `Node2D._draw`, `Tween`, `AnimatedSprite2D`, `CPUParticles2D` e à API `VisualFX` já existente. **Sem shader HDR exclusivo de Forward+**, pois o jogo usa GL Compatibility.

## 8. Coisas que NÃO podem ser alteradas

1. `GameState` e o balanço das moedas/skills/tiers, incluindo novas skills que existam no branch atual.
2. `ServerNode.State`, `add_progress`, `reset_locked`, `honeypot_expired`, `HONEYPOT_LIFETIME` e seus estados reais.
3. `Main` input (mover mouse para crack/collect), `GameState.max_nodes`, bots e hunter bots, honeypot, trace, ultimate, resultado da run.
4. Sinais da UI, navegação entre três cenas, botões de upgrades, áudio e FX já existentes.
5. Comportamento de debug/autotestes em `Main.gd`, `NetworkSelect.gd`, `SkillTree.gd`.
6. Nenhum inventário, research ou loja falsos como telas não funcionais do mockup da segunda imagem.

## 9. QA antes de aceitar uma implementação

1. `python3 install.py --repo ... --dry-run` lista exatamente três scripts, sem aplicar mudanças.
2. `python3 install.py --repo ...` instala o add-on e cria backup. Rodar duas vezes não duplica ganchos.
3. Rodar Godot import headless se disponível: `godot --headless --path /path/to/keep-hacking --editor --quit` para importar e verificar erros.
4. Executar `scenes/NetworkSelect.tscn`: cada uma das quatro redes aparece com suas condições reais, entra em Main e a tela de Skill Tree funciona.
5. Em Main, verificar a contagem real de servidores (sem nós adicionais), estados LOCKED/READY, leve animação nas conexões e evento READY, hover do botão e suas ações, bots e ultimates.
6. Com `is_honeypot`, ring vermelho não altera prazo nem penalidade. Ganhos reais aparecem no log sem dobrar os valores.
7. Executar flags já suportadas no repositório (onde disponíveis), por exemplo `autotest_fx`, `autotest_audio`, `autotest_endround`, `autotest_abilities`, `autotest_skills`, `autotest_tier=N`, `autotest_breach`.
8. Medir FPS em cinco minutos de jogo. Efeitos decorativos devem ficar limitados a 30/20 FPS como codificado. Em notebook modesto, permitir desligar links/pulsos mantendo funcionalidade original.
9. Rodar `--remove-hook` ou `git restore scripts/game/Main.gd scripts/game/NetworkSelect.gd scripts/game/SkillTree.gd`: fluxo anterior deve voltar sem quebrar projeto.

### Critérios de aprovação

- Sem parse/runtime errors Godot e sem warnings relacionados ao add-on.
- Sem botão coberto pelo painel e sem input capturado pela nova UI (`MOUSE_FILTER_IGNORE`).
- Sem queda grave de FPS frente à versão sem add-on.
- Tabela de habilidades/desbloqueios idêntica à versão original.
- Visuais dinâmicos refletem o estado real do jogo, não screenshots.
- Testes manuais e smoke flags passam, com capturas feitas **no editor ou build rodando**.

## 10. Limitações atuais e evolução v1.1

- **Não é uma instalação comprovada no Godot:** editor/runner não disponível aqui. O pacote está preparado e testes estáticos foram executados, mas o usuário precisa rodá-lo em uma cópia de trabalho.
- **Não recria automaticamente todos os detalhes tridimensionais do mockup.** O add-on melhora substancialmente a camada atual com HUD e sprites, porém uma recriação final da sala de controle, sistema 9-patch para todos cards e animações de borda exigirá ajustes visuais após ver o jogo rodando.
- O `HoloTelemetry` é intencionalmente não interativo e não abre cenas novas.
- O mapa é uma textura-base procedural com scanner móvel, não geolocalização real.
- O HUD em 1280×720 foi desenhado para o cenário atual. Ajustes de âncora e safe areas são uma fase seguinte.
- Eventuais mudanças recentes no seu branch podem exigir ajuste dos três marcadores de instalação. O script falha antes de aplicar se um marcador não estiver presente.

**Entrega recomendada da próxima etapa:** instale numa branch, rode o jogo, envie um screenshot real (de Main, NetworkSelect e SkillTree) e os eventuais erros de console. Ajustarei os detalhes até a aparência de produção, mantendo o código e o gameplay protegidos.
