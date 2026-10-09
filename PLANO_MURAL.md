# Mural do projeto — Responsabilidades

## Contexto

Ministérios têm funções fixas que ficam com uma pessoa por um período e depois
passam para outra (ex.: "Direção musical" com o João em outubro, com a Maria
em novembro). Hoje isso não existe no app — fica em grupo de WhatsApp.

O **Mural** é uma página nova do projeto que, nesta primeira versão, mostra só
as **responsabilidades** do projeto e quem está com cada uma. O líder edita
para trocar o responsável e o período; o app guarda o histórico e avisa o
membro, na tela de Início, que ele está com aquela responsabilidade.

## Decisões

| Tema | Decisão |
|---|---|
| Onde fica | Página nova, aberta pelo item **Mural** no menu ⋮ do header do projeto |
| Menu ⋮ | Passa a aparecer para **todos** os membros: membro vê só "Mural"; admin vê também Dashboard / Editar / Excluir |
| Conteúdo do Mural | Só responsabilidades (Fixados/comunicados ficam para depois) |
| Período | Datas livres (início/fim), com atalho "mês inteiro" |
| Quem edita | Só admin/owner; membros só visualizam |
| Troca de responsável | O líder edita a responsabilidade; a troca gera um novo período e o anterior vai para o histórico |
| Histórico | Guardado (cada troca é um registro); visível na página da responsabilidade |
| Pessoas por período | 1 |
| Aviso ao membro | Card na tela de **Início** com as responsabilidades atuais (e a próxima, se já agendada) |
| Plataformas | App primeiro, web depois |

## Fluxos

### Abrir o Mural
Projeto → menu ⋮ → **Mural**. Lista de cards:
```
🎼 Direção musical
   João · 01/10 a 31/10            ✎   ← lápis só para admin
🔊 Som
   Sem responsável no momento      ✎
```
- Se o usuário logado é o responsável, o card destaca: "Você · até 31/10".
- Período terminou e ninguém foi definido depois → "Sem responsável no
  momento" (o último aparece em "Último: João até 31/10").
- Vazio: estado vazio explicando o recurso + botão "Nova responsabilidade"
  (admin). Admin também tem FAB "+".

### Criar responsabilidade (admin)
"+" → nome (obrigatório), descrição (opcional), responsável (opcional),
período (atalho **Mês** ou **Datas**) → salvar.

### Editar / trocar responsável (admin)
Tocar no ✎ abre o mesmo formulário já preenchido com nome, descrição e o
**período atual** (responsável + datas):
- **Mudou só nome/descrição** → atualiza a responsabilidade.
- **Mudou só as datas** (mesmo responsável) → ajusta o período atual (ex.:
  estender até dezembro). Não gera histórico novo.
- **Mudou o responsável** → cria um **novo período** com a pessoa e datas
  escolhidas. O período anterior é preservado no histórico; se ele avançava
  além do início do novo, a API o encerra no dia anterior ao novo início.
  O atalho **Mês** já sugere o mês seguinte ao fim do período atual.

### Ver histórico
Tocar no card → página da responsabilidade: descrição + lista de períodos,
do mais recente para o mais antigo (atual destacado, passados esmaecidos).
Admin pode corrigir/excluir um período passado (erro de cadastro).

### Tela de Início (todos os membros)
No topo da aba "Próximos", se o usuário tiver responsabilidades vigentes ou
agendadas, aparece um card:
```
Suas responsabilidades
🎼 Direção musical · Louvor Central · até 31/10
🔊 Som · Banda X · a partir de 01/11
```
Tocar num item abre o Mural do projeto correspondente. Sem responsabilidades,
o card não aparece.

### Membro sai do projeto / conta excluída
Períodos passados e o atual ficam no histórico (com o nome da pessoa, ou
"Usuário removido"). Períodos que **ainda não começaram** são removidos junto
com a saída (mesma regra de eventos futuros em `ProjectMembershipRemover`).

## Backend (`louvor4-api`)

### Tabelas (`docs/migrations/add_project_responsibilities.sql`)

```sql
CREATE TABLE project_responsibilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    music_project_id UUID NOT NULL REFERENCES music_projects(id),
    name VARCHAR(80) NOT NULL,
    description VARCHAR(500),
    position INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
CREATE INDEX idx_responsibilities_project ON project_responsibilities (music_project_id);

-- Histórico: cada troca de responsável é um registro.
CREATE TABLE project_responsibility_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    responsibility_id UUID NOT NULL REFERENCES project_responsibilities(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES music_project_members(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP NOT NULL,
    CHECK (end_date >= start_date)
);
CREATE INDEX idx_resp_assignments_resp ON project_responsibility_assignments (responsibility_id, start_date);
CREATE INDEX idx_resp_assignments_member ON project_responsibility_assignments (member_id, end_date);
```

