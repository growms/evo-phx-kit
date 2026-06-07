defmodule EvoPhxKit.Components do
  @moduledoc """
  Self-contained UI components for Phoenix projects.

  ## Public API

  - `epk_flash/1` — individual flash message with auto-dismiss
  - `flash_group/1` — flash group (info, error, connection/server errors)
  - `theme_toggle/1` — dark/light/system theme toggle
  - `login_page/1` — full-screen login hero with configurable title and auth path
  """
  use Phoenix.Component
  use Gettext, backend: EvoPhxKit.Gettext

  alias Phoenix.LiveView.JS

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def epk_flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.hide(to: "##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <svg :if={@kind == :info} xmlns="http://www.w3.org/2000/svg" class="size-5 shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10" /><path d="M12 16v-4" /><path d="M12 8h.01" />
        </svg>
        <svg :if={@kind == :error} xmlns="http://www.w3.org/2000/svg" class="size-5 shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10" /><path d="m15 9-6 6" /><path d="m9 9 6 6" />
        </svg>
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("Fermer")}>
          <svg xmlns="http://www.w3.org/2000/svg" class="size-5 opacity-40 group-hover:opacity-70" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M18 6 6 18" /><path d="m6 6 12 12" />
          </svg>
        </button>
      </div>
    </div>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.epk_flash kind={:info} flash={@flash} />
      <.epk_flash kind={:error} flash={@flash} />

      <.epk_flash
        id="client-error"
        kind={:error}
        title={gettext("Connexion internet introuvable")}
        phx-disconnected={JS.show(to: ".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={JS.hide(to: "#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Tentative de reconnexion")}
        <svg xmlns="http://www.w3.org/2000/svg" class="ml-1 size-3 motion-safe:animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12a9 9 0 1 1-6.219-8.56" />
        </svg>
      </.epk_flash>

      <.epk_flash
        id="server-error"
        kind={:error}
        title={gettext("Une erreur est survenue")}
        phx-disconnected={JS.show(to: ".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={JS.hide(to: "#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Tentative de reconnexion")}
        <svg xmlns="http://www.w3.org/2000/svg" class="ml-1 size-3 motion-safe:animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12a9 9 0 1 1-6.219-8.56" />
        </svg>
      </.epk_flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label={gettext("Theme systeme")}
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="size-4 opacity-75 hover:opacity-100" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect width="20" height="14" x="2" y="3" rx="2" /><line x1="8" x2="16" y1="21" y2="21" /><line x1="12" x2="12" y1="17" y2="21" />
        </svg>
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label={gettext("Theme clair")}
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="size-4 opacity-75 hover:opacity-100" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="4" /><path d="M12 2v2" /><path d="M12 20v2" /><path d="m4.93 4.93 1.41 1.41" /><path d="m17.66 17.66 1.41 1.41" /><path d="M2 12h2" /><path d="M20 12h2" /><path d="m6.34 17.66-1.41 1.41" /><path d="m19.07 4.93-1.41 1.41" />
        </svg>
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label={gettext("Theme sombre")}
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="size-4 opacity-75 hover:opacity-100" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z" />
        </svg>
      </button>
    </div>
    """
  end

  attr :title, :string, required: true, doc: "project name displayed as heading"
  attr :login_path, :string, required: true, doc: "path to the auth provider"
  attr :login_label, :string, default: nil, doc: "button label (defaults to gettext)"

  slot :inner_block, doc: "optional content between the title and the button"

  def login_page(assigns) do
    ~H"""
    <div class="hero min-h-screen bg-base-200">
      <div class="hero-content text-center">
        <div class="max-w-md">
          <h1 class="text-4xl font-bold">{@title}</h1>
          <div :if={@inner_block != []} class="py-6 text-base-content/70">
            {render_slot(@inner_block)}
          </div>
          <a href={@login_path} class="btn btn-primary btn-lg">
            <svg xmlns="http://www.w3.org/2000/svg" class="size-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" /><polyline points="10 17 15 12 10 7" /><line x1="15" x2="3" y1="12" y2="12" />
            </svg>
            {@login_label || gettext("Se connecter")}
          </a>
        </div>
      </div>
    </div>
    """
  end
end
