defmodule EvoPhxKit.Plugs.SetLocaleTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  alias EvoPhxKit.Plugs.SetLocale

  setup do
    EvoPhxKit.Test.Helpers.setup_config()
    :ok
  end

  defp call_plug(conn) do
    conn
    |> Plug.Conn.fetch_cookies()
    |> SetLocale.call([])
  end

  defp build_conn_with_session(session_data \\ %{}) do
    conn =
      conn(:get, "/")
      |> Plug.Test.init_test_session(session_data)

    conn
  end

  test "defaults to 'fr' when no locale source is available" do
    conn = build_conn_with_session() |> call_plug()
    assert conn.assigns[:locale] == "fr"
  end

  test "reads locale from session" do
    cookie_name = EvoPhxKit.locale_cookie_name()
    conn = build_conn_with_session(%{cookie_name => "en"}) |> call_plug()
    assert conn.assigns[:locale] == "en"
  end

  test "reads locale from cookie" do
    cookie_name = EvoPhxKit.locale_cookie_name()

    conn =
      conn(:get, "/")
      |> put_req_cookie(cookie_name, "en")
      |> Plug.Conn.fetch_cookies()
      |> Plug.Test.init_test_session(%{})
      |> SetLocale.call([])

    assert conn.assigns[:locale] == "en"
  end

  test "reads locale from Accept-Language header" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "en-US,en;q=0.9,fr;q=0.8")
      |> Plug.Test.init_test_session(%{})
      |> call_plug()

    assert conn.assigns[:locale] == "en"
  end

  test "ignores unsupported locale from Accept-Language" do
    conn =
      conn(:get, "/")
      |> put_req_header("accept-language", "de-DE,de;q=0.9")
      |> Plug.Test.init_test_session(%{})
      |> call_plug()

    assert conn.assigns[:locale] == "fr"
  end

  test "reads locale from user via UserProvider when current_user is assigned" do
    user = %{id: 1, email: "test@test.com", locale: "en"}
    EvoPhxKit.Test.MockUserProvider.put_user(1, user)

    conn =
      build_conn_with_session()
      |> Plug.Conn.assign(:current_user, user)
      |> call_plug()

    assert conn.assigns[:locale] == "en"
  end

  test "reads locale from UserProvider via session user_id" do
    user = %{id: 42, email: "test@test.com", locale: "en"}
    EvoPhxKit.Test.MockUserProvider.put_user(42, user)

    conn =
      build_conn_with_session(%{"user_id" => 42})
      |> call_plug()

    assert conn.assigns[:locale] == "en"
  end

  test "sets locale cookie on response" do
    conn = build_conn_with_session() |> call_plug()
    cookie_name = EvoPhxKit.locale_cookie_name()

    cookie = Enum.find(conn.resp_cookies, fn {name, _} -> name == cookie_name end)
    assert cookie != nil
    {_, %{value: value}} = cookie
    assert value == "fr"
  end

  test "sets locale in session" do
    conn = build_conn_with_session() |> call_plug()
    cookie_name = EvoPhxKit.locale_cookie_name()
    assert Plug.Conn.get_session(conn, cookie_name) == "fr"
  end
end
