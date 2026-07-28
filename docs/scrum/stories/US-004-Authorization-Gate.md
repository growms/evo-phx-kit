---
status: todo
sprint: ""
epic: ""
model: sonnet
effort: high
depends_on: [US-003]
blocked_reason: ""
blocked_solutions: []
---

> **DRAFT** — non passee par la boucle redteam. A valider (redteam-story + revue securite Opus)
> avant tout developpement.

# US-004 — Point d'extension d'autorisation applicative

## Description

En tant qu'app hote portant des regles d'acces propres (compte suspendu, role, allowlist
d'invitation, quota), je veux pouvoir brancher ces regles **dans le gate du kit**, afin de ne pas
avoir a reimplementer le gate entier des que ma politique depasse « authentifie ou non ».

## Contexte

C'est la story qui decide si le kit reste utilisable par une app reelle sur la duree.

Le gate du kit s'arrete a l'authentification : session presente, non revoquee, utilisateur
trouve → acces. Toute app hote finit par ajouter des conditions **apres** ce point. Sur ECF, le
gate reel comporte aujourd'hui une verification supplementaire dont le kit n'a aucune notion :

```elixir
# EcfWeb.Plugs.RequireAuth (ECF, main)
if Ecf.Accounts.admin_suspended?(user) do
  conn |> configure_session(drop: true) |> redirect(to: "/login") |> halt()
else
  assign(conn, :current_user, user)
end
```

Sans point d'extension, l'app hote n'a que deux issues, toutes deux mauvaises :
- reimplementer le gate complet dans son code — le kit ne sert plus a rien ;
- ou pousser sa politique produit dans le kit — le kit devient un fork de l'app hote, et les autres
  consommateurs heritent de regles qui ne les concernent pas.

Le kit doit donc porter le **squelette** du gate et **appeler** la politique de l'hote, sans jamais
la connaitre : ni « suspension », ni « role », ni « invitation » ne doivent apparaitre dans le
vocabulaire du kit.

## Perimetre

- Ajouter un callback **optionnel** `@callback authorize(user :: struct()) :: :ok | {:error,
  term()}` sur `EvoPhxKit.UserProvider`, declare dans `@optional_callbacks authorize: 1`.
- Les deux gates l'invoquent **apres** `fetch_user/1` reussi et **avant** d'assigner
  `:current_user` :
  - callback non exporte (`function_exported?/3` faux) → `:ok` implicite, comportement actuel
    inchange pour les hotes qui n'en ont pas besoin ;
  - `:ok` → acces ;
  - `{:error, _reason}` → refus : session droppee (plug) / `:halt` (hook) + redirection.
- Le kit **ne route pas** selon la `reason` : elle est ignoree pour la decision (tout `{:error, _}`
  refuse) et seulement mise a disposition de l'hote. Motif : le kit ne peut pas connaitre les
  raisons metier, et un routage par raison ferait rentrer la politique dans le kit par la fenetre.
- Point d'extension **du refus** : la redirection utilise le chemin unique defini en US-005. Si
  l'hote veut differencier la destination selon la raison (ECF : `/session/suspended` avec le
  motif), il le fait dans son propre controller de landing, pas dans le kit.

## Criteres d'acceptation

- [ ] **AC1** — `@callback authorize(user) :: :ok | {:error, term()}` declare et place dans
      `@optional_callbacks` (todo)
- [ ] **AC2** — `RequireAuth.call/2` invoque `authorize/1` si exporte, apres `fetch_user/1`, avant
      `assign(:current_user, ...)` (todo)
- [ ] **AC3** — `EnsureAuthenticated.on_mount/4` idem, avant les assigns (todo)
- [ ] **AC4** — Provider sans `authorize/1` → comportement strictement identique a avant la story
      (non-regression, verifiee par les tests existants inchanges) (todo)
- [ ] **AC5** — Test plug : `authorize/1` renvoyant `{:error, :whatever}` → session droppee +
      redirection + `halt`, `:current_user` **non** assigne (todo)
- [ ] **AC6** — Test hook : idem → `{:halt, ...}`, aucun assign (todo)
- [ ] **AC7** — Test : `authorize/1` renvoyant `:ok` → acces nominal (todo)
- [ ] **AC8** — Test : `authorize/1` est bien appele **apres** `fetch_user/1` (un provider dont
      `fetch_user/1` renvoie `:error` ne doit jamais voir `authorize/1` invoque) (todo)
- [ ] **AC9** — Test : parite plug/hook — meme provider, meme decision (todo)
- [ ] **AC10** — `@moduledoc` : documente que `authorize/1` porte la politique de l'hote et que le
      kit n'interprete jamais la `reason` (todo)

## Cas limites

- **E1 — `authorize/1` levant une exception.** Non rattrape par le kit : une politique qui crashe
  doit crasher (fail-closed bruyant) plutot que d'etre interpretee comme un refus silencieux ou,
  pire, comme un `:ok`. A confirmer en redteam.
- **E2 — Cout de `authorize/1`.** Il est appele a **chaque** requete authentifiee et a chaque
  mount. Une implementation touchant la base a chaque appel double la charge du gate. A documenter
  (recommandation : decider sur la struct deja chargee par `fetch_user/1`, sans requete
  supplementaire).
- **E3 — Autorisation changeant pendant une session LiveView longue.** Verifiee au mount
  uniquement, comme la revocation (US-001 E3). Ecart connu et assume.
- **E4 — Gate par route (role admin sur `/admin/*`).** Hors perimetre : `authorize/1` est global au
  gate authentifie. Une garde par scope reste un plug/hook de l'app hote, chaine apres celui du kit.

## Points a arbitrer (redteam)

1. Callback optionnel sur `UserProvider` vs behaviour dedie `EvoPhxKit.AuthorizationProvider`
   configure separement. Le behaviour dedie est plus explicite et testable isolement ; le callback
   optionnel evite une cle de config de plus et garde la politique la ou vit deja l'utilisateur.
2. `authorize(user)` vs `authorize(user, conn_or_socket)` — la seconde forme permettrait des regles
   dependant de la requete (IP, chemin), mais fait entrer un type Plug/LiveView dans un behaviour
   jusqu'ici pur, et rend la parite plug/hook plus difficile a garantir.
3. Faut-il exposer la `reason` a l'app hote (assign sur `conn`/`socket` avant redirection) pour
   qu'elle puisse afficher un message, ou est-ce le role du controller de landing de la recalculer ?
