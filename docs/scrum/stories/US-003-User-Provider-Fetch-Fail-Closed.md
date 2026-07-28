---
status: todo
sprint: ""
epic: ""
model: sonnet
effort: medium
depends_on: []
blocked_reason: ""
blocked_solutions: []
---

> **DRAFT** — non passee par la boucle redteam. A valider (redteam-story + revue securite Opus)
> avant tout developpement.

# US-003 — `UserProvider.fetch_user/1` : utilisateur introuvable en fail-closed

## Description

En tant qu'app hote autorisant la suppression de compte, je veux qu'une session referencant un
utilisateur qui n'existe plus soit **rejetee proprement** (session videe, redirection) plutot que
de faire crasher la requete, afin qu'une consequence routiniere d'une suppression ne devienne pas
une erreur 500.

## Contexte

Les deux gates du kit appellent aujourd'hui `get_user!/1` sans filet :

```elixir
# lib/evo_phx_kit/plugs/require_auth.ex:29
assign(conn, :current_user, user_provider.get_user!(user_id))

# lib/evo_phx_kit/hooks/ensure_authenticated.ex:19
user = user_provider.get_user!(user_id)
```

Le behaviour impose meme la semantique levante : `@callback get_user!(id :: term()) :: struct()`.

Or, des qu'une app hote supprime reellement une ligne `users` (droit a l'effacement RGPD,
suppression de compte), **tout autre onglet ou session encore ouvert sous cette identite** frappe
ce chemin. C'est un evenement attendu et systematique, pas un cas exotique — et il produit un 500.

ECF a du contourner le probleme dans son propre code, aux deux endroits, avec le meme motif :

```elixir
defp safe_get_user(user_id) do
  Ecf.Accounts.get_user!(user_id)
rescue
  Ecto.NoResultsError -> nil
end
```

Ce `rescue` ne peut pas remonter tel quel dans le kit : `Ecto.NoResultsError` est une exception
Ecto, et le kit ne depend pas d'Ecto (et ne doit pas en dependre). La bonne frontiere est un
contrat de behaviour retournant un resultat, pas une exception.

## Perimetre

**Behaviour `EvoPhxKit.UserProvider`**

- Ajouter `@callback fetch_user(id :: term()) :: {:ok, struct()} | :error`.
- `get_user!/1` est **retire** du behaviour (le kit ne l'appelle plus). L'app hote garde bien sur
  sa propre fonction levante pour ses besoins internes ; c'est le **contrat avec le kit** qui
  change, pas le code de l'hote.
- `get_user_by_email/1` et `get_user_locale/1` restent inchanges.

**Gates**

- `RequireAuth.call/2` : `:error` → vider la session (`configure_session(drop: true)`), rediriger,
  `halt`. Le drop est indispensable : sans lui, le cookie pointant vers un utilisateur supprime
  reste dans le navigateur et rejoue la meme redirection a chaque requete.
- `EnsureAuthenticated.on_mount/4` : `:error` → `{:halt, redirect(...)}`. Un hook LiveView ne peut
  pas modifier la session ; la purge effective est faite par le plug HTTP au prochain hit sur une
  route protegee — comportement a documenter explicitement.

## Criteres d'acceptation

- [ ] **AC1** — `EvoPhxKit.UserProvider` declare `@callback fetch_user(id) :: {:ok, struct()} |
      :error` ; `get_user!/1` retire du behaviour (todo)
- [ ] **AC2** — `RequireAuth.call/2` utilise `fetch_user/1` ; sur `:error` → session droppee +
      redirection + `halt` (todo)
- [ ] **AC3** — `EnsureAuthenticated.on_mount/4` utilise `fetch_user/1` ; sur `:error` → `:halt` +
      redirection (todo)
- [ ] **AC4** — Test plug : provider retournant `:error` → reponse de redirection, `halted?` vrai,
      **aucune** exception levee, session videe (todo)
- [ ] **AC5** — Test hook : provider retournant `:error` → `{:halt, ...}`, aucune exception (todo)
- [ ] **AC6** — Test : le chemin nominal `{:ok, user}` assigne bien `:current_user` des deux cotes
      (non-regression) (todo)
- [ ] **AC7** — `mock_user_provider.ex` mis a jour ; `mix test` vert (todo)
- [ ] **AC8** — `@moduledoc` du behaviour : documente que l'implementation ne doit **jamais** lever
      sur « non trouve » et donne le motif `rescue Ecto.NoResultsError -> :error` comme exemple
      pour une hote Ecto (todo)

## Cas limites

- **E1 — Provider levant malgre le contrat.** Le kit ne rattrape pas (il ne connait pas les types
  d'exception de l'hote) : le contrat est documentaire, garanti par les tests de l'hote. A
  challenger — faut-il un `rescue` generique dans le gate, au risque de masquer une vraie panne
  (timeout DB) en redirection silencieuse vers le login ?
- **E2 — `user_id` de session de type inattendu** (chaine vs entier apres un changement de schema).
  Le provider recoit la valeur brute ; a lui de la normaliser. Le kit ne caste rien.
- **E3 — Suppression concurrente pendant la requete.** `fetch_user/1` peut renvoyer `{:ok, user}`
  sur une ligne supprimee juste apres ; l'acces est alors autorise pour cette requete. Fenetre
  acceptee, identique a l'existant.

## Points a arbitrer (redteam)

1. `{:ok, user} | :error` vs `{:ok, user} | {:error, reason}` — la raison est-elle utile au kit
   (elle pourrait piloter des redirections differenciees) ou est-ce du sur-contrat ?
2. Retirer `get_user!/1` du behaviour est un breaking change pour l'implementation de l'hote ;
   alternative : garder les deux callbacks avec `@optional_callbacks` et preferer `fetch_user/1`
   quand il est exporte. Plus doux, mais reintroduit un chemin implicite.
