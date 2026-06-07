defmodule EvoPhxKit.Plugs.RequireDevEnv do
  @moduledoc """
  Runtime guard that rejects requests when the host app's :environment is :prod.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    otp_app = EvoPhxKit.otp_app()

    if Application.get_env(otp_app, :environment) == :prod do
      conn
      |> send_resp(404, "Not Found")
      |> halt()
    else
      conn
    end
  end
end
