if Code.ensure_loaded?(Igniter.Mix.Task) do
  defmodule Mix.Tasks.EvoPhxKit.Setup do
    use Igniter.Mix.Task

    @shortdoc "Generates layout, themes, Dockerfile, and DevLoginController for a Phoenix project"

    @moduledoc """
    Generates files from evo-phx-kit templates into your Phoenix project.

    ## Usage

        mix evo_phx_kit.setup

    ## Options

    * `--only` - Comma-separated list of components to generate.
      Valid values: `layouts`, `themes`, `dockerfile`, `dev_login`.
      Default: all.

    * `--no-dev-login` - Skip generating the DevLoginController.
    """

    def info(_argv, _source) do
      %Igniter.Mix.Task.Info{
        group: :evo_phx_kit,
        example: "mix evo_phx_kit.setup",
        schema: [only: :string, no_dev_login: :boolean],
        defaults: [no_dev_login: false]
      }
    end

    def igniter(igniter) do
      options = igniter.args.options
      app_name = Igniter.Project.Application.app_name(igniter)
      app_module = app_name |> to_string() |> Macro.camelize()

      only = parse_only(options[:only])
      skip_dev_login = options[:no_dev_login]

      bindings = [
        app_name: app_name,
        app_module: app_module
      ]

      igniter
      |> maybe_generate(:layouts, only, fn ign ->
        ign
        |> create_from_template(
          "lib/#{app_name}_web/components/layouts.ex",
          "layouts.ex.eex",
          bindings
        )
        |> create_from_template(
          "lib/#{app_name}_web/components/layouts/root.html.heex",
          "root.html.heex.eex",
          bindings
        )
      end)
      |> maybe_generate(:themes, only, fn ign ->
        ign
        |> create_from_template(
          "assets/css/themes.css",
          "themes.css.eex",
          bindings
        )
        |> copy_static("assets/vendor/daisyui-theme.js", "daisyui-theme.js")
      end)
      |> maybe_generate(:dockerfile, only, fn ign ->
        ign
        |> create_from_template("Dockerfile", "dockerfile.eex", bindings)
        |> create_from_template("docker-compose.dev.yml", "docker-compose.dev.yml.eex", bindings)
      end)
      |> maybe_generate(:dev_login, only, fn ign ->
        if skip_dev_login do
          ign
        else
          create_from_template(
            ign,
            "lib/#{app_name}_web/controllers/dev_login_controller.ex",
            "dev_login_controller.ex.eex",
            bindings
          )
        end
      end)
    end

    defp parse_only(nil), do: nil

    defp parse_only(only_string) do
      only_string
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.to_atom/1)
      |> MapSet.new()
    end

    defp maybe_generate(igniter, _component, nil, fun), do: fun.(igniter)

    defp maybe_generate(igniter, component, only_set, fun) do
      if MapSet.member?(only_set, component), do: fun.(igniter), else: igniter
    end

    defp create_from_template(igniter, target_path, template_name, bindings) do
      template_path = template_dir(template_name)
      content = EEx.eval_file(template_path, bindings)
      Igniter.create_new_file(igniter, target_path, content, on_exists: :overwrite)
    end

    defp copy_static(igniter, target_path, source_name) do
      source_path = template_dir(source_name)
      content = File.read!(source_path)
      Igniter.create_new_file(igniter, target_path, content, on_exists: :overwrite)
    end

    defp template_dir(file) do
      :evo_phx_kit
      |> :code.priv_dir()
      |> Path.join("templates/evo_phx_kit.setup/#{file}")
    end
  end
end
