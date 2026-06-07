defmodule EvoPhxKit.Hooks.EnsureAuthenticatedTest do
  use ExUnit.Case

  alias EvoPhxKit.Hooks.EnsureAuthenticated

  setup do
    EvoPhxKit.Test.Helpers.setup_config()
    :ok
  end

  defp build_socket do
    %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}},
      redirected: nil
    }
  end

  test "halts and redirects when no user_id in session" do
    {:halt, socket} =
      EnsureAuthenticated.on_mount(:ensure_authenticated, %{}, %{}, build_socket())

    assert socket.redirected
  end

  test "assigns current_user when user_id is in session" do
    user = %{id: 1, email: "test@test.com", locale: "en"}
    EvoPhxKit.Test.MockUserProvider.put_user(1, user)

    {:cont, socket} =
      EnsureAuthenticated.on_mount(
        :ensure_authenticated,
        %{},
        %{"user_id" => 1},
        build_socket()
      )

    assert socket.assigns[:current_user] == user
    assert socket.assigns[:locale] == "en"
  end

  test "uses session locale when user has no locale" do
    user = %{id: 1, email: "test@test.com", locale: nil}
    EvoPhxKit.Test.MockUserProvider.put_user(1, user)
    cookie_name = EvoPhxKit.locale_cookie_name()

    {:cont, socket} =
      EnsureAuthenticated.on_mount(
        :ensure_authenticated,
        %{},
        %{"user_id" => 1, cookie_name => "en"},
        build_socket()
      )

    assert socket.assigns[:locale] == "en"
  end

  test "halts when session is revoked (with SessionProvider)" do
    EvoPhxKit.Test.Helpers.setup_config(session_provider: EvoPhxKit.Test.MockSessionProvider)
    EvoPhxKit.Test.MockSessionProvider.revoke(1)

    user = %{id: 1, email: "test@test.com", locale: "fr"}
    EvoPhxKit.Test.MockUserProvider.put_user(1, user)

    {:halt, socket} =
      EnsureAuthenticated.on_mount(
        :ensure_authenticated,
        %{},
        %{"user_id" => 1},
        build_socket()
      )

    assert socket.redirected
  end

  test "proceeds when no SessionProvider is configured" do
    user = %{id: 1, email: "test@test.com", locale: "fr"}
    EvoPhxKit.Test.MockUserProvider.put_user(1, user)

    {:cont, socket} =
      EnsureAuthenticated.on_mount(
        :ensure_authenticated,
        %{},
        %{"user_id" => 1},
        build_socket()
      )

    assert socket.assigns[:current_user] == user
  end
end
