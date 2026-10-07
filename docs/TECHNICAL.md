# Guia técnico — UFN Combate 0.5.0

## Ambiente e execução

- **Godot 4.7.2 Standard**, GDScript, Windows x64.
- Renderer **Compatibility**, OpenGL 3.3 na máquina validada.
- Interface lógica 1280 × 720, escala com preservação de proporção.
- Física de 60 passos por segundo; limite de apresentação de 60 FPS. Esse limite não garante 60 FPS sustentados; consulte as medições em [QA.md](QA.md).
- Cena inicial: `scenes/main.tscn`.
- Nenhum serviço remoto é necessário para jogar.

Importe `project.godot` no editor e execute com F5. Não versione a pasta de cache `.godot/`.

## Organização

| Arquivo | Responsabilidade |
|---|---|
| `scripts/main.gd` | Telas, seleção, rounds, modos, progressão e integração |
| `scripts/input_manager.gd` | Entradas físicas, remapeamento, gamepads e conflitos |
| `scripts/combat.gd` | Passos fixos, comandos, contatos, projéteis, defesa e duplas |
| `scripts/fighter.gd` | Estado individual, hurtbox, pushbox e atributos de referência |
| `scripts/move_db.gd` | Elenco ativo, atributos específicos, normais, especiais e Ultimates |
| `scripts/ai.gd` | Decisões dos oponentes de luta |
| `scripts/arena_view.gd` | Sprites, arenas, câmera e efeitos; lê o estado do combate |
| `scripts/fighter_motion.gd` | Cadência, deformação contínua, transições e topologia dos sprites |
| `scripts/ally_art.gd` | Atlas, poses, âncoras e contornos UV da aliada loira exclusiva de Vitor |
| `scripts/interface.gd` | Menus, HUD, galeria, créditos e guias |
| `scripts/tower_view.gd` | Seleção, escadas, retratos, progresso e desmontagem das torres |
| `scripts/kart.gd` | Mundo 3D, pistas, condução, CPUs, itens e campeonato |
| `scripts/kart_driver.gd` | Corpo sentado, articulação dos braços e fixação das mãos ao volante |
| `scripts/kart_appearance.gd` | Aparência dos 14 pilotos e da skin do Diogo, associada às referências fornecidas |
| `scripts/kart_ufn_track.gd` | Traçado, arquitetura, placas e objetos do circuito UFN / Andradas |
| `scripts/kart_hud.gd` | HUD de corrida, pausa, classificação e pódio |
| `scripts/audio_manager.gd` | Cache, volumes, vozes, efeitos e transições musicais |
| `scripts/save_manager.gd` | Perfil versionado, validação, gravação e recuperação |
| `data/balance.json` | Ajustes numéricos dos golpes |
| `data/roster.json` | Catálogo exportado; a definição ativa fica no MoveDB |

A simulação de luta usa dicionários de estado e eventos. O renderer e o áudio consomem esses eventos. Alterar uma pose desenhada não altera automaticamente o alcance do golpe.

## Combate

`Combat.tick()` recebe uma entrada por lado. Tempos de startup, atividade, recuperação, stun e efeitos usam frames de 60 Hz. A vida de referência é 1000, guarda 100 e energia 100; velocidade de caminhada e atributos-base são iguais entre os 14 jogáveis; recursos preparados e chefes mantêm regras específicas.

Há nove normais contextuais, cadeia de leves, quatro especiais por personagem, agarrão comum, esquiva e Ultimate. A janela de movimento direcional é de 18 frames, com buffer de ação de oito frames. Cada direção é armazenada também como frente/trás relativos ao adversário no momento da entrada. O buffer guarda orientação e especial resolvido para preservar a interpretação durante recuperação. Combinações especiais precedem os normais; apertar e segurar não gera repetição automática.

Com defesa segurada, o novo pressionamento de A2 tenta Ultimate; A3 tenta troca; A1 tenta agarrão, nessa prioridade. Combinações indisponíveis são consumidas e não se convertem em um golpe normal acidental.

Defesa alta/baixa é testada contra o nível do golpe. A defesa perfeita usa janela de cinco frames e o aparo frontal de três frames. Há perda de guarda, quebra de guarda, redução de dano em combos e limites de cancelamento/juggle.

As Ultimates confirmadas dos demais lutadores continuam usando a sequência genérica de 120 frames. Vitor do Mal e Mirkos usam `cinematic` com fases e impactos próprios, atualizados por `_tick_signature_cinematic()`. André mantém zonas de gás evitáveis, sem capturar os dois lutadores.

