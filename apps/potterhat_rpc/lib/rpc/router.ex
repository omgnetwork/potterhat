defmodule PotterhatRPC.Router do
  @moduledoc """
  Serves RPC requests.
  """
  use Plug.Router
  require Logger
  alias Potterhat.Node
  alias Potterhat.Orchestrator.ActiveNodes

  plug(Plug.Logger)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, Jason.encode!(%{status: true}))
  end

  # Forward all POST requests to the node and relay the response back to the requester.
  post "/" do
    response = node_request(conn.body_params, conn.req_headers)

    # `resp_headers` is reset to `[]` ensure only node's headers are returned.
    conn
    |> Map.put(:resp_headers, [])
    |> merge_resp_headers(response.headers)
    |> send_resp(response.status_code, response.body)
  end

  match _ do
    send_resp(conn, 404, "Not found.")
  end

  defp node_request(body_params, header_params) do
    active_nodes = ActiveNodes.all()
    node_request(body_params, header_params, active_nodes)
  end

  defp node_request(_body_params, _header_params, []) do
    {:error, :no_nodes_available}
  end

  defp node_request(body_params, header_params, [node_id | _]) do
    case Node.rpc_request(body_params, header_params, node_id: node_id) do
      {:ok, response} ->
        label = Node.get_label(node_id: node_id)
        Logger.debug("Serving the RPC request from #{label}.")
        response

      {:error, error} ->
        ActiveNodes.deregister(node_id)
        Logger.error("Failed to serve the RPC request: #{inspect(error)}.")

        case ActiveNodes.all() |> Enum.drop(1) |> hd() do
          nil ->
            {:error, :no_nodes_available}

          next_node_id ->
            label = Node.get_label(node_id: next_node_id)
            Logger.debug("Trying to serve the RPC request from #{label} instead.")
            node_request(body_params, header_params)
        end
    end
  end
end
