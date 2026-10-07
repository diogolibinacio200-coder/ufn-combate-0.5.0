# Validação — UFN Combate 0.5.0

Base: `UFN-Combate-v0.4.0-Codigo.zip`, obtido da pasta UFN Combate do Drive do autor. SHA-256: `1002a88c4cc04a0b968ba6203eb261ec88695fd6edcd8902f77f89d0492079cc`. A base foi importada, testada e registrada em commit local antes das alterações. [Registro anterior](QA-v040.md).

Validação em **07/10/2026**, Windows x64, **Godot 4.7.2 stable**. Testes de lógica sem janela; capturas e sessão nativa com Compatibility/OpenGL.

## Testes automáticos

**17 suítes, 3.305 verificações, zero falhas.** Importação e execuções concluídas com saída 0, sem `SCRIPT ERROR` ou `ERROR`. [Log completo](validation/v050/tests.txt).

| Suíte | Verificações |
|---|---:|
| Combate original | 195 |
| Módulos auxiliares | 62 |
| Áudio | 47 |
| Defesa | 11 |
| Dados | 12 |
| Fluxos e modos | 32 |
| Kart original | 26 |
| Regressões v2 | 64 |
| Release | 43 |
| Polimento | 650 |
| Torres | 500 |
| Ultimates 0.5.0 | 794 |
| Animações 0.5.0 | 328 |
| Pilotos 0.5.0 | 442 |
| Kart 0.5.0 | 53 |
| Skins 0.5.0 | 23 |
| Aliada 0.5.0 | 23 |
| **Total** | **3.305** |

As contagens incluem combinações de personagens, lados e estados; não representam esse número de funcionalidades ou partidas humanas independentes.

- Ultimates: custo único, captura confirmada, defesa, aparo, erro, interrupção, KO, treino, reinício, tint temporário, congelamento do relógio, descarte de comandos e retorno ao controle. Vitor causa 280 de dano em 15 impactos; Mirkos, 200 em seis impactos, com armadura ao final da montagem e benefícios originais de oito segundos.
- Animação: todos os 16 IDs de combate, sentidos de caminhada, apoio e elevação dos pés, aterrissagem, transições, atlas completos, limite de cache e simulação inalterada pelo desenho.
- Pilotos: 14 personagens e skin do Diogo, mãos no volante, pernas no cockpit, direção, aceleração, boost, salto e impacto.
- Skin: comparação de 600 frames entre os dois visuais de Diogo, incluindo ataques e Ultimate, hitboxes, seleção, troca, estatísticas e retomada da torre compartilhadas.
- Kart: entradas simultâneas, frenagem, drift, itens, colisões, recuperação, checkpoints, rejeição de atalhos/ré/teleporte, FOV e obstáculos da câmera, limites dos efeitos e limpeza ao sair/reiniciar.
- Aliada: transparência e atlas exclusivo, Maria preservada, elenco sem novo ID, manifestação e remoção do poder no Kart.

A IA completou três voltas e 60 checkpoints legais em cada pista. Tempos de **simulação**: Campus 79,1 s; Vila Belga 71,4 s; Centro 85,5 s; Desafio 96,7 s; UFN/Andradas 71,7 s. Velocidade máxima observada entre 28,75 e 29,67, abaixo do limite de 31,8. Teste adicional cobre tráfego com oito pilotos.

## Revisão visual

Capturas reais da engine registram os 16 lutadores caminhando, duas fases da passada de Lorenzo, as duas Ultimates, a armadura de Mirkos, a aliada loira nos dois sentidos, a seleção de cinco pistas, o circuito urbano e a divisão de tela.

- [Pilotos e skin do Diogo](screens/v050/pilots.png).
- [Lorenzo caminhando](screens/050_walk_10.png) e [passada alternada](screens/050_lorenzo_stride_b.png).
- [Vitor e sua aliada](screens/050_ultimate_09_049.png).
- [Robôs de Mirkos](screens/050_ultimate_04_044.png) e [montagem da armadura](screens/050_ultimate_04_131.png).
- [Aliada: soco](screens/050_ally_punch1_both_sides.png), [chute](screens/050_ally_kick_both_sides.png), [guarda](screens/050_ally_counter_right.png).
- [Seleção das pistas](screens/v050/kart_selection.png), [UFN/Andradas](screens/v050/andradas_overview.png) e [dois jogadores](screens/v050/andradas_split.png).

Correções decorrentes da revisão: nariz do kart separado do agrupamento de primitivas para evitar desaparecimento; coroas orientadas para a frente; cabelo de Maria conectado; contornos UV da aliada excluem fragmentos vizinhos sem recortar os sapatos. Sequências temporárias não aumentaram o número de nós na captura repetida.

## Reprodução

```powershell
./tools/test.ps1 -Godot 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe'
```

Capturadores: `tests/capture_animation050.gd`, `tools/capture_drivers050.gd` e `tools/capture_kart050.gd`. `tests/session_test.gd` exercita sessão nativa com bots, pausa, revanche, troca de modos e Kart dividido na pista nova. Perfis de teste são separados do perfil normal.

## Limites

- Não houve partida humana com dois controles físicos. Entradas simuladas não substituem essa verificação.
- Animações de luta combinam poses existentes e deformação de malha; não são um conjunto completo de animações novas desenhadas quadro a quadro. A aliada loira tem atlas próprio.
- Pilotos são interpretações 3D estilizadas das referências, não reproduções pixel a pixel. A pista é uma interpretação geográfica ajustada para corrida.
- Capturas e testes de ciclo de vida não demonstram ausência de todo vazamento em sessões de várias horas. Balanceamento competitivo requer partidas humanas.

[Notas da atualização](ATUALIZACAO-0.5.0.md) · [Arquitetura](TECHNICAL.md) · [Referências da pista](PISTA-UFN.md).