| Ultimate | Tipo | Preparação / atividade / recuperação | Dano-base | Coreografia após confirmação |
|---|---|---|---:|---|
| Vitor do Mal — Rajada Sombria | `rush_combo` | 22 / 8 / 36 frames | 280 | 126 frames de sequência, mais 24 de pausas de impacto |
| Mirkos — Protocolo Singularidade | `robot_super` | 27 / 9 / 54 frames | 200 | 144 frames de sequência, mais 16 de pausas de impacto |

Ambas custam **100 de energia** e usam a pausa de ativação de 12 frames do sistema de Ultimate. Os 280/200 são orçamentos de dano antes da redução de combos, não custos de energia. Os tempos da tabela são os valores da 0.5.0; os campos permitidos em `data/balance.json` continuam ajustáveis.

Vitor usa os impactos `[1,25,31,37,43,49,55,61,67,73,79,85,91,97,111]`. O primeiro aplica captura com `ultimate_tint`, os intermediários compõem a fase `flurry`, e o último entra em `finisher`, remove a tonalidade e inicia o recuo. Mirkos usa `[10,27,44,61,78,92]`, muda para `recall` no frame 103 e `assembly` no 117. Ao completar o frame 144, recebe `transform=480`: oito segundos de simulação, com +20% de dano e +30 de alcance nos normais. A armadura não modifica permanentemente o MoveDB.

Enquanto a sequência está ativa, o relógio da luta, os comandos dos jogadores e os timers normais ficam suspensos. `impact_pause` segura o avanço da coreografia nos impactos; não reaplica dano. A finalização limpa movimento pendente e buffers, libera o atacante e coloca o defensor na reação normal de queda. A apresentação consome `cinematic_start`, `ultimate_phase`, `super_hit` e `cinematic_end`; o evento `hit` complementar usa `silent_audio=true` para evitar som duplicado.

Bloqueio, aparo, invulnerabilidade e erro de alcance não iniciam captura. Mirkos ainda pode formar a armadura ao concluir a recuperação de um ataque bloqueado ou errado; se for interrompido antes disso, não recebe o benefício. `cancel_cinematic()` libera os estados e cancela impactos futuros sem conceder armadura. Reset de round também limpa as flags temporárias. Robôs e peças da coreografia são desenhados pela apresentação, sem dispositivos persistentes de combate.

### Duplas e rounds

- `teams` guarda dois estados por lado; `team_active` indica o lutador presente.
- Vida e energia são independentes por integrante.
- Troca manual exige lutador livre, no chão, reserva vivo e intervalo encerrado.
- Intervalo de troca: 300 frames. KO pode forçar a entrada da reserva sem esperar esse intervalo.
- Objetos do personagem que sai são retirados para evitar atribuição indevida de dano/energia.
- Duração: 99 s no individual e 150 s nas duplas.
- Melhor de três; Sobrevivência exige uma vitória por adversário.
- Timeout compara a proporção de vida da equipe. Empate exige outro round.

### Torre UFN

`tower_select` apresenta quatro cartões verticais com escadas de blocos e três níveis de dificuldade. `tower_count` representa somente os oponentes regulares e aceita `[3, 5, 8, 10]`; `tick_select()` sorteia essa quantidade sem repetir o lutador escolhido e acrescenta os chefes `14` (André CSTH) e `15` (Kelvin). Assim, a ordem persistida tem `[5, 7, 10, 12]` andares.

`save_manager.gd` valida o tipo, o tamanho, a ordem final dos chefes, a ausência de repetição e a exclusão do personagem do jogador. Perfis de dez andares da base anterior continuam válidos e migram para oito oponentes regulares. Dificuldade da torre é independente da dificuldade geral e chega ao `Combat` por `active_difficulty()`.

Depois da vitória em Kelvin, `complete_tower()` limpa a retomada, grava a conquista e muda para `tower_complete`. `tower_view.gd` usa `screen_time` para retirar cada bloco em uma ordem determinística, aplicando deslocamento, rotação, retrato e poeira sem criar nós por peça; em seguida `tick_tower_complete()` abre o final do campeão.

André e Kelvin recebem vida máxima própria por dificuldade. Na ordem fácil a extremo, André usa 1100/1150/1250/1300; Kelvin usa 1150/1250/1300/1400. O HUD e o timeout usam essa vida máxima.

### Sistemas específicos

