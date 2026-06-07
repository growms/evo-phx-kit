defmodule EvoPhxKitTest do
  use ExUnit.Case

  setup do
    EvoPhxKit.Test.Helpers.setup_config()
    :ok
  end

  test "user_provider/0 returns configured module" do
    assert EvoPhxKit.user_provider() == EvoPhxKit.Test.MockUserProvider
  end

  test "session_provider/0 returns nil when not configured" do
    assert EvoPhxKit.session_provider() == nil
  end

  test "session_provider/0 returns configured module" do
    Application.put_env(:evo_phx_kit, :session_provider, EvoPhxKit.Test.MockSessionProvider)
    assert EvoPhxKit.session_provider() == EvoPhxKit.Test.MockSessionProvider
  end

  test "gettext_module/0 returns configured module" do
    assert EvoPhxKit.gettext_module() == EvoPhxKit.Test.MockGettext
  end

  test "locales/0 returns configured locales" do
    assert EvoPhxKit.locales() == ["fr", "en"]
  end

  test "default_locale/0 returns configured default" do
    assert EvoPhxKit.default_locale() == "fr"
  end

  test "otp_app/0 returns configured app" do
    assert EvoPhxKit.otp_app() == :evo_phx_kit
  end

  test "auth_logout_path/0 returns configured path" do
    assert EvoPhxKit.auth_logout_path() == "/auth/logout"
  end

  test "locale_cookie_name/0 defaults to otp_app + _locale" do
    Application.delete_env(:evo_phx_kit, :locale_cookie_name)
    assert EvoPhxKit.locale_cookie_name() == "evo_phx_kit_locale"
  end

  test "locale_cookie_name/0 returns custom name when configured" do
    Application.put_env(:evo_phx_kit, :locale_cookie_name, "my_locale")
    assert EvoPhxKit.locale_cookie_name() == "my_locale"
  end

  test "session_user_key/0 returns configured key" do
    assert EvoPhxKit.session_user_key() == "user_id"
  end

  test "fetch_config!/1 raises when key is missing" do
    Application.delete_env(:evo_phx_kit, :user_provider)

    assert_raise ArgumentError, ~r/Missing required config/, fn ->
      EvoPhxKit.user_provider()
    end
  end
end
