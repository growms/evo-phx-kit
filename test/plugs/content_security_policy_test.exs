defmodule EvoPhxKit.Plugs.ContentSecurityPolicyTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  alias EvoPhxKit.Plugs.ContentSecurityPolicy

  setup do
    EvoPhxKit.Test.Helpers.setup_config()
    Application.delete_env(:evo_phx_kit, :csp_extra_sources)
    :ok
  end

  test "sets CSP header with default policy" do
    conn =
      conn(:get, "/")
      |> ContentSecurityPolicy.call([])

    [csp] = get_resp_header(conn, "content-security-policy")
    assert csp =~ "default-src 'self'"
    assert csp =~ "script-src 'self' 'wasm-unsafe-eval'"
    assert csp =~ "style-src 'self' 'unsafe-inline'"
    assert csp =~ "frame-ancestors 'none'"
  end

  test "appends extra sources to script-src when configured" do
    Application.put_env(:evo_phx_kit, :csp_extra_sources, "'unsafe-eval'")

    conn =
      conn(:get, "/")
      |> ContentSecurityPolicy.call([])

    [csp] = get_resp_header(conn, "content-security-policy")
    assert csp =~ "script-src 'self' 'wasm-unsafe-eval' 'unsafe-eval'"
  end

  test "ignores empty string extra sources" do
    Application.put_env(:evo_phx_kit, :csp_extra_sources, "")

    conn =
      conn(:get, "/")
      |> ContentSecurityPolicy.call([])

    [csp] = get_resp_header(conn, "content-security-policy")
    assert csp =~ "script-src 'self' 'wasm-unsafe-eval'"
    refute csp =~ "script-src 'self' 'wasm-unsafe-eval' "
  end
end
