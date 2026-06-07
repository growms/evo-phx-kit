defmodule EvoPhxKit do
  @moduledoc """
  Shared Phoenix toolkit for Evo projects.

  ## Public API

  Config helpers that read from `Application.get_env(:evo_phx_kit, key)`.
  """

  def user_provider do
    fetch_config!(:user_provider)
  end

  def session_provider do
    Application.get_env(:evo_phx_kit, :session_provider)
  end

  def gettext_module do
    fetch_config!(:gettext_module)
  end

  def default_locale do
    Application.get_env(:evo_phx_kit, :default_locale, "fr")
  end

  def locales do
    Application.get_env(:evo_phx_kit, :locales, ["fr", "en"])
  end

  def otp_app do
    fetch_config!(:otp_app)
  end

  def auth_logout_path do
    Application.get_env(:evo_phx_kit, :auth_logout_path, "/auth/logout")
  end

  def locale_cookie_name do
    Application.get_env(
      :evo_phx_kit,
      :locale_cookie_name,
      "#{otp_app()}_locale"
    )
  end

  def session_user_key do
    Application.get_env(:evo_phx_kit, :session_user_key, "user_id")
  end

  defp fetch_config!(key) do
    case Application.get_env(:evo_phx_kit, key) do
      nil ->
        raise ArgumentError,
              "Missing required config :evo_phx_kit, :#{key}. " <>
                "Add it to your config/config.exs."

      value ->
        value
    end
  end
end