- **Lorenzo:** aceleração do pacote após 18 frames, reposicionamento e firewall consumível.
- **Leonardo:** concluir o trago concede até três níveis de Embalo por oito segundos. Um ataque com dano consome os níveis e recebe +12% por nível. Não há cura.
- **Cristian:** tijolo em arco, parede que intercepta dois projéteis ou é destruída por golpe corporal e pilar anunciado.
- **Fernando:** ataques físicos partem da posição do urso; o dono gesticula. Postura do urso é separada da vida de Fernando. Acertar o dono interrompe a ação; postura esgotada desorganiza o urso.
- **André:** ataques anunciados de gás e Ultimate com três regiões temporizadas.
- **Kelvin:** golpes com skate, ascendente, giro e investida.

## Entrada e remapeamento

Há nove entradas por jogador: quatro direções, quatro ações de ataque/defesa e esquiva. O Input Manager consulta teclas físicas e botões/eixos a cada passo, gerando bordas de pressionamento e soltura.

O mapa padrão de teclado é WASD + J/K/L/U para J1 e setas + Num1/2/3/4 para J2. Esquiva: Shift para J1 e Num0 para J2. Gamepad: X/Y/A/LB e B para esquiva; direcional e analógico esquerdo; Start pausa. O perfil sem numérico usa F/G/H/R para as ações de J1 e J/K/L/U para J2.

`bindings` e `kart_bindings` são separados; o mesmo vale para botões de gamepad. Dispositivo, zona morta e eixos ficam na configuração do jogador. Remapear para uma tecla ocupada troca as atribuições, evitando que a mesma tecla controle dois jogadores no mesmo mapa. Esc, Enter, Tab, F2, F3 e F11 são reservados.

O sistema permite automático, somente teclado ou somente controle. A perda de controle pausa a partida e libera retorno ao teclado. Atribuição e persistência são testadas por software; ghosting de teclado e dois controles reais simultâneos precisam ser avaliados no equipamento final.

## Sprites e arenas

Cada personagem usa:

```text
assets/sprites/<id>/atlas.png
assets/sprites/<id>/portrait.png
assets/sprites/<id>/frames.json
```

Nas duas skins de Diogo, `sockets` associa o ponto da mão à pose de origem; efeitos são desenhados antes do corpo para evitar ocultar punho/punho espelhado. `uppercut` usa uma sequência ascendente dedicada.

O JSON contém `frames` (retângulos), `animations` (nomes de poses em sequência), `anchor` e `source`. As células atuais medem 384 × 320, com ancoragem dos pés em **192,304**. O espelhamento acompanha a direção do lutador.

Os dez personagens anteriores e a skin têm 35 poses catalogadas por atlas. Lorenzo, Cristian e Fernando têm 30; Leonardo, 32; André e Kelvin, 26. Sequências de 24 posições repetem essas poses; **24 posições não significam 24 desenhos distintos**. Alguns estados reutilizam poses aproximadas. O urso usa um atlas independente de oito poses. A revisão dos novos recortes usa limites por quadro nos metadados para ocultar fragmentos de poses vizinhas, preservando a ancoragem. Onde o recorte de origem omite parte do corpo, uma pose íntegra alternativa é reutilizada; não são reconstruídos membros com pixels inventados. Caminhada e transições de alguns personagens, portanto, repetem poses. Consulte as notas dos respectivos `frames.json`.

Na 0.5.0, `fighter_motion.gd` adiciona uma malha sobre a célula de sprite, com grade de 12 × 16. Cada célula é intersectada com o polígono opcional de `frame_clips`, triangulada e mapeada para as UVs do retângulo de origem no atlas. A deformação desloca os vértices, mas conserva as UVs e o pixel de origem. As junções usam a mesma função contínua, evitando separar braços e pernas em peças independentes. Hurtbox e pushbox continuam exclusivamente em `fighter.gd`.

A fase de caminhada segue a distância horizontal percorrida, com sentido e amplitude específicos para recuo. Respiração, apoio durante ataques e reação de aterrissagem complementam os desenhos. `transition()` dissolve entre poses em 35 ms para ataque/reação e 90 ms nos demais estados. O cache de topologias tem limite de 96 entradas; `reset()` limpa os estados temporais dos lutadores.

`ally_art.gd` é independente do elenco. Declara sete poses, âncoras e os contornos usados para recortar a aliada loira em `assets/sprites/vitor_ally_blonde/atlas.png`. Algumas células têm extensões sobrepostas: `CONTOURS` remove visualmente fragmentos da pose vizinha através de polígonos com UV, sem modificar o bitmap. A pose de guarda também é usada pelo recurso de apoio do kart. Maria não é removida ou substituída no catálogo. Para futuras trocas do atlas, revise retângulos, contornos e âncoras em conjunto, especialmente nas poses de soco e chute.

Para trocar um sprite, mantenha as coordenadas de ancoragem coerentes e confira idle, caminhada, ataque, queda e espelhamento em ambas as extremidades da arena. Verifique também recortes de retrato e sombra. A lista de nomes deve continuar alinhada entre MoveDB, renderer e kart.

