# Backlog — evo-phx-kit

Stories non planifiees. Numerotation locale au repo (`US-001`...), independante d'ECF.

## Lot « contrat d'authentification » (draft, non redteame)

Objectif : porter dans le kit le **contrat** dont une app hote reelle a besoin pour brancher sa
politique d'acces, sans que le kit connaisse cette politique. Origine : l'audit de la migration
d'ECF (branche `wt1`, abandonnee) a montre que le gate v0.1.0 du kit constituait une regression
fonctionnelle sur 5 points face au gate maison d'ECF.

| # | Story | Sujet | Ecart comble | Taille |
|---|-------|-------|--------------|--------|
| 1 | [US-001](stories/US-001-Session-Revocation-Watermark.md) | `session_valid?/2` avec watermark `authenticated_at` | Une session anterieure a une revocation redevient valide apres deblocage | L |
| 2 | [US-002](stories/US-002-Session-Provider-Fail-Closed.md) | Resolution fail-closed du `session_provider` | `session_provider` absent → revocation silencieusement desactivee | M |
| 3 | [US-003](stories/US-003-User-Provider-Fetch-Fail-Closed.md) | `fetch_user/1` au lieu de `get_user!/1` | Compte supprime → 500 au lieu d'une redirection | M |
| 4 | [US-004](stories/US-004-Authorization-Gate.md) | Callback optionnel `authorize/1` | Aucun point d'extension : l'hote doit reimplementer le gate ou polluer le kit | L |
| 5 | [US-005](stories/US-005-Parite-Plug-Hook.md) | Parite stricte plug ↔ hook | 3 destinations de redirection differentes, sequences dupliquees | M |
| 6 | [US-006](stories/US-006-Release-Taguee-CI.md) | CI + CHANGELOG + tag `v0.2.0` | Aucun tag, aucune CI → `path:` obligatoire, non buildable en prod | M |

**Ordre** : US-001 → US-002 (meme surface), US-003 → US-004 (meme surface), puis US-005 (unifie),
puis US-006 (tag du contrat complet). US-001/002 et US-003/004 sont independants entre eux et
parallelisables.

**Prealable** : ces stories sont des **drafts**. Elles doivent passer la boucle redteam
(`redteam-story`, plus une revue securite Opus — le kit porte le gate d'authentification de ses
consommateurs) avant tout developpement.

**Consommateur en attente** : ECF US-309 (migration vers le kit) est explicitement bloquee tant que
ce lot n'est pas livre et tague.

## Divers

- Verifier si `EvoPhxKit.Auth.Zitadel` doit rester dans le kit ou devenir un package satellite
  (`evo_phx_kit_zitadel`) — le kit est cense etre agnostique du provider OIDC.
- `mix.exs` : aucune contrainte de version sur `phoenix`/`phoenix_live_view` a auditer avant
  publication eventuelle.
