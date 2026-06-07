defmodule EvoPhxKit.Plugs.RequireAuthTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  alias EvoPhxKit.Plugs.RequireAuth

  setup do
    EvoPhxKit.Test.Helpers.setup_config()
    :ok
  end

  defp call_plug(conn) do
    RequireAuth.call(conn, [])
  end

  test "redirects to /login when no user_id in session" do
    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(%{})
      |> call_plug()

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/login"]
  end

  test "assigns current_user when user_id is in session" do
    user = %{id: 1, email: "test@test.com", locale: "fr"}
    EvoPhxKit.Test.MockUserProvider.put_user(1, user)

    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(%{"user_id" => 1})
      |> call_plug()

    refute conn.halted
    assert conn.assigns[:current_user] == user
  end

  test "redirects when session is revoked (with SessionProvider)" do
    EvoPhxKit.Test.Helpers.setup_config(session_provider: EvoPhxKit.Test.MockSessionProvider)
    EvoPhxKit.Test.MockSessionProvider.revoke(1)

    user = %{id: 1, email: "test@test.com", locale: "fr"}
    EvoPhxKit.Test.MockUserProvider.put_user(1, user)

    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(%{"user_id" => 1})
      |> call_plug()

    assert conn.halted
    assert get_resp_header(conn, "location") == ["/login"]
  end

  test "does not check revocation when no SessionProvider is configured" do
    user = %{id: 1, email: "test@test.com", locale: "fr"}
    EvoPhxKit.Test.MockUserProvider.put_user(1, user)

    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(%{"user_id" => 1})
      |> call_plug()

    refute conn.halted
    assert conn.assigns[:current_user] == user
  end
end
