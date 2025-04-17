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

  pipeline :soap do
    plug :accepts, ["xml"]
    plug :fetch_session
    #plug AriWeb.Plugs.SOAPParser
    # CSRF protection is not included here
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

    post "/create", UserController, :create
    post "/login", UserController, :login
    post "/roles", UserController, :create_role
    post "/permissions", UserController, :create_permission
    post "/resources", UserController, :create_resource
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
