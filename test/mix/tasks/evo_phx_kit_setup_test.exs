defmodule Mix.Tasks.EvoPhxKit.SetupTest do
  use ExUnit.Case

  @template_dir Path.join(:code.priv_dir(:evo_phx_kit), "templates/evo_phx_kit.setup")

  test "all template files exist" do
    expected = [
      "layouts.ex.eex",
      "root.html.heex.eex",
      "dev_login_controller.ex.eex",
      "themes.css.eex",
      "daisyui-theme.js",
      "dockerfile.eex",
      "docker-compose.dev.yml.eex"
    ]

    for file <- expected do
      path = Path.join(@template_dir, file)
      assert File.exists?(path), "Template #{file} not found at #{path}"
    end
  end

  test "layouts.ex.eex renders with bindings" do
    content = render_template("layouts.ex.eex", app_name: :my_app, app_module: "MyApp")
    assert content =~ "defmodule MyAppWeb.Layouts"
    assert content =~ "import EvoPhxKit.Components"
    assert content =~ "flash_group"
    assert content =~ "theme_toggle"
  end

  test "root.html.heex.eex renders with bindings" do
    content = render_template("root.html.heex.eex", app_name: :my_app, app_module: "MyApp")
    assert content =~ "my_app"
    assert content =~ "viewport"
    assert content =~ "csrf-token"
  end

  test "dev_login_controller.ex.eex renders with bindings" do
    content =
      render_template("dev_login_controller.ex.eex", app_name: :my_app, app_module: "MyApp")

    assert content =~ "defmodule MyAppWeb.DevLoginController"
    assert content =~ "EvoPhxKit.user_provider().get_user_by_email"
    assert content =~ "EvoPhxKit.Plugs.RequireDevEnv"
  end

  test "themes.css.eex renders with bindings" do
    content = render_template("themes.css.eex", app_name: :my_app, app_module: "MyApp")
    assert content =~ "daisyui-theme"
    assert content =~ "oklch"
    assert content =~ "name: \"dark\""
    assert content =~ "name: \"light\""
  end

  test "dockerfile.eex renders with bindings" do
    content = render_template("dockerfile.eex", app_name: :my_app, app_module: "MyApp")
    assert content =~ "my_app"
    assert content =~ "mix release"
    assert content =~ "EXPOSE 4000"
  end

  test "docker-compose.dev.yml.eex renders with bindings" do
    content =
      render_template("docker-compose.dev.yml.eex", app_name: :my_app, app_module: "MyApp")

    assert content =~ "POSTGRES_USER: my_app"
    assert content =~ "postgres:17"
  end

  test "daisyui-theme.js is a valid JS file" do
    path = Path.join(@template_dir, "daisyui-theme.js")
    content = File.read!(path)
    assert content =~ "daisyUI"
    assert content =~ "MIT License"
  end

  test "task module is defined" do
    assert Code.ensure_loaded?(Mix.Tasks.EvoPhxKit.Setup)
  end

  defp render_template(template_name, bindings) do
    Path.join(@template_dir, template_name)
    |> EEx.eval_file(bindings)
  end
end
