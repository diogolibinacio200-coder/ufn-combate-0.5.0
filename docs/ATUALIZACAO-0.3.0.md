# UFN Combate 0.3.0 — atualização arcade

Evolução do projeto de Diogo Liberalesso Inácio, a partir do commit `60cd035ead731a5f11ea80b20957d66054e3a05a` de `diogolibinacio200-coder/ufn-combate`. Mantém elenco, arenas, perfis e modos existentes.

## Combate e comandos

**Trás + A1** executa o especial A de cada personagem. **Frente → baixo + A2** executa uma nova técnica ofensiva própria. **Trás + baixo + A1** acessa o especial B e **baixo → frente + A3** acessa o C. Os comandos antigos continuam válidos; A3 sozinho continua sendo chute. Frente/trás acompanham o adversário para J1 e J2.

Direções têm janela de 18 frames (300 ms); ações têm buffer de oito frames. Especiais têm prioridade e ficam registrados durante recuperação, sem gastar energia duas vezes nem gerar normal quando falta recurso.

Esquiva em **Shift / Num0 / B**, remapeável, com recuperação e intervalo. A cadeia de três leves exige acertos; normais e especiais mantêm cancelamentos e limites. Cima + forte é ascendente; baixo + forte é rasteira forte; frente + forte avança; trás + forte é reversão.

Os 14 jogáveis compartilham atributos básicos de vida, deslocamento e salto. Foram removidos bônus passivos gerais de dano/recuperação de alguns lutadores; Embalo, irritação e transformação continuam diferenciando estilos. Chefes preservam regras próprias.

## Apresentação

Poses acompanham preparação, contato e recuperação; idle/guarda têm respiração discreta. Acertos aplicam flash curto; hitstop, sons, partículas e tremor existentes continuam ativos. Ultimates de captura passam de 3,5 para dois segundos, mantendo dano e seis impactos. Mirkos e André conservam suas mecânicas específicas.

Nas duas skins de Diogo, efeitos usam pontos de mão por pose e são desenhados atrás do corpo completo. O ascendente usa o braço erguido. A revisão também corrigiu falha de desenho nas bolas em rotação. Os limites da investigação da mão estão em [QA.md](QA.md).

HUD com retratos, vida, guarda, energia, Ultimate e controles; barras acompanham as bordas. Fundo cobre a viewport com proporções preservadas; câmera interpola centro e zoom até 8,5%. Tela cheia é padrão em perfis novos; configurações existentes são mantidas. F11 alterna o modo.

O guia exibe nomes das quatro técnicas, custo/dano e teclas atuais. Tab abre o personagem na seleção; a pausa mantém acesso. Após oito segundos, menu e seleção exibem uma luta de CPU isolada, sem gravar estatísticas nem substituir escolhas. Interação encerra a demonstração.

## Kart

Piloto arcade sentado com quadril, coxas, joelhos, pernas e pés no cockpit. Braços acompanham pontos do volante; tronco reage a direção, aceleração, boost, impacto, salto e poder exclusivo. Cores, cabelo, barba, óculos e roupa identificam os pilotos. A modelagem permanece simples.

Veículos têm assento, pedais, carenagem aberta, motor, escapamentos, faróis e rodas com pivôs de esterço/giro. Geometria estática é agrupada por material. Câmera mais próxima e baixa.

Aceleração, frenagem e resposta da direção foram ajustadas. Drift acumula carga conforme a curva e rende miniturbo ao soltar na pista, sem recompensar interrupção por colisão. Marcas de pneus usam pool de 96 instâncias; o motor varia durante derrapagem. Itens, recuperação, checkpoints, voltas, quatro pistas e divisões de tela foram preservados.

## Entrega

1.141 verificações automatizadas passaram. Capturas em quatro resoluções e testes do PCK estão registrados em [QA.md](QA.md). O projeto contém os testes novos, capturador visual e guias atualizados.

Extraia o ZIP Windows em uma pasta nova e execute `UFNCombate.exe` com `UFNCombate.pck` ao lado. O perfil usa o mesmo local anterior. Para editar, importe `project.godot` no Godot 4.7.2 Standard.

A entrega não comprova desempenho nativo no Windows nem equilíbrio competitivo. Também não substitui os sprites por animações inteiramente redesenhadas. Nenhuma release pública 0.3.0 foi criada automaticamente.
