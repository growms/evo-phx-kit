defmodule EvoPhxKit.ComponentsTest do
  use ExUnit.Case

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias EvoPhxKit.Components

  test "epk_flash renders info flash" do
    assigns = %{flash: %{"info" => "Success!"}}

    html =
      rendered_to_string(~H"""
      <Components.epk_flash kind={:info} flash={@flash} />
      """)

    assert html =~ "Success!"
    assert html =~ "alert-info"
    assert html =~ "role=\"alert\""
  end

  test "epk_flash renders error flash" do
    assigns = %{flash: %{"error" => "Something broke"}}

    html =
      rendered_to_string(~H"""
      <Components.epk_flash kind={:error} flash={@flash} />
      """)

    assert html =~ "Something broke"
    assert html =~ "alert-error"
  end

  test "epk_flash does not render when no flash message" do
    assigns = %{flash: %{}}

    html =
      rendered_to_string(~H"""
      <Components.epk_flash kind={:info} flash={@flash} />
      """)

    refute html =~ "alert-info"
  end

  test "epk_flash renders with title" do
    assigns = %{flash: %{"error" => "details"}}

    html =
      rendered_to_string(~H"""
      <Components.epk_flash kind={:error} flash={@flash} title="Error Title" />
      """)

    assert html =~ "Error Title"
    assert html =~ "details"
  end

  test "epk_flash renders inner_block content" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Components.epk_flash kind={:info} id="custom-flash">
        Custom content here
      </Components.epk_flash>
      """)

    assert html =~ "Custom content here"
    assert html =~ "id=\"custom-flash\""
  end

  test "flash_group renders flash container" do
    assigns = %{flash: %{"info" => "Hello"}}

    html =
      rendered_to_string(~H"""
      <Components.flash_group flash={@flash} />
      """)

    assert html =~ "id=\"flash-group\""
    assert html =~ "Hello"
    assert html =~ "id=\"client-error\""
    assert html =~ "id=\"server-error\""
  end

  test "flash_group uses custom id" do
    assigns = %{flash: %{}}

    html =
      rendered_to_string(~H"""
      <Components.flash_group flash={@flash} id="my-flashes" />
      """)

    assert html =~ "id=\"my-flashes\""
  end

  test "theme_toggle renders three buttons" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Components.theme_toggle />
      """)

    assert html =~ "data-phx-theme=\"system\""
    assert html =~ "data-phx-theme=\"light\""
    assert html =~ "data-phx-theme=\"dark\""
  end

  test "theme_toggle contains SVG icons" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Components.theme_toggle />
      """)

    assert html =~ "<svg"
    assert html =~ "viewBox"
  end

  test "login_page renders title and login button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Components.login_page title="My App" login_path="/auth/oidc" />
      """)

    assert html =~ "My App"
    assert html =~ ~s(href="/auth/oidc")
    assert html =~ "btn btn-primary"
    assert html =~ "<svg"
  end

  test "login_page renders inner_block content" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Components.login_page title="Test" login_path="/login">
        <p>First paragraph</p>
        <p>Second paragraph</p>
      </Components.login_page>
      """)

    assert html =~ "First paragraph"
    assert html =~ "Second paragraph"
    assert html =~ "text-base-content/70"
  end

  test "login_page uses default label when login_label is nil" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Components.login_page title="Test" login_path="/login" />
      """)

    assert html =~ "Sign in" || html =~ "Se connecter"
  end

  test "login_page uses custom login_label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Components.login_page title="Test" login_path="/login" login_label="Sign in with Google" />
      """)

    assert html =~ "Sign in with Google"
    refute html =~ "Se connecter"
  end

  test "login_page hides content div when no inner_block" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Components.login_page title="Test" login_path="/login" />
      """)

    refute html =~ "text-base-content/70"
  end

  test "components are importable without other dependencies" do
    assert function_exported?(EvoPhxKit.Components, :epk_flash, 1)
    assert function_exported?(EvoPhxKit.Components, :flash_group, 1)
    assert function_exported?(EvoPhxKit.Components, :theme_toggle, 1)
    assert function_exported?(EvoPhxKit.Components, :login_page, 1)
  end
end
