---
status: todo
sprint: ""
epic: ""
model: sonnet
effort: medium
depends_on: [US-001, US-002, US-003, US-004, US-005]
blocked_reason: ""
blocked_solutions: []
---

> **DRAFT** — non passee par la boucle redteam. A valider (redteam-story) avant tout developpement.

# US-006 — Release taguee + CI + notes de migration

## Description

En tant qu'app hote, je veux consommer le kit via une **dependance git taguee** validee par une CI,
afin que mes builds CI/Docker/production soient reproductibles et que je sache exactement quel code
d'authentification j'embarque.

## Contexte

Le repo n'a **aucun tag** a ce jour (`git tag` → vide) et aucune CI. La seule integration tentee a
ce jour utilisait `{:evo_phx_kit, path: "../../evo-phx-kit"}`, qui ne resout pas hors du checkout
local du developpeur : le build CI, l'image Docker et le deploiement echouent. Une dependance
`branch:` n'est pas une option non plus — la branche peut avancer entre deux builds du meme commit
de l'app hote.

Par ailleurs, le kit porte desormais l'integralite du gate d'authentification de ses consommateurs,
alors que les outils SAST des apps hotes (sobelow, credo, gitleaks) ne scannent que leur propre
arborescence, jamais leurs dependances. Le code le plus sensible se retrouverait donc dans la zone
la moins couverte.

Cette story est la derniere du lot : elle ne peut etre livree qu'apres US-001 a US-005, puisque
c'est la version tagguee qui matérialise le contrat complet.

## Perimetre

- **CI GitHub Actions** sur `push` et `pull_request` : `mix deps.get`, `mix compile
  --warnings-as-errors`, `mix format --check-formatted`, `mix test`.
- **Analyse statique** dans la meme CI : `credo --strict` et `sobelow` (le kit contient des plugs
  Phoenix), puisqu'aucun consommateur ne scannera ce code.
- **CHANGELOG.md** avec une section de migration v0.1.0 → v0.2.0 listant les breaking changes du
  contrat :
  - `SessionProvider.session_revoked?/1` → `session_valid?/2` (US-001)
  - `UserProvider.get_user!/1` → `fetch_user/1` (US-003)
  - `authorize/1` optionnel ajoute (US-004)
  - cle de config `auth_unauthenticated_path` (US-005), distincte de `auth_logout_path`
  - cle de config `require_session_revocation` (US-002)
- **README** : remplacer le squelette `mix new` (« TODO: Add description ») par la description
  reelle, l'exemple de config complet, le tableau des behaviours a implementer et la section
  « regle de genericite » (cf. `CLAUDE.md`).
- **Tag `v0.2.0`** cree apres CI verte et revue securite du diff cumule US-001..US-005.

## Criteres d'acceptation

- [ ] **AC1** — Workflow CI ajoute ; compile, format, tests verts sur `main` (todo)
- [ ] **AC2** — `--warnings-as-errors` actif a la compilation (todo)
- [ ] **AC3** — `credo --strict` et `sobelow` integres a la CI et verts (todo)
- [ ] **AC4** — `CHANGELOG.md` cree, section v0.2.0 listant les 5 breaking changes avec, pour
      chacun, le motif de code avant/apres (todo)
- [ ] **AC5** — README reecrit : description, installation via `git:`+`tag:`, config complete,
      tableau des behaviours, regle de genericite (todo)
- [ ] **AC6** — `version` de `mix.exs` passee a `0.2.0` (todo)
- [ ] **AC7** — Revue securite du diff cumule US-001..US-005 effectuee (Opus — le kit porte le gate
      d'authentification de ses consommateurs) avant tag (todo)
- [ ] **AC8** — Tag `v0.2.0` cree et pousse sur `origin` apres AC1-AC7 (todo)

## Cas limites

- **E1 — Tag deplace apres coup.** Un tag reecrit change le code sous un `mix.lock` deja fige chez
  un consommateur, sans changer le hash attendu. Regle : un tag publie est immuable ; toute
  correction donne un nouveau tag.
- **E2 — Consommateur bloque sur v0.1.0.** Aucun a ce jour (le kit n'est en production nulle part),
  mais la regle vaut pour la suite : v0.1.0 reste accessible et non modifiee.
- **E3 — Repo public.** Le kit est public et ne doit contenir aucun secret ni aucune reference a
  l'infrastructure d'une app hote. A verifier avant tag (gitleaks en CI, AC3 adjacent).

## Points a arbitrer (redteam)

1. Publier sur Hex plutot que consommer via `git:`+`tag:` — plus standard, versions immuables par
   construction, mais expose publiquement le package et impose une discipline de release.
2. Faut-il un check CI cote **app hote** verifiant que le tag epingle dans `mix.lock` correspond a
   un tag revu (et alerter au bump), ou la revue manuelle du diff au moment du bump suffit-elle ?
