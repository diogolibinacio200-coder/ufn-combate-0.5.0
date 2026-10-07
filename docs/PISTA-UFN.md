# Pista UFN / Andradas — referências e adaptação

**UFN / Andradas** é o quinto circuito do Kart UFN, introduzido na 0.5.0. A região de referência é o entorno do Conjunto II da Universidade Franciscana, em Santa Maria/RS. A geometria é original, construída no código para uma corrida arcade.

## Geografia de referência

O portal institucional informa o **Conjunto II na Rua Silva Jardim, 1323**, e o **Conjunto I na Rua dos Andradas, 1614**. Esses endereços distinguem o prédio de referência das ruas usadas no circuito; o nome UFN / Andradas não muda o endereço do Conjunto II. Fonte: [Universidade Franciscana — endereços dos conjuntos](https://oportunidades.ufn.edu.br/interesse-em-graduacao).

A Prefeitura identifica o trecho da Rua Silva Jardim junto ao Conjunto II **entre Duque de Caxias e Serafim Valandro**, e também descreve o segmento de Duque de Caxias entre Silva Jardim e Andradas. Essa informação orienta as relações entre as ruas, sem importar regras temporárias de trânsito para a corrida. Fonte: [Prefeitura de Santa Maria — organização do trânsito para o vestibular, janeiro de 2025](https://www.santamaria.rs.gov.br/smsop/noticias/29131-prefeitura-comunica-adequacoes-do-transito-e-reforco-dos-onibus-para-o-vestibular-neste-final-de-semana).

O mapa fornecido pelo autor em 5 de outubro de 2026 serviu como referência inicial. A consulta cartográfica complementar foi ao [ponto do Conjunto II no Waze](https://www.waze.com/live-map/directions/br/rs/universidade-franciscana-ufn-conjunto-ii?to=place.ChIJn7B3s1zLA5URTfmsmggh9fo). As fontes foram consultadas para a implementação em 5 de outubro; os dois endereços oficiais acima foram reconferidos em 7 de outubro de 2026.

## Percurso no jogo

A volta foi organizada como um circuito fechado: **Andradas → Serafim Valandro → Silva Jardim → Duque de Caxias → Andradas**. A largada fica no setor inspirado em Andradas. Os nomes aparecem na sinalização ao longo dos quatro lados do percurso.

O desenho usa 12 pontos de controle suavizados para oferecer retas, aproximação de curvas e espaço para ultrapassagem. Largura de pista, distâncias, esquinas, recuos e fachadas são adaptações de jogabilidade. Não se trata de levantamento topográfico, réplica arquitetônica ou reprodução das mãos de trânsito reais.

O bloco central inclui volumes identificados como **UFN • Conjunto II**, **Engenharias** e **ITEC / UFN**, galerias e uma área interna. As fachadas, o pátio, as entradas e os comércios são composições estilizadas, não representações documentais de cada instalação ou estabelecimento. Há também calçadas, travessias, iluminação pública, árvores, cones e veículos estacionados.

As ruas laterais terminam em limites visíveis do circuito. As barreiras delimitam o corredor dirigível, os cones e carros têm volumes de contato, e os prédios fornecem limites para a câmera. O jogador não pode usar os quarteirões como uma segunda rota para validar voltas.

## Regras de corrida

- São **três voltas**, cada uma com **20 portões ordenados**; a linha de chegada é o portão zero.
- Um portão só conta quando o veículo cruza do lado anterior para o posterior, dentro da largura válida e no sentido de avanço.
- Pular portões, cruzar de ré ou longe da faixa não concede progresso. Mudanças de posição maiores que a tolerância por passo também não contam como cruzamento.
- Reposicionar o kart retorna ao último portão validado, sem adiantar o próximo checkpoint.
- A corrida rápida usa oito corredores; o contrarrelógio é solo. O campeonato continua usando as quatro pistas clássicas.

A IA percorre a mesma pista, usa os mesmos limites de velocidade e precisa validar os mesmos portões. A antecipação de curvas e o desvio de tráfego e objetos atuam nos comandos de aceleração e direção.

## Implementação e procedência

| Arquivo | Responsabilidade |
|---|---|
| `scripts/kart_ufn_track.gd` | Pontos do circuito, arquitetura, placas, postes, árvores e objetos urbanos |
| `scripts/kart.gd` | Condução, barreiras, contatos, checkpoints, IA, recuperação e câmera |
| `scripts/interface.gd` | Cartão e miniatura original da nova pista |
| `tests/kart050_test.gd` | Voltas reais de IA e tentativas inválidas de progresso, colisão e câmera |

O mapa enviado e imagens de Street View não foram incorporados como texturas. Os prédios, superfícies, placas e objetos foram construídos como geometria do jogo; as fontes geográficas não fornecem uma licença geral para copiar sua cartografia ou suas fotografias. Os créditos e a procedência dos demais materiais estão em [LICENSES.md](../LICENSES.md).

Os resultados e as capturas da validação atual constam em [QA.md](QA.md).