As oito arenas são imagens em `assets/arenas/`. A seleção usa a mesma ordem de `main.gd` e `arena_view.gd`. Há efeitos sobrepostos, mas a composição atual não é um cenário integralmente dividido em planos de paralaxe.

## Kart

O mundo 3D é compartilhado por um ou dois SubViewports, cada um com sua câmera. Circuitos fechados usam uma curva suavizada e distância acumulada para posição, orientação, classificação e condução da CPU.

Os IDs 0–3 continuam sendo os quatro circuitos clássicos. O ID 4 corresponde a **UFN / Andradas**, construído por `kart_ufn_track.gd`, disponível na corrida rápida e no contrarrelógio. A nova seleção usa cinco cartões. O campeonato permanece com quatro etapas, conservando o formato e os limites de retomada existentes. A geometria e as fontes geográficas estão descritas em [PISTA-UFN.md](PISTA-UFN.md).

Cada volta exige **20 checkpoints ordenados** e a passagem correta na chegada. Cruzar de ré, fora do portão ou pulando o próximo checkpoint não avança a volta. Deslocamentos superiores a oito unidades em um passo não contam como cruzamentos. São três voltas por corrida. Reposicionamento conserva o progresso legítimo e retorna ao último portão válido.

Há aceleração, frenagem/ré, direção, atrito fora da pista, drift e miniturbo, colisões, saltos em rampas, recuperação e aviso de contramão. A corrida termina após os humanos concluírem; CPUs ainda em pista são classificadas pelo progresso.

`_resolve_track_contact()` contém o centro do kart dentro da barreira descontando seu raio, elimina a velocidade dirigida para fora e preserva a velocidade tangencial. `_resolve_obstacles()` trata cones e veículos estacionados. A separação entre karts reaplica esses limites e cobre o caso de centros coincidentes. O detector de imobilidade e a recuperação por distância excessiva usam `respawn_racer()`, assim como os atalhos manuais.

`_bot_input()` antecipa o ponto da curva, calcula velocidade segura pelo desvio angular e ajusta a faixa para competidores e objetos próximos. As decisões usam os mesmos comandos de aceleração e direção dos humanos; não há multiplicador de velocidade baseado na posição do jogador. `_update_cameras()` interpola posição, foco e FOV; `_camera_clear_position()` amostra o segmento de visão contra `scenery_bounds` para encurtar a câmera antes de uma fachada.

As caixas sorteiam seis categorias: pulso, turbo, escudo, choque, óleo e poder exclusivo. A capivara é o poder de Maria. Escudo absorve impacto; a recuperação concede proteção temporária para reduzir encadeamento de ataques.

O campeonato soma 15/12/10/8/6/4/2/1 pontos por posição nas quatro pistas. Reiniciar uma corrida restaura a pontuação anterior à etapa. O contrarrelógio desativa CPUs e caixas, salvando o melhor tempo local.

Geometria estática com o mesmo material é agrupada por `_batch_static_geometry()` para reduzir chamadas de desenho; karts e itens continuam independentes. A qualidade leve desativa sombras mais caras. `kart_appearance.gd` define paletas, cabelo, roupa, barba, óculos e detalhes individuais, com ID de referência e skin separados. As 15 imagens originais permanecem em `assets/kart/references/`, com a correspondência e os hashes em `manifest.json`.

`kart_driver.gd` fixa quadril/pernas ao assento e pedais, inclina o tronco e recalcula os segmentos dos braços até os pontos globais do volante. Rodas usam pivôs separados para esterço e giro. A skin do Diogo muda sua aparência, mas mantém `character=3` e o mesmo sistema de kart.

Marcas de derrapagem reciclam no máximo **96 instâncias**; `burst()` limita a **180 partículas simultâneas**, removidas ao vencer o tempo de vida. `stop()` interrompe os motores, libera o mundo via sua camada e limpa arrays de corredores, efeitos, marcas, obstáculos e alvos de câmera. Na luta, a lista de efeitos do renderer fica limitada a **64 entradas**. Esses limites reduzem acúmulo, sem constituir garantia de FPS para todo hardware.

## Apresentação e demonstração

A janela usa `canvas_items` com aspecto `expand`: a área lógica cresce no eixo excedente. O conteúdo do menu fica centralizado; o fundo cobre a viewport. O HUD de luta usa margens da viewport para retratos, barras e rodapé. Sprites preservam escala uniforme. A câmera interpola centro e zoom entre 1,0 e 1,085.

