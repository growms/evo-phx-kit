---
status: todo
sprint: ""
epic: ""
model: sonnet
effort: medium
depends_on: [US-001, US-002, US-003, US-004]
blocked_reason: ""
blocked_solutions: []
---

> **DRAFT** — non passee par la boucle redteam. A valider (redteam-story + revue securite Opus)
> avant tout developpement.

# US-005 — Parite stricte plug HTTP ↔ hook LiveView

## Description

En tant qu'app hote, je veux que le gate HTTP et le gate LiveView du kit prennent **exactement la
meme decision** et redirigent **au meme endroit**, afin qu'un utilisateur refuse sur une page ne
soit pas accepte sur une autre selon qu'elle est servie par un controller ou par une LiveView.

## Contexte

Les deux gates ont diverge des la v0.1.0, sur trois axes.

**Destination de redirection** — 3 cibles differentes pour le meme evenement « pas authentifie » :

| Gate | Cas | Destination actuelle |
|---|---|---|
| `RequireAuth` | session absente | `"/login"` (en dur) |
| `RequireAuth` | session revoquee | `"/login"` (en dur) |
| `EnsureAuthenticated` | session absente | `EvoPhxKit.auth_logout_path()` (defaut `/auth/logout`) |
| `EnsureAuthenticated` | session revoquee | `"/login"` (en dur) |

Le cas « session absente » envoie donc l'utilisateur vers **deux pages differentes** selon le type
de route. `auth_logout_path/0` est manifestement detourne de son sens (deconnexion volontaire) pour
servir de page d'entree.

**Purge de session** — `RequireAuth` fait `configure_session(drop: true)` sur revocation ; le hook
ne peut pas (une LiveView connectee n'ecrit pas la session). L'asymetrie est structurelle, mais
elle doit etre **documentee et compensee**, pas subie.

**Logique dupliquee** — chaque gate porte sa propre copie de la resolution du provider (traite en
US-002) et sa propre sequence de verifications. Deux copies divergent toujours ; c'est deja arrive.

## Perimetre

- Ajouter `EvoPhxKit.auth_unauthenticated_path/0` →
  `Application.get_env(:evo_phx_kit, :auth_unauthenticated_path, "/login")`.
- Remplacer les **4** destinations en dur / detournees par cet appel unique.
- `auth_logout_path/0` n'a plus aucun appelant interne. Le conserver dans l'API publique (usage
  legitime : bouton de deconnexion explicite d'une app hote) et documenter dans son `@doc` qu'il
  n'est plus utilise par les gates.
- Extraire la sequence de decision commune dans un module unique (ex. `EvoPhxKit.Auth.Gate`)
  consomme par le plug et par le hook, chacun ne gardant que son adaptateur d'effet (halt/redirect
  Plug vs `{:halt, redirect}` LiveView, et le drop de session cote plug uniquement). Ordre canonique
  de la sequence, une seule fois :
  1. session absente → refus
  2. `EvoPhxKit.session_valid?/2` faux → refus (US-001, US-002)
  3. `fetch_user/1` → `:error` → refus (US-003)
  4. `authorize/1` → `{:error, _}` → refus (US-004)
  5. sinon → acces, assigns (`current_user`, `locale`)
- Documenter l'asymetrie de purge : le hook ne vide pas la session, la purge effective a lieu au
  prochain hit HTTP sur une route protegee. Une app hote qui a besoin d'une purge immediate doit
  provoquer une navigation HTTP (`redirect` externe) plutot qu'un `push_navigate` interne.

## Criteres d'acceptation

- [ ] **AC1** — `EvoPhxKit.auth_unauthenticated_path/0` ajoute, defaut `"/login"` (todo)
- [ ] **AC2** — Les 4 redirections des deux gates utilisent ce chemin ; plus aucun `"/login"` en
      dur ni `auth_logout_path()` dans les gates (todo)
- [ ] **AC3** — Sequence de decision extraite dans un module unique, consomme par le plug et le
      hook ; aucune logique de decision dupliquee ne subsiste (todo)
- [ ] **AC4** — `auth_logout_path/0` conservee, `@doc` mis a jour (plus d'appelant interne) (todo)
- [ ] **AC5** — Test de parite exhaustif, table-driven : pour chacun des 5 cas de la sequence, le
      plug et le hook produisent la meme decision et la meme destination (todo)
- [ ] **AC6** — Test : `auth_unauthenticated_path` surchargee en config → les deux gates suivent la
      nouvelle valeur (todo)
- [ ] **AC7** — Test : le plug droppe la session sur refus post-authentification (revocation,
      utilisateur introuvable, autorisation refusee) et **ne la droppe pas** quand il n'y a pas de
      session du tout (todo)
- [ ] **AC8** — README : tableau des cas de refus et de leur destination (todo)

## Cas limites

- **E1 — `auth_unauthenticated_path` pointant vers une route elle-meme protegee.** Boucle de
  redirection infinie. Le kit ne peut pas le detecter (il ne connait pas le routeur de l'hote) ; a
  documenter comme piege de configuration.
- **E2 — Migration d'une app hote qui configurait `auth_logout_path` en croyant couvrir le cas
  « non authentifie ».** Le changement de cle est silencieux (l'ancienne valeur reste valide pour
  la deconnexion). A signaler explicitement dans les notes de migration (US-006).
- **E3 — Redirection depuis un mount LiveView statique (dead render) vs connecte.** Les deux
  passent par `redirect/2` ; comportement identique attendu, a couvrir en test.

## Points a arbitrer (redteam)

1. Extraire la sequence dans un module partage (`EvoPhxKit.Auth.Gate`) vs garder deux
   implementations et se contenter d'un test de parite. Le module partage supprime la classe de bug
   a la racine ; le test de parite la detecte seulement.
2. Faut-il conserver `auth_logout_path/0` (aucun appelant apres cette story) ou la supprimer
   franchement, le kit etant encore en v0.x sans consommateur en production ?
