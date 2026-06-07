defmodule EvoPhxKit.Test.Helpers do
  def setup_config(opts \\ []) do
    Application.put_env(:evo_phx_kit, :otp_app, :evo_phx_kit)
    Application.put_env(:evo_phx_kit, :user_provider, EvoPhxKit.Test.MockUserProvider)
    Application.put_env(:evo_phx_kit, :gettext_module, EvoPhxKit.Test.MockGettext)
    Application.put_env(:evo_phx_kit, :default_locale, "fr")
    Application.put_env(:evo_phx_kit, :locales, ["fr", "en"])
    Application.put_env(:evo_phx_kit, :auth_logout_path, "/auth/logout")
    Application.put_env(:evo_phx_kit, :session_user_key, "user_id")

    if opts[:session_provider] do
      Application.put_env(:evo_phx_kit, :session_provider, opts[:session_provider])
    else
      Application.delete_env(:evo_phx_kit, :session_provider)
    end

    EvoPhxKit.Test.MockUserProvider.reset()
    EvoPhxKit.Test.MockSessionProvider.reset()
  end
end
