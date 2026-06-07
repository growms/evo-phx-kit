defmodule EvoPhxKit.Hooks.SetLocaleTest do
  use ExUnit.Case

  alias EvoPhxKit.Hooks.SetLocale

  setup do
    EvoPhxKit.Test.Helpers.setup_config()
    :ok
  end

  defp build_socket do
    %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}}
    }
  end

  test "sets locale from session" do
    cookie_name = EvoPhxKit.locale_cookie_name()
    session = %{cookie_name => "en"}
    {:cont, socket} = SetLocale.on_mount(:set_locale, %{}, session, build_socket())

    assert socket.assigns[:locale] == "en"
  end

  test "defaults to configured default_locale when session has no locale" do
    {:cont, socket} = SetLocale.on_mount(:set_locale, %{}, %{}, build_socket())
    assert socket.assigns[:locale] == "fr"
  end
end
