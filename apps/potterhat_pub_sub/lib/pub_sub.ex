defmodule PotterhatPubSub do
  @moduledoc """
  Provides essential functionalities for Pub/Sub transport.
  """

  def broadcast(message) when is_map(message) do
    message
    |> Jason.encode!()
    |> broadcast()
  end

  def broadcast(message) do
    Registry.dispatch(Registry.PotterhatPubSub, :broadcasters, fn(entries) ->
      for {pid, _} <- entries, do: Process.send(pid, message, [])
    end)
  end
end
