defmodule PotterhatElixir.PotterhatClient do
  @moduledoc """
  The Potterhat client for Ethereumex.
  """
  use Ethereumex.Client.BaseClient
  alias Jason.DecodeError
  alias PotterhatRPC.EthForwarder

  @headers [{"Content-Type", "application/json"}]

  @spec post_request(binary(), []) :: {:ok | :error, any()}
  def post_request(payload, opts) do
    case EthForwarder.forward(payload, @headers) do
      {:ok, raw} -> decode_body(raw)
      {:error, error} = error -> error
    end
  end

  @spec decode_body(binary()) :: {:ok | :error, any()}
  defp decode_body(body) do
    case Jason.decode(body) do
      {:ok, %{"error" => error}} -> {:error, error}
      {:ok, [%{} | _] = result} -> {:ok, format_batch(result)}
      {:ok, %{"result" => result}} -> {:ok, result}
      {:ok, decoded_body} -> {:error, decoded_body}
      {:error, %DecodeError{data: ""}} -> {:error, :empty_response}
      {:error, error} -> {:error, {:invalid_json, error}}
    end
  end
end