### Endpoints

Leitura: `@projectSecurity.isMember(projectId)`. Escrita: `isAdminOrOwner(projectId)`.

| Método | Rota | Descrição |
|---|---|---|
| GET | `/music-project/{projectId}/responsibilities` | Lista do Mural: cada responsabilidade com `current`, `next` e `last` (último encerrado) já calculados |
| POST | `/music-project/{projectId}/responsibilities` | Criar (nome, descrição, e opcionalmente `memberId` + `startDate` + `endDate`) |
| PUT | `/music-project/{projectId}/responsibilities/{id}` | Editar nome/descrição e o período atual (regras do fluxo "Editar") |
| DELETE | `/music-project/{projectId}/responsibilities/{id}` | Excluir (com histórico) |
| GET | `/music-project/{projectId}/responsibilities/{id}/assignments` | Histórico completo |
| PUT | `/music-project/{projectId}/responsibilities/{id}/assignments/{assignmentId}` | Corrigir um período |
| DELETE | `/music-project/{projectId}/responsibilities/{id}/assignments/{assignmentId}` | Excluir um período |
| GET | `/users/responsibilities` | Do usuário logado, em todos os projetos: períodos com `end_date >= hoje` (atuais e agendados), com nome/id do projeto — alimenta o card da tela de Início |

Todo id da rota é validado como pertencente ao `projectId` (mesma mensagem de
"não encontrado" para não revelar ids de outros projetos).

### Regras de negócio
- `endDate >= startDate`; membro precisa estar ACTIVE no projeto.
- Sem sobreposição de períodos na mesma responsabilidade. Na troca de
  responsável, o período vigente que avança além do novo início é encerrado
  em `novoInicio - 1` (se o novo começa antes até do início do vigente, a API
  recusa com mensagem clara em vez de apagar histórico).
- `current` = período que contém hoje; `next` = primeiro com início > hoje;
  `last` = último com fim < hoje (para "Último: João até 31/10").
- `ProjectMembershipRemover.remove`: apagar períodos do membro com
  `start_date > hoje`.
- Projeto excluído (soft delete) / membro removido: consultas de
  `/users/responsibilities` ignoram projetos excluídos e vínculos não ACTIVE.

### Testes
Service: criar com e sem responsável; editar só nome; editar só datas; trocar
responsável (encerra o anterior no dia certo, preserva histórico); novo início
antes do vigente recusado; sobreposição recusada; membro não ativo recusado;
cálculo de current/next/last nas bordas (hoje = início, hoje = fim);
`/users/responsibilities` só traz vigentes/agendados de projetos ativos;
remoção de membro apaga só os futuros; ids de outro projeto recusados.

## App (`louvor4_app`)

- `music_project_overview_page.dart`: menu ⋮ visível para todos; item
  **Mural** (para todos) no topo; Dashboard/Editar/Excluir continuam só para
  admin/owner.
- Nova feature `features/project_board/`:
  - `data/`: `responsibilities_repository.dart` + impl.
  - `domain/entities/`: `ResponsibilityEntity` (com `current`/`next`/`last`),
    `ResponsibilityAssignmentEntity`, `MyResponsibilityEntity` (com projeto).
  - `presentation/`:
    - `project_board_page.dart` — a página do Mural (lista, pull-to-refresh,
      skeleton, estado vazio, FAB para admin).
    - `responsibility_card.dart` — card com destaque "Você".
    - `responsibility_form_sheet.dart` — criar/editar (nome, descrição,
      responsável, período com atalho Mês/Datas).
    - `responsibility_history_page.dart` — histórico.
    - cubits correspondentes.
- Tela de Início (`events_list_page.dart`, aba "Próximos"): card
  `MyResponsibilitiesCard` no topo, alimentado por `GET /users/responsibilities`
  (carregado junto com os eventos e no pull-to-refresh). Tocar abre o Mural do
  projeto.

## Fora do escopo desta rodada
- Fixados/comunicados no Mural.
- Push "amanhã você assume X" (job diário no `InternalJobController`).
- Mais de uma pessoa por período.
- Gerar períodos automaticamente a partir de uma lista de membros.
- Mural no `louvor4-web`.

## Verificação
- API: testes novos do service + `mvn test`.
- App: `flutter analyze`, `flutter test` (mesmas 10 falhas pré-existentes),
  teste manual: membro comum vê o menu ⋮ só com "Mural"; admin cria
  "Direção musical" com João em outubro; João vê o card no Início; admin troca
  para Maria em novembro → histórico mostra os dois e o Início do João deixa
  de mostrar quando o período dele acaba.
