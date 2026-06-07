defmodule EvoPhxKit.Plugs.ContentSecurityPolicy do
  @moduledoc """
  Sets a strict Content-Security-Policy header on browser responses.

  Reads `:csp_extra_sources` from the host app's config to allow
  dev-time additions like `'unsafe-eval'` for LiveReload.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    put_resp_header(conn, "content-security-policy", policy())
  end

  defp policy do
    otp_app = EvoPhxKit.otp_app()
    extra = Application.get_env(otp_app, :csp_extra_sources)

    script_src =
      case extra do
        nil -> "script-src 'self' 'wasm-unsafe-eval'"
        "" -> "script-src 'self' 'wasm-unsafe-eval'"
        sources when is_binary(sources) -> "script-src 'self' 'wasm-unsafe-eval' #{sources}"
      end

    Enum.join(
      [
        "default-src 'self'",
        script_src,
        "style-src 'self' 'unsafe-inline'",
        "connect-src 'self' wss:",
        "img-src 'self' data:",
        "font-src 'self'",
        "frame-ancestors 'none'",
        "base-uri 'self'",
        "form-action 'self'"
      ],
      "; "
    )
  end
end
