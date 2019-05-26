defmodule PotterhatPubSub.WebsocketHandler do
  require Logger

  @behaviour :cowboy_websocket

  def init(request, _state) do
    state = %{registry_key: request.path}

    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    Registry.register(Registry.PotterhatPubSub, :broadcasters, {})

    {:ok, state}
  end

  #
  # Handle messages from websocket clients
  #

  def websocket_handle({:text, message}, state) do
    json = Jason.decode!(message)
    websocket_handle({:json, json}, state)
  end

  def websocket_handle({:json, _}, state) do
    {:reply, {:text, "{'hello': 'world'}"}, state}
  end

  #
  # Handle messages from other parts of the system
  #

  def websocket_info(message, state) do
    {:reply, {:text, message}, state}
  end

  #
  # Termination
  #

  def terminate(_reason, _req, _state) do
    :ok
  end
end
