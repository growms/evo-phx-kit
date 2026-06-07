defmodule EvoPhxKit.Auth.ZitadelTest do
  use ExUnit.Case

  alias EvoPhxKit.Auth.Zitadel

  setup do
    EvoPhxKit.Test.Helpers.setup_config()
    Application.put_env(:evo_phx_kit, :auth_provider, :zitadel)
    System.delete_env("ZITADEL_ISSUER")
    Application.delete_env(:ueberauth_oidcc, :issuers)
    :ok
  end

  test "configures ueberauth_oidcc when ZITADEL_ISSUER is set" do
    System.put_env("ZITADEL_ISSUER", "https://auth.example.com")
    assert Zitadel.runtime_config!(:evo_phx_kit) == :ok

    issuers = Application.get_env(:ueberauth_oidcc, :issuers)
    assert [%{name: :zitadel_issuer, issuer: "https://auth.example.com"}] = issuers
  end

  test "does nothing when ZITADEL_ISSUER is not set" do
    assert Zitadel.runtime_config!(:evo_phx_kit) == :ok
    assert Application.get_env(:ueberauth_oidcc, :issuers) == nil
  end

  test "does nothing when auth_provider is not :zitadel" do
    Application.put_env(:evo_phx_kit, :auth_provider, :none)
    System.put_env("ZITADEL_ISSUER", "https://auth.example.com")

    assert Zitadel.runtime_config!(:evo_phx_kit) == :ok
    assert Application.get_env(:ueberauth_oidcc, :issuers) == nil
  end
end
