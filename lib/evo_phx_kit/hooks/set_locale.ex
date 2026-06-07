defmodule EvoPhxKit.Hooks.SetLocale do
  @moduledoc false
  import Phoenix.Component

  def on_mount(:set_locale, _params, session, socket) do
    cookie_name = EvoPhxKit.locale_cookie_name()
    default = EvoPhxKit.default_locale()
    locale = session[cookie_name] || default

    Gettext.put_locale(EvoPhxKit.gettext_module(), locale)
    {:cont, assign(socket, locale: locale)}
  end
end
