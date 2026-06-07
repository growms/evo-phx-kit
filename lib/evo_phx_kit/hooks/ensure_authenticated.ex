defmodule EvoPhxKit.Hooks.EnsureAuthenticated do
  @moduledoc false
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:ensure_authenticated, _params, session, socket) do
    user_key = EvoPhxKit.session_user_key()

    case session[user_key] do
      nil ->
        {:halt, redirect(socket, to: EvoPhxKit.auth_logout_path())}

      user_id ->
        if session_revoked?(user_id) do
          {:halt, redirect(socket, to: "/login")}
        else
          user_provider = EvoPhxKit.user_provider()
          user = user_provider.get_user!(user_id)
          cookie_name = EvoPhxKit.locale_cookie_name()
          default = EvoPhxKit.default_locale()

          locale =
            case user_provider.get_user_locale(user) do
              l when is_binary(l) and l != "" -> l
              _ -> session[cookie_name] || default
            end

          Gettext.put_locale(EvoPhxKit.gettext_module(), locale)

          {:cont,
           assign(socket,
             current_user: user,
             locale: locale
           )}
        end
    end
  end

  defp session_revoked?(user_id) do
    case EvoPhxKit.session_provider() do
      nil -> false
      provider -> provider.session_revoked?(user_id)
    end
  end
end
