defmodule TodoerPhoenixWeb.Router do
  use TodoerPhoenixWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {TodoerPhoenixWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", TodoerPhoenixWeb do
    pipe_through(:browser)

    live("/login", AuthLive, :login)
    live("/register", AuthLive, :register)
    live("/", TodoLive, :index)
  end

  if Application.compile_env(:todoer_phoenix, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: TodoerPhoenixWeb.Telemetry)
    end
  end
end
