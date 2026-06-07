defmodule EvoPhxKit.Plugs.RequireDevEnvTest do
  use ExUnit.Case
  import Plug.Test

  alias EvoPhxKit.Plugs.RequireDevEnv

  setup do
    EvoPhxKit.Test.Helpers.setup_config()
    :ok
  end

  test "allows request when environment is not :prod" do
    Application.put_env(:evo_phx_kit, :environment, :dev)

    conn =
      conn(:get, "/dev/dashboard")
      |> RequireDevEnv.call([])

    refute conn.halted
  end

  test "returns 404 when environment is :prod" do
    Application.put_env(:evo_phx_kit, :environment, :prod)

    conn =
      conn(:get, "/dev/dashboard")
      |> RequireDevEnv.call([])

    assert conn.halted
    assert conn.status == 404
  end

  test "allows request when environment is nil" do
    Application.delete_env(:evo_phx_kit, :environment)

    conn =
      conn(:get, "/dev/dashboard")
      |> RequireDevEnv.call([])

    refute conn.halted
  end
end
