defmodule EvoPhxKit.Auth.Zitadel do
  @moduledoc """
  Runtime config helper for Zitadel OIDC.

  Call `runtime_config!/1` from your `runtime.exs` to configure
  `:ueberauth_oidcc` issuers from the `ZITADEL_ISSUER` env var.
  """

  def runtime_config!(otp_app) when is_atom(otp_app) do
    if auth_provider(otp_app) == :zitadel do
      case System.get_env("ZITADEL_ISSUER") do
        nil ->
          :ok

        issuer ->
          Application.put_env(:ueberauth_oidcc, :issuers, [
            %{name: :zitadel_issuer, issuer: issuer}
          ])
      end
    end

    :ok
  end

  defp auth_provider(otp_app) do
    Application.get_env(:evo_phx_kit, :auth_provider) ||
      Application.get_env(otp_app, :auth_provider)
  end
end
