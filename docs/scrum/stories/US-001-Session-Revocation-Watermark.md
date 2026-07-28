---
status: todo
sprint: ""
epic: ""
model: sonnet
effort: high
depends_on: []
blocked_reason: ""
blocked_solutions: []
---

> **DRAFT** — non passee par la boucle redteam. A valider (redteam-story + revue securite Opus)
> avant tout developpement.

# US-001 — SessionProvider : revocation avec watermark `authenticated_at`

## Description

En tant qu'app hote consommant `evo-phx-kit`, je veux que le gate d'authentification du kit puisse
rejeter une session **emise avant** un evenement de revocation, afin qu'un cookie de session vole
ou laisse ouvert reste refuse meme apres qu'un deblocage legitime a leve le drapeau de revocation.

## Contexte

Le contrat actuel est un booleen par utilisateur :

```elixir
# lib/evo_phx_kit/behaviours/session_provider.ex
@callback session_revoked?(user_id :: term()) :: boolean()
```

Il ne permet d'exprimer que « cet utilisateur est actuellement revoque ». Des qu'un deblocage
legitime remet le drapeau a `false`, **toutes** les sessions anterieures redeviennent valides,
y compris celle a l'origine de la revocation.

ECF a resolu ce probleme dans son propre code (`EcfWeb.RevokedSessions.session_valid?/2`) en
comparant l'instant d'authentification de la session a une **ligne d'eau (watermark)** posee au
moment de la revocation :

```elixir
def session_valid?(user_id, authenticated_at) do
  case fetch(user_id) do
    {true, _watermark_at} -> false                                    # revoque maintenant
    {false, nil} -> true                                              # jamais revoque
    {false, watermark_at} -> authenticated_after?(authenticated_at, watermark_at)
  end
end
```

Tant que le kit n'expose pas ce contrat, une app hote qui migre dessus **perd** cette garantie
sans que rien ne le signale. C'est le principal ecart bloquant identifie entre le kit et l'etat
de l'art d'ECF.

## Perimetre

**Behaviour `EvoPhxKit.SessionProvider`**

- `session_revoked?/1` est **remplace** par `session_valid?(user_id, authenticated_at)`
  retournant `boolean()` (`true` = la session peut continuer). Le sens est inverse par rapport a
  `session_revoked?/1` : nommer la garantie positive evite les doubles negations dans les gates.
- `authenticated_at` est passe **tel qu'il est lu en session**, sans interpretation par le kit
  (le kit ne sait pas si c'est un `DateTime`, un ISO8601 ou un timestamp unix — seul le provider
  de l'hote le sait).
- `clear_revoked_session/1` reste inchange.
- Breaking change assume : bump de version mineure (voir US-006). Aucune app en production ne
  consomme le kit a ce jour.

**Lecture de `authenticated_at`**

- Ajouter `EvoPhxKit.session_authenticated_at_key/0` →
  `Application.get_env(:evo_phx_kit, :session_authenticated_at_key, "authenticated_at")`.
- `RequireAuth` (plug) et `EnsureAuthenticated` (hook) lisent cette cle en session et la passent
  a `session_valid?/2`. Rappel Plug : `put_session(conn, :authenticated_at, ...)` cote HTTP est
  relu `session["authenticated_at"]` cote LiveView (normalisation atome → chaine par Plug,
  `deps/plug/lib/plug/conn.ex`), donc une cle chaine unique suffit des deux cotes.
- Une session sans `authenticated_at` (cle absente) transmet `nil` au provider — c'est au
  provider de decider (ECF : `authenticated_after?(nil, watermark)` → `false`, fail-closed).

## Criteres d'acceptation

- [ ] **AC1** — `EvoPhxKit.SessionProvider` declare `@callback session_valid?(user_id :: term(),
      authenticated_at :: term()) :: boolean()` ; `session_revoked?/1` est retire du behaviour (todo)
- [ ] **AC2** — `EvoPhxKit.session_authenticated_at_key/0` ajoute, defaut `"authenticated_at"` (todo)
- [ ] **AC3** — `RequireAuth.call/2` lit `authenticated_at` en session et rejette la requete si
      `session_valid?/2` retourne `false` (todo)
- [ ] **AC4** — `EnsureAuthenticated.on_mount/4` fait de meme et `:halt` (todo)
- [ ] **AC5** — Test : session dont `authenticated_at` precede le watermark → rejetee **alors meme
      que** le provider ne signale plus de revocation active (le test qui echoue avec le contrat
      booleen actuel) (todo)
- [ ] **AC6** — Test : session posterieure au watermark → acceptee (todo)
- [ ] **AC7** — Test : `authenticated_at` absent de la session → `nil` transmis au provider, pas de
      crash du kit (todo)
- [ ] **AC8** — Test : parite plug/hook — le meme couple (session, provider) produit la meme
      decision d'acces des deux cotes (todo)
- [ ] **AC9** — `mock_session_provider.ex` mis a jour ; `mix test` vert (todo)

## Cas limites

- **E1 — Provider implementant encore l'ancien `session_revoked?/1`.** Le kit ne fournit pas de
  fallback silencieux : un provider incomplet doit produire une erreur de compilation
  (`@behaviour` non satisfait) ou une `UndefinedFunctionError` explicite au premier appel. Pas de
  degradation en fail-open.
- **E2 — Type de `authenticated_at` divergent entre HTTP et LiveView.** Hors perimetre du kit :
  c'est l'app hote qui ecrit la valeur en session et son provider qui la lit. A documenter dans le
  `@moduledoc` du behaviour.
- **E3 — Revocation survenant apres le mount LiveView.** Non couvert (le gate ne s'execute qu'au
  mount). Ecart connu, identique a l'existant ECF — a traiter, si besoin, par un mecanisme
  d'invalidation live cote app hote (PubSub), hors kit.

## Points a arbitrer (redteam)

1. `session_valid?/2` (positif) vs `session_revoked?/2` (negatif, symetrique de l'existant) — le
   choix du sens positif est-il le bon, sachant qu'un provider mal implemente qui retourne une
   valeur falsy par defaut echoue alors en fail-closed ?
2. Faut-il que le kit normalise `authenticated_at` (ex. exiger un `DateTime`) plutot que de le
   passer opaque ? Opaque = generique mais deporte toute la rigueur sur l'hote.
