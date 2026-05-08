defmodule AriWeb.Router do
  use AriWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AriWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated_api do
    plug :accepts, ["json"]
    plug AriWeb.Plugs.RequireAuth
  end

  pipeline :authenticated_browser do
    plug AriWeb.Plugs.RequireAuth, mode: :redirect
  end

  pipeline :soap do
    plug :accepts, ["xml"]
    plug :fetch_session
    #plug AriWeb.Plugs.SOAPParser
    # CSRF protection is not included here
  end

  scope "/", AriWeb do
    pipe_through :browser

    get "/", IndexController, :index
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    get "/logout", SessionController, :delete
  end

  scope "/", AriWeb do
    pipe_through [:browser, :authenticated_browser]

    get "/dashboard", DashboardController, :index
    get "/viewer", DashboardController, :viewer_index
    get "/viewer/payload/:action/:id", DashboardController, :viewer_payload
  end

  scope "/soap", AriWeb do
    pipe_through :soap
    post "/availability", AvailabilityController, :update, plug: AriWeb.Plugs.SOAPParser
    post "/getAvailabilities", AvailabilityController, :get_list, plug: AriWeb.Plugs.SOAPParser
    post "/rate", RateController, :update, plug: AriWeb.Plugs.SOAPParser
    post "/getRates", RateController, :get_list, plug: AriWeb.Plugs.SOAPParser
    post "/inventory", InventoryController, :update, plug: AriWeb.Plugs.SOAPParser
    post "/getInventories", InventoryController, :get_list, plug: AriWeb.Plugs.SOAPParser
    get "/public.wsdl", SoapController, :public
    get "/private.wsdl", SoapController, :private
  end

  scope "/api", AriWeb do
    pipe_through :api

    post "/login", UserController, :login
  end

  scope "/api", AriWeb do
    pipe_through :authenticated_api

    get "/session", SessionController, :show
    post "/create", UserController, :create
    post "/roles", UserController, :create_role
    post "/permissions", UserController, :create_permission
    post "/resources", UserController, :create_resource
  end

  scope "/dashboard/api", AriWeb do
    pipe_through :authenticated_api

    get "/messages", DashboardController, :messages
    post "/messages/active", DashboardController, :update_messages
    get "/users", DashboardController, :users
    post "/users", DashboardController, :create_user
  end

  scope "/viewer", AriWeb do
    pipe_through :authenticated_api

    get "/messages", DashboardController, :viewer_messages
    post "/messages/active", DashboardController, :viewer_update_messages
    get "/users", DashboardController, :viewer_users
    post "/users", DashboardController, :viewer_create_user
    delete "/users/:id", DashboardController, :viewer_delete_user
  end


  # Other scopes may use custom stacks.
  # scope "/api", AriWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ari, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AriWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

end
