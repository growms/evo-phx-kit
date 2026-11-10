# Fiche produit — `evo-phx-kit`

> Fiche d'orientation destinée à un agent ou un humain qui découvre ce dossier.
> Document non normatif : les autorités sont `CLAUDE.md`, `mix.exs`, le code de `lib/`
> et `docs/scrum/backlog.md`.

## 1. En une phrase

`evo-phx-kit` est une **bibliothèque Elixir/Phoenix privée** (paquet `:evo_phx_kit`, v0.1.0),
consommée en dépendance git par les applications Evo, qui mutualise un gate d'authentification
(plugs + hooks LiveView), des composants UI autonomes, la gestion de locale et un générateur
Igniter de fichiers de projet — **sans jamais porter de logique métier d'application hôte**.

Ce n'est ni un paquet Hex publié, ni un template de projet à cloner : le dépôt est un projet
`mix` bibliothèque (pas d'`application` supervisée, `mix.exs` ne déclare aucun `mod:`), doublé
d'une tâche `mix evo_phx_kit.setup` qui génère des fichiers chez le consommateur.

## 2. Le problème résolu

Trois applications Evo (ECF / `evo-code-fleet`, LLM Teams / `evo-llm-teams`, `evo-core-cloud`)
dupliquaient le même socle Phoenix : garde de session, sélection de langue, en-tête CSP,
composants de flash et de thème, `Dockerfile` et layout. Le kit centralise ce socle.

La règle fondatrice est énoncée dans `CLAUDE.md` : le kit porte le **contrat** (squelette du gate,
points d'extension, comportement fail-closed) ; l'application hôte porte la **politique** (qui a le
droit, et pourquoi). Concrètement : aucun schéma Ecto, aucun `Repo`, aucune migration, aucune règle
produit (rôles, quotas, suspension, RGPD). Tout ce dont le kit a besoin de l'hôte transite par un
behaviour (`EvoPhxKit.UserProvider`, `EvoPhxKit.SessionProvider`) configuré via
`config :evo_phx_kit`.

## 3. Structure du dossier

| Chemin | Contenu |
|---|---|
| `lib/evo_phx_kit.ex` | Façade de configuration (61 l.) : lecture de `Application.get_env(:evo_phx_kit, …)`, avec `fetch_config!/1` qui lève sur clé obligatoire manquante |
| `lib/evo_phx_kit/behaviours/` | `user_provider.ex` (3 callbacks), `session_provider.ex` (2 callbacks, optionnel) |
| `lib/evo_phx_kit/plugs/` | `require_auth.ex`, `set_locale.ex`, `require_dev_env.ex`, `content_security_policy.ex` |
| `lib/evo_phx_kit/hooks/` | `ensure_authenticated.ex`, `set_locale.ex` (`on_mount` LiveView) |
| `lib/evo_phx_kit/components.ex` | 170 l. — `epk_flash/1`, `flash_group/1`, `theme_toggle/1`, `login_page/1`, SVG inline, Gettext embarqué |
| `lib/evo_phx_kit/auth/zitadel.ex` | Helper de configuration runtime OIDC Zitadel (`ueberauth_oidcc`) |
| `lib/mix/tasks/evo_phx_kit.setup.ex` | 121 l. — tâche Igniter de génération (compilée seulement si Igniter est chargé) |
| `priv/templates/evo_phx_kit.setup/` | 7 gabarits EEx/statiques (468 l.) : layouts, `root.html.heex`, thèmes DaisyUI, `Dockerfile`, `docker-compose.dev.yml`, `DevLoginController` |
| `priv/gettext/` | Catalogues `fr` et `en` (53 lignes chacun) pour les chaînes du kit |
| `test/` | 11 fichiers de tests (759 l., 65 `test "…"`), plus 4 modules de support (mocks providers, gettext) |
| `docs/scrum/` | `backlog.md` + 6 user stories `US-001` à `US-006` (662 l.), toutes en `status: todo` |
| `_build/`, `deps/` | Artefacts locaux, ignorés par git (`.gitignore`) |

Absents et notables : pas de `config/`, pas de `CHANGELOG.md`, pas de `.github/` (aucune CI),
pas de `LICENSE`.

## 4. Concepts et modèle de données

Le kit ne possède aucune donnée persistée. Son modèle se réduit à deux contrats et un jeu de clés
de configuration.

**`EvoPhxKit.UserProvider`** (`lib/evo_phx_kit/behaviours/user_provider.ex`) :
`get_user!/1` (lève si absent), `get_user_by_email/1` (`nil` si absent), `get_user_locale/1`.

**`EvoPhxKit.SessionProvider`** (optionnel) : `session_revoked?/1`, `clear_revoked_session/1`.
S'il n'est pas configuré, la révocation de session est **silencieusement désactivée** dans les deux
gates (`case EvoPhxKit.session_provider() do nil -> false` dans `require_auth.ex` et
`ensure_authenticated.ex`).

**Clés de configuration** lues par `lib/evo_phx_kit.ex` — obligatoires : `:user_provider`,
`:gettext_module`, `:otp_app` ; facultatives avec valeur par défaut : `:session_provider` (`nil`),
`:default_locale` (`"fr"`), `:locales` (`["fr","en"]`), `:auth_logout_path` (`"/auth/logout"`),
`:locale_cookie_name` (`"<otp_app>_locale"`), `:session_user_key` (`"user_id"`).

**Séquence du gate** (identique en intention dans le plug et le hook) : lecture de
`session[session_user_key]` → si absente, redirection ; sinon vérification de révocation → sinon
`get_user!/1` puis assignation de `:current_user`. Le hook y ajoute la résolution de locale
(locale utilisateur, sinon cookie de session, sinon défaut).

## 5. Stack technique et dépendances externes

Elixir `~> 1.17`. Dépendances déclarées dans `mix.exs` : `plug ~> 1.16`,
`phoenix_live_view ~> 1.0`, `gettext >= 0.26.0`, `jason ~> 1.4`, `igniter ~> 0.5` (`optional: true`).

Points à connaître :

- **`phoenix` n'est pas déclaré**, alors que `lib/evo_phx_kit/plugs/require_auth.ex` fait
  `import Phoenix.Controller` : il n'est disponible que transitivement via `phoenix_live_view`
  (`mix.lock` le référence, `deps/phoenix` est présent).
- Aucune contrainte de version sur `phoenix` ni audit des bornes — le backlog le note lui-même
  (`docs/scrum/backlog.md`, section « Divers »).
- Les gabarits supposent **DaisyUI/Tailwind** (`priv/templates/evo_phx_kit.setup/themes.css.eex`,
  `daisyui-theme.js`) et **PostgreSQL 17** (`docker-compose.dev.yml.eex`).
- `EvoPhxKit.Auth.Zitadel` configure `:ueberauth_oidcc` sans en dépendre : couplage implicite à un
  provider OIDC, que le backlog propose d'extraire en paquet satellite.

## 6. Comment ça se lance / s'utilise

Le dépôt ne « se lance » pas : il se consomme. Développement local (`CLAUDE.md`) :
`mix deps.get`, `mix test`, `mix format`.

Côté application hôte, `CLAUDE.md` prescrit une dépendance **git taguée**, jamais `path:`
(ne résout pas en CI/Docker/prod) ni `branch:` (peut avancer sous le build) :

```elixir
{:evo_phx_kit, git: "https://github.com/growms/evo-phx-kit.git", tag: "v0.2.0"}
```

L'intégration réelle observable est celle de `evo-llm-teams` : `llm_teams/mix.exs` épingle
`{:evo_phx_kit, github: "growms/evo-phx-kit", ref: "6e1e6d4…"}` (commit exact, faute de tag), et
`llm_teams/config/config.exs` renseigne le bloc `config :evo_phx_kit` (`otp_app`, `user_provider`,
`gettext_module`, `session_user_key`, `default_locale`, `locales`, `auth_logout_path: "/login"`).

Le générateur s'invoque chez l'hôte : `mix evo_phx_kit.setup`, avec `--only layouts,themes,
dockerfile,dev_login` et `--no-dev-login`. Il écrit en `on_exists: :overwrite`.

## 7. État d'avancement

- Dépôt **actif mais jeune** : 12 commits, du 2026-06-07 au 2026-07-28, auteur unique (`blemoine`),
  branche `main` seule, arbre de travail propre, distant `git@github.com:growms/evo-phx-kit.git`.
- **Aucun tag** (`git tag` vide) alors que le mode de consommation documenté exige un tag.
- Code : 13 modules, **675 lignes** dans `lib/`, plus 468 lignes de gabarits.
- Tests : 11 fichiers, **759 lignes, 65 cas** — couverture nominale de chaque plug, hook,
  composant, du helper Zitadel et du générateur. Aucun `describe` : tests à plat.
  Le ratio test/code (≈ 1,12) est cohérent avec le TDD annoncé dans `CLAUDE.md`.
  Note : ni `mix` ni `elixir` ne sont disponibles dans l'environnement d'inspection ; la suite
  n'a **pas** été exécutée pour cette fiche.
- Fonctionnellement, la v0.1.0 est **livrée et consommée** par `evo-llm-teams`
  (stories `US-052`, `US-052a`–`US-052d`, toutes `status: done`).
- Le lot suivant — le « contrat d'authentification » — est **entièrement à faire** :
  6 stories `US-001` à `US-006`, toutes `status: todo`, toutes marquées **DRAFT non passée par la
  boucle redteam**, **52 critères d'acceptation, 0 coché**.

## 8. Restes à traiter

Le backlog (`docs/scrum/backlog.md`) est explicite : l'audit de la migration ECF a établi que le
gate v0.1.0 constitue une **régression sur 5 points** face au gate maison d'ECF.

| Story | Objet | Écart comblé |
|---|---|---|
| US-001 | `session_valid?/2` avec watermark `authenticated_at` | une session antérieure à une révocation redevient valide après déblocage |
| US-002 | Résolution fail-closed du `session_provider` | `session_provider` absent → révocation silencieusement désactivée |
| US-003 | `fetch_user/1` au lieu de `get_user!/1` | compte supprimé → 500 au lieu d'une redirection |
| US-004 | Callback optionnel `authorize/1` sur `UserProvider` | aucun point d'extension pour la politique d'accès de l'hôte |
| US-005 | Parité stricte plug ↔ hook (+ `auth_unauthenticated_path/0`, module `Auth.Gate`) | 3 destinations de redirection différentes, séquences dupliquées |
| US-006 | CI GitHub Actions, credo/sobelow, `CHANGELOG.md`, README réel, tag `v0.2.0` | aucun tag, aucune CI |

Ordre prescrit : US-001 → US-002, US-003 → US-004, puis US-005, puis US-006 (qui dépend des cinq
autres). Préalable impératif : boucle redteam **plus revue sécurité** avant tout développement.

Deux points ouverts en « Divers » : sortir `EvoPhxKit.Auth.Zitadel` en paquet satellite, et auditer
les bornes de version `phoenix`/`phoenix_live_view`.

## 9. Pièges

1. **Aucun tag n'existe.** Toute la documentation de consommation (`CLAUDE.md`, US-006) repose sur
   `tag: "v0.2.0"` ; ce tag n'est pas créé et la version de `mix.exs` est toujours `0.1.0`.
   `evo-llm-teams` contourne par un `ref:` de commit — solution correcte pour la reproductibilité,
   mais hors de la convention écrite.
2. **Le `README.md` est le squelette `mix new`** : « TODO: Add description », et il annonce une
   installation via Hex (`{:evo_phx_kit, "~> 0.1.0"}`) qui n'existe pas — le paquet n'est pas publié.
   Ne pas s'y fier : `CLAUDE.md` fait foi. US-006 prévoit sa réécriture.
3. **Divergence plug ↔ hook, non corrigée.** `RequireAuth` redirige en dur vers `"/login"` ; le hook
   `EnsureAuthenticated` redirige vers `auth_logout_path()` (défaut `/auth/logout`) quand la session
   est absente, mais vers `"/login"` en dur quand elle est révoquée. Un même utilisateur peut donc
   atterrir sur deux pages différentes selon le type de route. `evo-llm-teams` neutralise l'écart en
   posant `auth_logout_path: "/login"` dans sa config — détournement fonctionnel de la clé, que
   US-005 entend corriger par `auth_unauthenticated_path`.
4. **Révocation fail-open.** Oublier `:session_provider` dans la config désactive la vérification de
   révocation sans aucun avertissement (US-002).
5. **Compte supprimé → 500.** `get_user!/1` lève ; le gate ne rattrape pas (US-003).
6. **Le générateur écrase.** `mix evo_phx_kit.setup` utilise `on_exists: :overwrite` sur tous les
   fichiers générés, y compris `Dockerfile` et les layouts. À lancer sur un arbre git propre.
7. **`mix evo_phx_kit.setup` est invisible sans Igniter.** Le module entier est enveloppé dans
   `if Code.ensure_loaded?(Igniter.Mix.Task)` : chez un consommateur sans `igniter`, la tâche
   n'existe simplement pas (comportement voulu, commit `b9d3100`).
8. **Aucune CI, aucun SAST.** Le kit porte le code d'authentification de ses consommateurs, alors
   que les scanners des apps hôtes (sobelow, credo, gitleaks) n'analysent jamais les dépendances.
   C'est la motivation explicite d'US-006.
9. **Contradiction documentaire entre dépôts.** `evo-llm-teams/planning/stories/US-052-…` affirme
   « ECF a ete migre avec succes (1204 tests, 0 failures) », tandis que
   `evo-code-fleet/docs/scrum/stories/US-309-Evo-Phx-Kit-Migration-ECF.md` est `status: blocked`
   et que le backlog du kit qualifie la branche `wt1` d'**abandonnée** (archivée en
   `archive/wt1-evo-phx-kit`, non mergée). Se fier à US-309 et au backlog du kit, plus récents.
10. **Hygiène.** Aucun secret en clair détecté dans `lib/`, `priv/` ou `test/`. Le seul
    identifiant présent est un mot de passe PostgreSQL **de développement** dérivé du nom de
    l'application dans `priv/templates/evo_phx_kit.setup/docker-compose.dev.yml.eex` (gabarit,
    non destiné à la production). Aucune donnée personnelle repérée. Aucun fichier de plus de 2 Mo
    hors `.git` ; `_build/` et `deps/` sont présents localement mais correctement ignorés.

