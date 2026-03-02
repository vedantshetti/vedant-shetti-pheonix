defmodule TodoerPhoenixWeb.ErrorHTML do
  use TodoerPhoenixWeb, :html

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
