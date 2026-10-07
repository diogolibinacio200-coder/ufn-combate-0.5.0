# UFN Combate 0.5.0 — Combate, animações e Kart UFN

A 0.5.0 foi construída sobre o código da 0.4.0, preservando o elenco, as arenas, as torres, os modos de jogo e o formato de salvamento. A atualização concentra as mudanças nas Ultimates dos dois Vitors e de Mirkos, na apresentação dos lutadores e no modo Kart.

## Ultimates

O comando continua sendo **D + A2**, com 100 de energia. D representa a ação de defesa. A preparação usa uma breve pausa, destaque visual e som de ativação. A captura só começa quando o ataque conecta: defesa, aparo, invulnerabilidade e distância continuam relevantes.

| Personagem | Sequência confirmada | Dano-base | Encerramento |
|---|---|---:|---|
| Vitor do Bem | Ultimate de contra-ataque: primeiro impacto, tonalidade vermelha temporária, sequência rápida de socos e finalização; 15 acertos | 280 | Remove a tonalidade vermelha do alvo, aplica recuo e devolve o controle após a reação de queda |
| Vitor do Mal | Rajada Sombria com a coreografia das aliadas, sequência rápida de socos e finalização; 15 acertos | 280 | Aplica recuo, devolve o controle após a reação de queda e não usa a tonalidade vermelha do Vitor do Bem |
| Mirkos | Seis impactos de unidades mecânicas, recolhimento das peças e montagem da armadura | 200 | Ativa a armadura pelo período original de 480 quadros, equivalente a oito segundos de simulação |

O dano total passa pela redução de combos do sistema. Não há um dano inicial extra somado novamente à sequência. As pausas de impacto são curtas nos golpes intermediários e mais longas na finalização. O relógio da luta fica suspenso durante a coreografia.

A armadura de Mirkos conserva **20% de dano adicional nos ataques normais e 30 unidades extras de alcance**, sem alterar os atributos básicos permanentemente. Em defesa ou erro, o adversário não é capturado; Mirkos recebe a armadura somente se completar a recuperação sem ser interrompido. Uma interrupção antes desse término cancela a recompensa. A ativação confirmada só concede a armadura depois da montagem.

Reset de round e cancelamento da sequência limpam captura, tonalidade, pausas e comandos pendentes. A câmera e os efeitos acompanham os eventos da simulação; não calculam dano nem colisões.

## Aliada exclusiva de Vitor do Mal

Uma aliada loira com arte própria participa das invocações, da guarda, da coreografia da Ultimate e do poder de kart de Vitor do Mal. O atlas está em `assets/sprites/vitor_ally_blonde/atlas.png` e suas poses são definidas em `scripts/ally_art.gd`. Ela não participa da Ultimate vermelha do Vitor do Bem.

Essa aliada é um recurso de apoio de Vitor. Não recebe slot no elenco, ID de lutador ou progresso próprio. **Maria continua sendo uma personagem jogável**, com sua arte e suas habilidades preservadas. A substituição visual se limita à representação dos poderes de Vitor.

## Animações e skins

O módulo `scripts/fighter_motion.gd` aplica movimento a uma superfície contínua do sprite, preservando os pixels de origem, as caixas de colisão e a lógica de combate. A caminhada acompanha a distância percorrida; o recuo inverte o ciclo e usa passada menor. Respiração, oscilação do tronco, movimento de apoio durante ataques e reação ao pouso complementam as poses dos atlas.

As transições entre poses usam interpolação curta, com tempo menor nos ataques para manter o contato legível. A revisão alcança o elenco completo, incluindo Lorenzo e as duas aparências de Diogo. É animação procedural sobre os atlas existentes, não um conjunto inteiramente redesenhado de quadros para cada lutador.

**Diogo Careca continua sendo uma skin do Diogo.** As duas aparências compartilham ID, golpes, Ultimate, vida, atributos, hitboxes, estatísticas e progresso. A escolha altera a apresentação e é restaurada nas lutas, rounds, reservas de Duplas, torre e kart.

## Pilotos e condução do kart