## 10. Où regarder ensuite

| Sujet | Chemin (sur la machine : `~/mnt/perso/…`) |
|---|---|
| Règle de généricité, conventions, mode de consommation | `evo-phx-kit/CLAUDE.md` |
| Clés de configuration et valeurs par défaut | `evo-phx-kit/lib/evo_phx_kit.ex` |
| Contrats à implémenter par l'hôte | `evo-phx-kit/lib/evo_phx_kit/behaviours/` |
| Gate HTTP / gate LiveView (et leur divergence) | `evo-phx-kit/lib/evo_phx_kit/plugs/require_auth.ex`, `evo-phx-kit/lib/evo_phx_kit/hooks/ensure_authenticated.ex` |
| Composants UI et leurs `attr` | `evo-phx-kit/lib/evo_phx_kit/components.ex` |
| Générateur et gabarits | `evo-phx-kit/lib/mix/tasks/evo_phx_kit.setup.ex`, `evo-phx-kit/priv/templates/evo_phx_kit.setup/` |
| Feuille de route du contrat d'authentification | `evo-phx-kit/docs/scrum/backlog.md`, `evo-phx-kit/docs/scrum/stories/` |
| Exemple d'intégration réelle | `evo-llm-teams/llm_teams/mix.exs`, `evo-llm-teams/llm_teams/config/config.exs` |
| Migration consommateur (faite) | `evo-llm-teams/planning/stories/US-052-Migration-evo-phx-kit.md` et `US-052a`–`US-052d` |
| Migration consommateur (bloquée, raisons détaillées) | `evo-code-fleet/docs/scrum/stories/US-309-Evo-Phx-Kit-Migration-ECF.md` |
