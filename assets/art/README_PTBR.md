# KEEP HACKING — Asset Pack Original (v0.9.1)

Este pacote reúne **elementos 2D em pixel art prontos para serem importados** em um jogo incremental de invasão de sistemas fictícios. A referência para a estrutura de telas e para o ciclo incremental foi *Keep Watering* (oito capturas públicas na loja Steam), mas **nenhum sprite ou screenshot do jogo original foi copiado, recortado ou distribuído neste ZIP**. Os elementos aqui foram desenhados e compostos especificamente para *Keep Hacking*.

## O conceito de jogo

**ESCANEAR → INFILTRAR → EXTRAIR DADOS → COMPRAR UPGRADES → REPETIR**.

- **Watering** vira escaneamento e pulsos de intrusão.
- **Harvest** vira extração de créditos e pacotes de dados.
- **Plants/crops** viram nós da rede, terminais, bancos de dados, caches e servidores.
- **Tractors/rain** viram bots automáticos, transmissores e tarefas de extração em massa.
- **Skill tree** vira uma árvore de pesquisa com ferramentas, módulos e capacidades fictícias.
- **Farm selection** vira seleção de redes por dificuldade: Home Lab, Tech Campus, Data Center e Dark Grid.
- **Rural village** vira um hub de expansão: Nexus District.

## O que foi entregue

| Pasta | Conteúdo | Quantidade / dimensões |
|---|---|---|
| `assets/props/` | Servidores, terminal, firewall, roteadores, banco de dados, drones, porta segura, núcleo quântico, etc. | **34 PNGs RGBA 64×64** |
| `assets/icons/` | Moedas, dados, cadeado, scan, radar, energia, pesquisa, upgrades, mapa etc. | **32 PNGs RGBA 32×32** |
| `assets/tiles/` | Pisos digitais, placas, chão da rede, circuitos e cabos | **20 PNGs RGBA 32×32** |
| `assets/fx/` | Animações para pulso de scan, glitch e extração | **26 frames PNG RGBA 64×64** |
| `assets/ui/` | Templates de botões, janelas, barras de progresso e nós da pesquisa | **16 PNGs RGBA**, tamanhos específicos |
| `assets/atlases/` | Spritesheets organizados | **4 atlases PNG transparentes** |
| `assets/backgrounds/` | Fundos de menu azul e modo de alerta | **2 PNGs 1280×720** |
| `assets/marketing/` | Logotipo em fundo transparente, cápsula e key art | **3 PNGs** |
| `screenshots/` | Oito mockups completos e um catálogo comparativo | **8 imagens 1280×720 + 1 prancha** |
| `concept/` | Imagens exploratórias de direção de arte | **2 imagens PNG**, não recortadas em sprites |
| `source/create_assets.py` | Código-fonte usado para gerar o pacote de pixel art e os mockups | Editável e reproduzível (Python + Pillow) |
| `manifest.json` | Nomes, caminhos, dimensões, atlas e mapeamento de telas | JSON |
| `prototype.html` | Preview interativo local (cliques, dados, upgrades) | HTML sem servidor |

Os sprites individuais foram renderizados **com transparência verdadeira**, sem fundos quadriculados. A prancha de catálogo serve só para visualização; para usar em jogo, importe os PNGs das pastas respectivas ou os atlases.

## As 8 telas reinterpretadas

1. `01_first_breach.png` — área inicial da rede e invasão de um pequeno conjunto de nós.
2. `02_upgrade_details.png` — árvore tecnológica e tooltip de upgrade.
3. `03_automated_intrusion.png` — muitas máquinas e extração automatizada.
4. `04_network_selection.png` — quatro redes/dificuldades e cadeados.
5. `05_nexus_district.png` — hub para investir recursos e desbloquear destinos.
6. `06_midgame_scan.png` — campo de scan com densidade intermediária.
7. `07_full_research_tree.png` — árvore tecnológica completa.
8. `08_final_breach.png` — jogo avançado, recursos, alertas e extração.

## Integração na engine

**Godot 4:** importe a pasta `assets/`, use `Texture Filter: Nearest` (sem suavização) e sprites com proporção preservada. Para efeitos animados, importe os quadros ordenados por nome, por exemplo `scan_pulse_00.png` até `scan_pulse_09.png`.

**Unity 2D:** configure `Texture Type = Sprite (2D and UI)`, `Filter Mode = Point (no filter)`, `Compression = None` e mantenha pixels por unidade consistentes. Os atlases têm células fixas declaradas em `manifest.json` (64×64 ou 32×32) e podem ser usados como spritesheets **Grid by Cell Size**.

**GameMaker/Construct/Phaser:** também são PNGs normais. Os atlases permitem slicing em grid e os nomes descritivos facilitam animações/camadas de UI.

### Regras visuais propostas

| Uso | Cor |
|---|---|
| Fundo | `#070C1A` |
| Equipamento | `#263952` |
| Operação/seleção | `#45DEF5` |
| Sucesso/créditos | `#42F7A9` |
| Pesquisa/raridade | `#B26EFF` |
| Alerta/firewall | `#FF5378` |
| Recompensa | `#FFD971` |

## Como pré-visualizar

Abra `prototype.html` no navegador. Ele exibe sprites reais do pacote num tabuleiro interativo: clique em dispositivos para ganhar dados, use a compra de upgrade para automatizar recursos, altere a rede e navegue pelas telas no painel superior. Trata-se de um **protótipo de visualização** e não de um jogo pronto, com física, progressão persistente, salvamento, som ou arquitetura de produção.

Abra `screenshots/00_contact_sheet.png` para ver todas as telas juntas e `assets/asset_catalog.png` para ver os sprites.

## Limites / produção final

- Os **mockups não são cenas de engine**: são imagens demonstrativas compostas a partir dos PNGs, para visualização/layout.
- As imagens da pasta `concept/` são **ilustrações de direção de arte**, não sprites isolados para animação; podem precisar de retoque se forem usadas como arte promocional.
- As animações fornecidas são sequências gráficas; cabe à engine controlar timing, interações, som e interpolação.
- Não estão incluídos códigos que executam invasões reais, exploração de falhas ou interferência em redes. A fantasia de hacking é puramente visual e lúdica.
- Verifique a disponibilidade do nome **Keep Hacking**, sua marca e quaisquer obrigações legais antes de comercializar. A semelhança conceitual de ciclo incremental não significa autorização para duplicar a arte, o código ou a identidade do jogo de referência.

**Comando para refazer o kit procedural:** `python source/create_assets.py` — requer `pip install Pillow`.
