# Unificar Letra e Cifra

## Contexto

Hoje "Letra" e "Cifra" são dois recursos 100% independentes, tanto no backend
quanto no app: `Song.lyrics` (string solta) e `Song.chordSheetJson` (seções
estruturadas, cada linha já com seu próprio texto). Isso obriga quem cadastra
uma cifra a digitar a letra da música duas vezes, e as duas cópias não têm
nenhuma sincronização — uma correção feita numa não se reflete na outra.

O objetivo: "Letra" deixa de ser um dado próprio e vira apenas um **modo de
visualização** da cifra já existente (mesmas linhas de texto, sem os acordes
por cima). Quem só quer digitar a letra continua podendo fazer isso de forma
simples — só que por baixo isso cria/atualiza a mesma estrutura da cifra
(uma seção só, sem acordes), não um campo separado.

Achados que embasam a abordagem escolhida:
- O app **web** (`louvor4-web`) já resolveu esse mesmo problema: o editor de
  cifra de lá (`songs-chord-sheet.component.ts`) é uma única página com 3
  modos (visualizar / editar só texto / editar acordes), com utilitários
  prontos (`sectionsToPlainText`/`applyPlainTextToSections`) pra converter
  entre texto corrido e a estrutura de seções. É o precedente a seguir.
- No Flutter, `chord_sheet_page.dart` **já tem** um modo de edição chamado
  "Editar letra" (`_ChordSheetEditMode.lyrics`, via `LyricsSectionsEditor`)
  que edita texto/estrutura sem acordes — hoje é só um modo de *edição*
  interno à cifra, não um modo de *visualização* nem está ligado à tela
  separada `LyricsPage`. `chord_sheet_editor.dart` também já tem
  `editFullLyricsText`/`_splitLyricsIntoBlocks`, o equivalente Flutter do
  `applyPlainTextToSections` do web — ou seja, a peça de "colar texto corrido
  e virar linhas" já existe, só precisa ser reaproveitada como entrada
  principal em vez de estar escondida dentro do editor de cifra.
- No backend, `lyrics` e `chordSheetJson` são colunas totalmente
  independentes (confirmei: `deleteChordSheet` nem toca em `lyrics`). Não há
  Flyway/Liquibase — migrações são SQL manual em `docs/migrations/`. O
  setlist/repertório do evento não expõe letra nem cifra (só a flag de
  permissão), então essa mudança **não afeta a API de eventos**.
- Existe uma assimetria de permissão pra resolver: editar "letra" hoje é
  owner-only, enquanto editar "cifra" já aceita permissão colaborativa
  (`EventSong.editChordSheetPermission` / `canEditChordSheetOf`). Como editar
  letra vai passar a ser literalmente editar a cifra, ela **herda** a
  permissão colaborativa — é uma melhoria, não uma regressão (quem já pode
  corrigir acorde errado passa a poder corrigir palavra errada também).
- Escopo desta rodada: **só o app Flutter + backend**. O app web
  (`louvor4-web`) tem a mesma duplicação, mas já tem a peça de UI pronta
  (páginas de letra e cifra separadas, chamando os mesmos endpoints) — fica
  como follow-up separado, não mexo nele agora pra não estourar escopo.

## Abordagem

### Backend (`louvor4-api`)

1. **Migração de dados (one-off, script/endpoint administrativo temporário)**:
   para toda `Song` que tenha `lyrics` preenchido e `chordSheetJson` nulo,
   gerar um `chordSheetJson` mínimo: `schemaVersion: 1`, uma seção
   (`type: "other"`, sem label), uma `ChordLineEntity` por linha do texto
   (quebra por `\n`, sem acordes). Rodar uma vez contra o banco (dev depois
   produção). Como não há runner de migração automatizado neste repo, o mais
   simples é um `CommandLineRunner`/endpoint admin temporário, removido depois
   de rodar — documentar o passo em `docs/migrations/` seguindo a convenção
   existente (arquivo descritivo, ex.
   `docs/migrations/backfill_chord_sheet_from_lyrics.md` explicando o passo,
   já que não é um `ALTER TABLE` simples).
2. **Não apagar a coluna `lyrics` nem os endpoints `/lyrics` ainda** — deixar
   como está, só parar de chamá-los do app depois que a migração de dados
   rodar. Remoção de coluna/endpoint fica pra uma limpeza posterior, depois
   de confirmar que nenhum cliente depende mais deles (baixo risco, mas sem
   necessidade de fazer agora).