As 15 referências fornecidas foram associadas aos 14 pilotos e à skin do Diogo. O mapeamento fica em `assets/kart/references/manifest.json`; as aparências dos modelos são definidas em `scripts/kart_appearance.gd`.

Os modelos preservam diferenças de cabelo, barba, óculos, roupas, calçados, cores e detalhes característicos. O quadril fica no banco, as pernas permanecem no cockpit e os braços acompanham o volante através de articulações. Curvas, aceleração e impactos inclinam o tronco sem soltar as mãos.

A condução usa aceleração progressiva, frenagem e ré, direção suavizada e aderência específica durante drift. O miniturbo continua sendo liberado ao soltar um drift carregado na pista. Rodas giram com o deslocamento, esterçam e acompanham a direção; o áudio do motor varia com o movimento.

Colisões laterais retiram a componente de velocidade contra a barreira e preservam a componente ao longo dela. Karts sobrepostos são separados, e os mesmos limites de pista e obstáculos são aplicados após colisões entre veículos. A recuperação manual e a recuperação de veículo preso ou afastado da pista retornam ao último checkpoint válido, sem conceder avanço.

A câmera suaviza posição e alvo, antecipa levemente curvas, varia discretamente o campo de visão e aproxima o enquadramento quando um prédio obstrui a linha de visão. A CPU considera o traçado à frente, reduz velocidade em curvas e ajusta a faixa ao encontrar outros karts ou objetos. Não recebe velocidade de recuperação baseada na distância até o jogador.

## UFN / Andradas

O quinto circuito é uma interpretação urbana original do entorno do Conjunto II da UFN, em Santa Maria. Inclui fachadas universitárias, área interna, calçadas, cruzamentos, postes, árvores, placas, cones e carros estacionados. O traçado faz referência às ruas dos Andradas, Serafim Valandro, Silva Jardim e Duque de Caxias, com distâncias e curvas adaptadas ao jogo.

A nova pista pode ser selecionada na **corrida rápida e no contrarrelógio**. O **campeonato mantém as quatro etapas clássicas**, assim como suas regras e seus salvamentos. A seleção de pistas passa a mostrar cinco cartões e permite escolha pelo mouse.

Cada volta exige os 20 portões na ordem correta, com cruzamento no sentido da corrida e dentro da largura válida. Cruzamentos invertidos, desvios laterais, checkpoints pulados e deslocamentos descontínuos não concedem volta. São necessárias três voltas completas.

[Referências geográficas, adaptações e implementação da pista](PISTA-UFN.md).

## Recursos e validação

Os efeitos de kart têm limite de 180 partículas ativas e as marcas de derrapagem reutilizam 96 objetos. Parar ou reiniciar a corrida limpa corredores, efeitos, obstáculos e estado de câmera. As animações de combate mantêm um cache limitado de topologias de sprite.

As novas suítes verificam os comportamentos da atualização:

| Suíte | Cobertura principal |
|---|---|
| `tests/ultimate050_test.gd` | Ambos os lados, acerto, defesa, erro, interrupção, aparo, dano, timers, controle, KO e reset |
| `tests/animation050_test.gd` | Movimento, integridade da malha, transições e apresentação das sequências |
| `tests/driver050_test.gd` | Identidade dos pilotos, referências, pose sentada e articulações |
| `tests/kart050_test.gd` | Três voltas reais de IA nas cinco pistas, tráfego, checkpoints, colisões, câmera, controles e limpeza |
| `tests/skin050_test.gd` | Mecânicas idênticas entre skins, seleção e progresso compartilhados |
| `tests/ally050_test.gd` | Arte própria da aliada, preservação de Maria, transparência, limites do atlas e encerramento do poder no kart |

As suítes anteriores continuam presentes. Os logs, as capturas, os resultados de integração e os limites da avaliação ficam em [QA.md](QA.md). A documentação de procedência está em [LICENSES.md](../LICENSES.md). Esta atualização não declara equivalência visual com uma reprodução fotográfica da cidade nem certificação de balanceamento competitivo.

Histórico preservado: [0.4.0 — Torres UFN](ATUALIZACAO-0.4.0.md) e [0.3.0 — base de combate e kart](ATUALIZACAO-0.3.0.md).