`demo_combat` e `demo_bots` são instâncias isoladas, usadas somente após oito segundos sem interação em menu/seleção. A demo sorteia lutadores distintos e arena, inicia com 80 de energia e reinicia ao terminar ou após 30 s. Entrada física ou movimento do mouse encerra a demo sem gravar resultados nem substituir a seleção.

## Áudio e perfil

Há buses `UFNMusic`, `UFNSFX` e `UFNVoice`, sob o volume geral. Efeitos usam pool de 18 canais; música usa dois players para transição; narrador usa fila própria. Arquivos são pré-carregados no início.

- Música/efeitos: `tools/generate_audio.py`.
- Narrador pt-BR: `tools/generate_announcer_pt.ps1`, com Microsoft Maria Desktop instalada.

O perfil versão 2 fica em `user://profile.json`, equivalente no Windows a `%APPDATA%/Godot/app_userdata/UFN COMBATE/profile.json`. Inclui settings, stats, bindings e progress. A escrita passa por arquivo temporário e mantém `.bak`; tipos e faixas são validados na leitura. Torre salva personagem, skin, dificuldade, quantidade regular, ordem e andar; campeonato salva pilotos, skins, humanos, próxima pista e pontos.

## Alterar conteúdo

1. **Balanceamento:** ajuste valores existentes em `data/balance.json`. `name`, `kind` e `family` permanecem definidos no código. Reinicie a simulação e rode os testes.
2. **Novo lutador:** atualize elenco/IDs/velocidades/visuais/especiais/Ultimate no MoveDB; arte e índices no renderer/interface; piloto e assinatura no kart; limites de seleção e persistência; testes.
3. **Novo comportamento:** implemente o tipo na simulação, depois o evento e a apresentação. Um nome novo no JSON não cria uma mecânica.
4. **Nova arena/pista:** atualize a lista ativa, miniatura, construção e música; confirme a seleção e o sorteio.
5. **Skin:** mantenha os mesmos dados de combate e associe somente o atlas/retrato alternativo.

## Testes e exportação

```powershell
./tools/test.ps1 -Godot 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe'
./tools/build.ps1 -Godot 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe' -SignedRuntime 'C:/caminho/Godot_v4.7.2-stable_win64.exe'
```

O comando recomendado importa os recursos, verifica a assinatura Authenticode do executável fornecido em `-SignedRuntime` e exporta os dados com o preset **Windows Desktop** para `../Windows/UFNCombate.pck`. Em seguida, copia o executável oficial, sem alterar seus bytes, para `../Windows/UFNCombate.exe`. A verificação e os hashes do pacote efetivamente produzido devem constar em [QA.md](QA.md). Renomear o executável sem modificar seu conteúdo preserva a assinatura da engine; os dados do jogo no PCK não são cobertos por essa assinatura.

**Distribua o EXE e o PCK juntos, com o mesmo nome-base.** `-Output` muda o caminho do EXE; o PCK será criado ao lado dele, trocando apenas a extensão. O preset inclui explicitamente os JSONs de balanceamento e frames. Testes, ferramentas e documentação ficam fora dos dados executáveis do jogo. Mantenha os avisos de terceiros junto ao pacote Windows.

Sem `-SignedRuntime`, o script mantém a exportação Windows convencional com PCK embutido. Nesse caso, é possível indicar `-WindowsReleaseTemplate 'C:/caminho/windows_release_x86_64.exe'`; o ajuste temporário do preset é restaurado ao terminar.

As suítes da 0.5.0 (`ultimate050`, `animation050`, `driver050`, `kart050`, `skin050` e `ally050`) complementam os testes da base. Elas cobrem as novas sequências, deformações, pilotos, tráfego real de IA, checkpoints, identidade compartilhada das skins e ciclo de vida da aliada. A arte da aliada também deve ser inspecionada visualmente nos dois sentidos: validar limites e UVs não substitui a avaliação da pose e dos contornos desenhados.

A sessão funcional nativa opcional é executada sem `--headless`, separadamente da suíte:

```powershell
& 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/session_test.gd
```

Ela dura cerca de 96 segundos, alterna luta, menus e kart, e verifica pausa, retomada, revanche, tela dividida e liberação do mundo 3D. O script força 720p/qualidade padrão, janela sem foco e fora da tela, com bots no lugar dos jogadores. Os valores de FPS vêm do inverso do delta de processamento; não constituem benchmark em primeiro plano ou teste térmico. A simulação continua configurada em 60 passos por segundo independentemente dessa cadência de apresentação.

[Resultados e limitações da validação](QA.md) · [Lista de golpes](../GOLPES.md) · [Procedência](../LICENSES.md)
