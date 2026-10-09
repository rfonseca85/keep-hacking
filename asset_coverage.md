# Keep Hacking — Asset Coverage

Mapeamento de cada asset do pack (`assets/art/assets/`) para onde é consumido em runtime.
Gerado durante a migração visual P0–P6. Fonte de verdade dos caminhos: `scripts/visual/KHArt.gd`.

Legenda de status:
- **EM USO** — carregado e desenhado em runtime hoje.
- **DISPONÍVEL** — importado e acessível via `KHArt.tex()`, reservado para uso futuro.
- **NÃO-RUNTIME** — material de referência/marketing, proibido como UI jogável (spec §3.1, §18.5).

---

## props/ (34)

| Asset | Status | Tela / componente |
|---|---|---|
| terminal, server_rack, server_cluster, router, database, processor, mainframe, data_cache, access_port, code_console, secure_node | **EM USO** | `ServerNode._draw_device()` — variante sorteada por célula via `KHArt.pick_device_variant()` (RNG local, não consome o RNG global de gameplay) |
| cooling_fan, satellite_dish, relay_tower, antenna, neon_crate, signal_orb | **EM USO** | `Main._draw_circuit_decor()` — props decorativos fora da área clicável |
| terminal_desk | **EM USO** | `NetworkSelect` — emblema do tier HOME NETWORK |
| server_cluster | **EM USO** | `NetworkSelect` — emblema do tier OFFICE LAN |
| mainframe | **EM USO** | `NetworkSelect` — emblema do tier CORP NETWORK |
| relay_tower | **EM USO** | `NetworkSelect` — emblema do tier BOTNET ARRAY |
| firewall, firewall_gate, encrypted_vault, vault_door, security_cam, virus_specimen, glitch_node | **DISPONÍVEL** | reservado: visual de honeypot/alerta dedicado |
| bot_drone, proxy_bot, packet_transmitter, wifi_beacon | **DISPONÍVEL** | reservado: ator visual do tick de bot (spec §12.2) |
| quantum_core, power_cell, data_pod, decrypt_station, extraction_port | **DISPONÍVEL** | reservado: variantes de tier superior |

## icons/ (32)

| Asset | Status | Tela / componente |
|---|---|---|
| credits | **EM USO** | HUD contador de CREDITS (`Main._make_counter`) + rodapé NetworkSelect |
| exploit | **EM USO** | HUD contador de EXPLOITS |
| key | **EM USO** | HUD contador de 0-DAYS |
| lock, unlock | **EM USO** | `ServerNode._draw_status_icon()` — estado LOCKED/READY |
| bolt | **EM USO** | SkillTree: `speed1`, `speed2` |
| scan | **EM USO** | SkillTree: `radius1`, `radius2` |
| bot | **EM USO** | SkillTree: `bot1`, `bot2` |
| data | **EM USO** | SkillTree: `yield2` (ZERO-DAY CACHE) |
| stealth | **EM USO** | SkillTree: `duration1` (STEALTH ROUTING) |
| shield | **EM USO** | SkillTree: `forensics1` (COUNTER-FORENSICS) |
| network | **EM USO** | SkillTree: `footprint1` (NETWORK FOOTPRINT) |
| xp, packets, radar, glitch, upload, speed, upgrade, tree, replay, settings, map, firewall, code, cpu, lab, warning, success, target, boost, power | **DISPONÍVEL** | reservado para HUD/botões futuros |

> Mapeamento de compatibilidade (spec §11): os IDs de skill mantêm nomes antigos
> (`bolt2`, `scan2`, `bot2`, `cash`, `diamond`, `clock`) e são traduzidos para ícones
> reais em `SkillTree._SkillIcon.ICON_MAP`. **Nenhum ID, preço ou efeito foi renomeado.**

## tiles/ (20)

| Asset | Status | Tela / componente |
|---|---|---|
| grid_a, grid_b | **EM USO** | `Main._draw_grid_lines()` — chão da grade 24×14 tiles de 32px, variação seeded (seed fixa 42, sem flicker) |
| circuit_a, circuit_b | **EM USO** | `Main._draw_circuit_decor()` — decalques fora da grade |
| deck_a, deck_b, metal_plate, metal_grid, neon_floor, walkway, hazard, server_carpet, hub_floor, purple_floor, noise, grid_alert, data_stream | **DISPONÍVEL** | reservado: variação de chão por tier |
| cable_h, cable_v, cable_turn | **DISPONÍVEL** | reservado: cabos desenhados (hoje os pacotes correm sobre as linhas da grade) |

## fx/ (26)

| Asset | Status | Trigger real |
|---|---|---|
| data_extract_00..07 | **EM USO** | `Main._exfiltrate()` — tingido pelo tipo (verde normal / magenta exploit / vermelho honeypot) |
| glitch_00..07 | **EM USO** | `Main._on_honeypot_expired()` |
| scan_pulse_00..09 | **EM USO** | cursor durante `is_decrypting` (throttle 0.42s, escala derivada de `GameState.decrypt_radius`) + chain crack |

Todos one-shot via `VisualFX.play()`, com cap de 20 simultâneos e `queue_free()` em
`animation_finished` (verificado em runtime gráfico: spawned=3 → remaining=0).

## ui/ (16)

| Asset | Status | Tela / componente |
|---|---|---|
| selection_card | **EM USO** | `NetworkSelect` — moldura dos 4 cards (StyleBoxTexture, tingida pela cor do tier) |
| hud_counter | **EM USO** | `Main` — painel dos contadores do topo |
| bar_full, bar_alarm, bar_energy, window, panel_small, tooltip, button_primary, button_secondary, button_alert, button_disabled | **DISPONÍVEL** | reservado: molduras de barra/botão/janela |
| skill_node, skill_available, skill_active | **DISPONÍVEL** | ver nota abaixo |
| skill_locked | **NÃO APLICÁVEL como moldura** | ver nota abaixo |

> **Nota honesta sobre os `skill_*`:** foram testados como `StyleBoxTexture` nos nós da
> SkillTree e **rejeitados**. `skill_locked.png` não é uma moldura ninepatch — é um ícone
> de cadeado *preenchido* 32×32; esticá-lo sobre um botão de 110×80 deformava o cadeado e
> cobria o texto. Os estados visuais dos nós usam hoje `StyleBoxFlat` com cor semântica
> (ciano = comprável, verde = adquirido/MAX, cinza = sem créditos). Os PNGs seguem
> importados caso se queira usá-los como *ícone de canto* em vez de fundo.

## atlases/ (4)

| Status | Observação |
|---|---|
| **DISPONÍVEL (não usado por design)** | São cópias organizadas dos mesmos PNGs individuais. Spec §3.1 proíbe desenhar atlas e PNG individual simultaneamente; o projeto usa os PNGs individuais. |

## backgrounds/ (2), marketing/ (3), screenshots/, concept/

| Status | Observação |
|---|---|
| **NÃO-RUNTIME** | `ui_blue_background_1280x720`, `ui_red_background_1280x720`, `key_art`, `logo`, `steam_capsule`, `screenshots/*`, `concept/*`. Spec §3.1/§18.5: proibido usar como tela jogável. O ambiente de jogo é construído em camadas de nós Godot. `concept/01_gameplay_concept.png` e `screenshots/00_contact_sheet.png` são usados **apenas** como referência de comparação visual durante o desenvolvimento. |
