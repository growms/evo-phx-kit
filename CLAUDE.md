# evo-phx-kit — instructions projet

Toolkit Phoenix partage entre les projets Evo (ECF, LLM Teams, evo-core-cloud).
Le kit fournit **des briques generiques** : plugs, hooks LiveView, behaviours, composants UI
self-contained, helpers de config, et un generator igniter.

## Regle de genericite (IMPORTANT)

Le kit ne contient **jamais de logique metier d'une app hote**. Concretement :

- Pas de schema Ecto, pas de `Repo`, pas de migration — le kit ne connait pas la base de l'hote
- Pas de regle produit (allowlist d'acces, roles, quotas, suspension, invitation, suppression de
  compte, RGPD) — ces regles restent dans l'app hote
- Tout ce dont le kit a besoin de l'hote passe par un **behaviour** (`EvoPhxKit.UserProvider`,
  `EvoPhxKit.SessionProvider`, ...) configure via `config :evo_phx_kit`

Le kit porte le **contrat** (le squelette du gate d'authentification, ses points d'extension et
son comportement fail-closed). L'app hote porte la **politique** (qui a le droit, et pourquoi).

Test a appliquer avant d'ajouter quoi que ce soit : *« est-ce que les 3 apps hotes voudraient ce
comportement a l'identique ? »* Si non, c'est un point d'extension a exposer, pas du code a
integrer.

## Structure du dossier docs/

```
docs/
└── scrum/          — Artefacts SCRUM (meme convention que ECF)
    ├── stories/    — User stories (format: US-XXX-<Sujet>.md)
    └── backlog.md  — Stories non planifiees
```

**Numerotation** : `US-001`, `US-002`, ... — namespace **local a ce repo**, independant de la
numerotation d'ECF (US-4xx). Une story du kit ne partage jamais son numero avec une story ECF ;
les references croisees se font en nommant le repo (`evo-phx-kit US-001`, `ECF US-309`).

Le processus SCRUM (etats, boucle de review redteam, decision log) est celui decrit dans le
`CLAUDE-SCRUM.md` d'ECF. Toute story doit passer la boucle redteam avant son developpement.

## Developpement

```bash
mix deps.get
mix test
mix format
```

Toute story est developpee en TDD. Le kit porte du code d'authentification : les changements de
comportement du gate (`RequireAuth`, `EnsureAuthenticated`, behaviours) sont **securite-critiques**
et exigent une revue securite dediee avant tag.

## Versionnement et consommation

Les apps hotes consomment le kit via une **dependance git taguee** :

```elixir
{:evo_phx_kit, git: "https://github.com/growms/evo-phx-kit.git", tag: "v0.2.0"}
```

Jamais `path:` (ne resout pas en CI/Docker/prod), jamais `branch:` (peut avancer sous le build).
Tout changement de contrat (signature de behaviour, comportement du gate) impose un **bump de
version mineure** et une note de migration dans le CHANGELOG.
