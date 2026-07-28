---
status: todo
sprint: ""
epic: ""
model: sonnet
effort: medium
depends_on: [US-001]
blocked_reason: ""
blocked_solutions: []
---

> **DRAFT** — non passee par la boucle redteam. A valider (redteam-story + revue securite Opus)
> avant tout developpement.

# US-002 — Resolution fail-closed du `session_provider` (mode strict)

## Description

En tant qu'app hote pour laquelle la revocation de session est une exigence de securite, je veux
que le kit **refuse de fonctionner** si le `session_provider` n'est pas configure, afin qu'une
erreur de configuration ne desactive pas silencieusement la revocation.

## Contexte

Aujourd'hui, la resolution du provider est fail-**open**, et la logique est **dupliquee** dans les
deux gates :

```elixir
# lib/evo_phx_kit/plugs/require_auth.ex:35  ET  lib/evo_phx_kit/hooks/ensure_authenticated.ex:41
defp session_revoked?(user_id) do
  case EvoPhxKit.session_provider() do
    nil -> false          # <-- revocation silencieusement desactivee
    provider -> provider.session_revoked?(user_id)
  end
end
```

Une config oubliee, un `config/runtime.exs` mal ordonne ou une erreur de merge suffisent a laisser
passer toutes les sessions revoquees, **sans aucun signal** — ni log, ni erreur, ni test rouge.
`EvoPhxKit.session_provider/0` est d'ailleurs le seul helper de config qui n'utilise pas
`fetch_config!/1` (contrairement a `user_provider/0`, `gettext_module/0`, `otp_app/0`).

Le kit doit rester generique — une app hote sans besoin de revocation doit pouvoir s'en passer —
donc la strictesse est un **opt-in explicite**, pas un defaut impose.

## Perimetre

- Ajouter `EvoPhxKit.require_session_revocation?/0` →
  `Application.get_env(:evo_phx_kit, :require_session_revocation, false)`.
- Centraliser la resolution dans **une seule** fonction publique `EvoPhxKit.session_valid?/2`
  (supprime la duplication des deux gates) :
  - `session_provider() == nil` **et** `require_session_revocation?() == true` → raise
    `EvoPhxKit.SessionRevocationNotConfiguredError`
  - `session_provider() == nil` **et** flag a `false` → `true` (revocation desactivee, comportement
    generique conserve)
  - sinon → delegue a `provider.session_valid?(user_id, authenticated_at)`
- Nouvelle exception `EvoPhxKit.SessionRevocationNotConfiguredError`, message actionnable :
  quelle cle de config manque, quel behaviour implementer, comment desactiver le flag.
- Ajouter `EvoPhxKit.check_session_revocation_config!/0` — meme verification, sans user_id,
  appelable par l'app hote depuis son `Application.start/2` pour **echouer au boot** plutot qu'a la
  premiere requete authentifiee. Le kit n'a pas d'`Application` OTP a lui (`mix.exs` ne declare pas
  de `mod:`), il ne peut donc pas verifier au boot tout seul.
- `RequireAuth.call/2` et `EnsureAuthenticated.on_mount/4` appellent `EvoPhxKit.session_valid?/2`
  et suppriment leur copie privee.

## Criteres d'acceptation

- [ ] **AC1** — `EvoPhxKit.require_session_revocation?/0` ajoute, defaut `false` (todo)
- [ ] **AC2** — `EvoPhxKit.SessionRevocationNotConfiguredError` definie, message citant
      `:evo_phx_kit, :session_provider` et `:require_session_revocation` (todo)
- [ ] **AC3** — `EvoPhxKit.session_valid?/2` centralise la resolution ; les fonctions privees
      dupliquees de `RequireAuth` et `EnsureAuthenticated` sont supprimees (todo)
- [ ] **AC4** — `EvoPhxKit.check_session_revocation_config!/0` ajoute (todo)
- [ ] **AC5** — Test : provider `nil` + `require_session_revocation: true` → raise (test qui
      passe silencieusement aujourd'hui) (todo)
- [ ] **AC6** — Test : provider `nil` + flag `false` → acces autorise, aucune exception
      (genericite preservee pour les hotes sans revocation) (todo)
- [ ] **AC7** — Test : `check_session_revocation_config!/0` raise dans les memes conditions, sans
      requete ni session (todo)
- [ ] **AC8** — Test : parite plug/hook sur les 3 branches de resolution (todo)
- [ ] **AC9** — README/`@moduledoc` : la cle `require_session_revocation` est documentee comme
      recommandee pour toute app manipulant des sessions revocables (todo)

## Cas limites

- **E1 — Flag active mais provider configure sur un module inexistant.** `Application.get_env`
  retourne l'atome du module sans verifier son existence → `UndefinedFunctionError` au premier
  appel. `check_session_revocation_config!/0` doit-il aussi verifier
  `Code.ensure_loaded?/1` + `function_exported?/3` ? A arbitrer.
- **E2 — Config posee en `runtime.exs` apres le demarrage de l'`Application` de l'hote.** L'ordre
  est garanti par Elixir (`runtime.exs` s'evalue avant le demarrage des applications), mais a
  documenter explicitement pour eviter un faux diagnostic.
- **E3 — Environnement de test de l'hote.** Un test qui desactive temporairement le provider via
  `Application.put_env` doit restaurer en `on_exit` ; sinon la strictesse fait cascader les
  echecs. A signaler dans la doc de migration.

## Points a arbitrer (redteam)

1. Trois filets pour la meme condition si l'app hote ajoute en plus sa propre validation de boot
   (cas d'ECF) : defense en profondeur justifiee (dep externe hors perimetre SAST de l'hote) ou
   sur-ingenierie ?
2. Le defaut de `require_session_revocation` doit-il rester `false` (genericite) ou passer a `true`
   (fail-closed par defaut, les hotes sans revocation devant desactiver explicitement) ?