3. Nenhuma mudança em `EventSongMapper`/`EventSongDTO`/setlist — já não
   expõem letra/cifra.

### Flutter (`louvor4_app`)

1. **`chord_sheet_view.dart`**: adicionar um parâmetro `showChords: bool`
   (default `true`) em `ChordSheetView`/`_ChordLine`. Quando `false`, renderiza
   só `line.text` (pula a linha de acordes montada por `buildChordLineText`).
   Decidir o comportamento pra seções `chordSequence` (sem texto próprio) no
   modo letra: ocultar essas seções nesse modo, já que não têm palavra
   nenhuma pra mostrar.
2. **`chord_sheet_page.dart`**: adicionar um toggle visível (chip/switch) no
   modo de leitura pra alternar `showChords` true/false sem sair da página —
   espelha o padrão de 3 modos do app web. Isso passa a ser a **única** tela
   pra letra e cifra.
3. **Botões em `song_detail_page.dart`**: mantêm os dois botões existentes
   ("Ver letra" / "Ver cifra") por familiaridade de UX, mas os dois agora
   abrem a **mesma** `ChordSheetPage`, diferindo só no `showChords` inicial
   (`false` pro botão "Ver letra", `true` pro "Ver cifra"). Atualizar os 2
   call sites que hoje abrem `LyricsPage`: `songs_list_page.dart`
   (`_goToLyrics`, ~L246) e `event_detail_page.dart` (`_openLyrics`, ~L1080)
   — trocar para abrir `ChordSheetPage` com `showChords: false`, usando o
   mesmo `canEdit` que já é passado pra `_openChords`
   (`state.canEditChordSheetOf(song)`), resolvendo a assimetria de permissão.
4. **Entrada rápida "só letra"**: quando a música ainda não tem cifra
   nenhuma, abrir `full_lyrics_text_page.dart` diretamente (reaproveitar como
   está) e, ao salvar, criar a `ChordSheetEntity` com uma seção/linhas sem
   acordes — reaproveitando o mesmo caminho que `editFullLyricsText` em
   `chord_sheet_editor.dart` já usa pra dividir texto colado em linhas
   (`_splitLyricsIntoBlocks`), só que chamado como fluxo de criação em vez de
   edição.
5. **Remover**: `lyrics_page.dart` (326 linhas), `getSongLyrics`/
   `updateSongLyrics` de `songs_repository.dart` + impl (`GET`/`PUT
   /songs/{id}/lyrics` deixam de ser chamados pelo app).
6. **`chord_sheet_pdf_builder.dart`**: sem mudança obrigatória agora — cifra
   exportada continua completa (texto + acordes). Se quiser um PDF "só
   letra" no futuro, é outra tarefa.

## Arquivos principais a mexer

- `lib/features/songs/presentation/widgets/chord_sheet_view.dart` — flag `showChords`
- `lib/features/songs/presentation/pages/chord_sheet_page.dart` — toggle de modo, novo ponto de entrada único
- `lib/features/songs/presentation/pages/song_detail_page.dart` — os 2 botões roteando pra mesma página
- `lib/features/songs/presentation/pages/songs_list_page.dart` — `_goToLyrics`/`_goToChords`
- `lib/features/events/presentation/pages/event_detail_page.dart` — `_openLyrics`/`_openChords` (dentro de `_SongsTab`)
- `lib/features/songs/data/songs_repository.dart` + `impl/songs_repository_impl.dart` — remover métodos de lyrics
- `lib/features/songs/presentation/pages/lyrics_page.dart` — remover arquivo
- Backend: script/endpoint de migração one-off (novo), sem alterar `SongController`/`SongServiceImpl` além do necessário pra rodar o backfill

## Verificação

- `flutter analyze` e `flutter test` no `louvor4_app` depois das mudanças
  (mesma checagem que já vimos rodando nas últimas tarefas: 182 testes
  passando, as 10 falhas pré-existentes de `event_program_tab_test.dart` não
  relacionadas).
- Testar manualmente: música sem cifra → "Ver letra" abre editor de texto
  simples → salvar → reabrir "Ver cifra" mostra a mesma letra, agora dentro
  da estrutura de seções, sem acordes ainda. Adicionar acordes → "Ver letra"
  continua mostrando só o texto, sem os acordes.
- Backend: rodar o backfill contra o banco de dev, conferir com uma query
  que toda `Song` com `lyrics` preenchido passou a ter `chord_sheet_json`
  equivalente. Rodar os testes Java existentes
  (`SongServiceImplChordSheetTest`, `ChordSheetValidationTest`).
