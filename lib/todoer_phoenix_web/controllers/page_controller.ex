defmodule TodoerPhoenixWeb.PageController do
  use TodoerPhoenixWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
