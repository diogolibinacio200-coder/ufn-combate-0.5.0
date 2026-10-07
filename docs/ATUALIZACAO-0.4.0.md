# UFN Combate 0.4.0 — Torres UFN

Esta atualização reorganiza o modo Torre para seguir a linguagem visual da referência enviada: blocos empilhados, retratos encaixados em cada andar e uma queda física no encerramento. A identidade visual foi redesenhada para a UFN, mantendo os personagens e os chefes do projeto.

## Escolha antes da luta

O menu **TORRE UFN** abre quatro cartões com 3, 5, 8 ou 10 oponentes regulares. A dificuldade é escolhida separadamente em **FÁCIL**, **MÉDIO** ou **DIFÍCIL**. O personagem do jogador é escolhido depois, e os rivais regulares são sorteados sem repetição.

André CSTH e Kelvin continuam reservados para os dois andares finais de qualquer opção. Portanto, uma torre escolhida com 3 oponentes tem 5 andares persistidos; a torre de 10 tem 12.

## Progresso e final

O jogo salva o lutador, a skin, a dificuldade, a ordem sorteada e o próximo andar. Derrotas mantêm o mesmo rival para retry; vitórias avançam somente depois que o resultado é confirmado. Salvamentos antigos de dez andares continuam válidos e são tratados como oito oponentes regulares mais os dois chefes.

Quando Kelvin é derrotado, a retomada é limpa e a conquista é gravada imediatamente. A tela **TORRE CONQUISTADA** anima cada bloco: a base se abre, os andares inclinam, os retratos se soltam e partículas de poeira atravessam o pátio. Depois de alguns segundos, o final do campeão aparece.

## Verificação

- 500 verificações na suíte `tests/tower_test.gd`.
- 1.641 verificações no conjunto completo de onze suítes, sem falhas.
- Capturas reais em quatro resoluções e cinco momentos da desmontagem em [`screens/v040`](screens/v040/).
- Compatibilidade visual com 1280 × 720, 1920 × 1080, 1024 × 768 e 1680 × 720.

Veja [QA.md](QA.md) para os logs e [TECHNICAL.md](TECHNICAL.md) para o fluxo de dados.
