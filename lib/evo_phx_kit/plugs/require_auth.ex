defmodule EvoPhxKit.Plugs.RequireAuth do
  @moduledoc """
  Plug that ensures the user is authenticated via session.
  Redirects to the configured logout path if not authenticated or if session is revoked.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    user_key = EvoPhxKit.session_user_key()

    case get_session(conn, user_key) do
      nil ->
        conn
        |> redirect(to: "/login")
        |> halt()

      user_id ->
        if session_revoked?(user_id) do
          conn
          |> configure_session(drop: true)
          |> redirect(to: "/login")
          |> halt()
        else
          user_provider = EvoPhxKit.user_provider()
          assign(conn, :current_user, user_provider.get_user!(user_id))
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
