# Potterhat

> Now it is such a bizarrely improbable coincidence that anything so mindbogglingly useful could evolve purely by chance that some thinkers have chosen to see it as a final and clinching proof of the non-existence of God. The argument goes something like this:
>
> "I refuse to prove that I exist," says God, "for proof denies faith, and without faith I am nothing."
>
> "But," says Man, "the Babel fish is a dead giveaway, isn't it? It could not have evolved by chance. It proves you exist, and so therefore, by your own arguments, you don't. QED."
>
> "Oh dear," says God, "I hadn't thought of that," and promptly vanishes in a puff of logic.
>
> "Oh, that was easy," says Man, and for an encore goes on to prove that black is white, and gets killed on the next zebra crossing.
>
> Most leading theologians claim that this argument is a load of dingo's kidneys. But this did not stop Oolon Colluphid making a small fortune when he used it as the central theme for his best selling book, Well That About Wraps It Up for God. Meanwhile the poor Babel fish, by effectively removing all barriers to communication between different cultures and races, has caused more and bloodier wars than anything else in the history of creation.

In other words, see https://github.com/omisego/OIP/issues/15.

## Installation

### Prerequisites

- A running Ethereum node. A light node is acceptable. Start one via Docker with:

  ```shell
  docker run -it \
    -v ~/docker-ethereum:/root \
    -p 8545:8545 \
    -p 8546:8546 \
    -p 30303:30303 \
    ethereum/client-go --syncmode "light" \
    --rpc --rpcaddr "0.0.0.0" \
    --ws --wsaddr "0.0.0.0"
  ```

### Configuration

Configure an arbitary number of nodes via environment variables:

```shell
export POTTERHAT_NODE_0_ID="cluster_geth"
export POTTERHAT_NODE_0_LABEL="Cluster Geth"
export POTTERHAT_NODE_0_CLIENT_TYPE="geth"
export POTTERHAT_NODE_0_RPC="http://cluster_geth:8545"
export POTTERHAT_NODE_0_WS="ws://cluster_geth:8545"
export POTTERHAT_NODE_0_PRIORITY="10"

export POTTERHAT_NODE_1_ID="cluster_parity"
# ...
```

## Usage

### Potterhat as a standalone service

1. Start Potterhat

    ```shell
    RPC_PORT=8545 mix run --no-halt
    ```

2. Health check

    ```shell
    curl http://localhost:8545
    ```

3. Do an RPC call

    ```shell
    curl -X POST http://localhost:8545 \
      -H "Content-Type: application/json" \
      --data '{
        "jsonrpc":"2.0",
        "method":"eth_blockNumber",
        "params":[],
        "id":1
      }' -s | jq
    ```

### Potterhat as an Elixir library

1. Add Ethereumex to your mix.exs dependencies:

    ```elixir
    def deps do
      [{:potterhat, github: "omisego/potterhat"}]
    end
    ```

2. Implement Potterhat into your Elixir application the same way you would do for [Ethereumex](https://github.com/mana-ethereum/ethereumex):

    ```elixir
    iex> PotterhatElixir.PotterhatClient.web3_client_version()
    {:ok, "Parity//v1.7.2-beta-9f47909-20170918/x86_64-macos/rustc1.19.0"}
    ```

### Usage remarks

Currently Potterhat behaves as a dumb relay to Ethereum nodes, meaning that discrepancies
between implementations like Geth v.s. Parity are not handled. It is up to the user to make sure
that either:

1. Potterhat's consumers do not rely on any client-type specific features, or
2. Use the same client type for all Potterhat backend nodes

Cross-client support may be considered for Potterhat in the future but it will take some time.

## Potential metrics

- A node falling behind in block heights
- Node synchronisation times: start, finish, time spent syncing, how many blocks pulled
- Latency of RPC call to the Ethereum node
- Number of errors for the RPC call attempt
- Number of requests by type to the RPC call
- If invalid response, what was the response?
- If the call couldn't be made, number of retry attempts
- If retries are implemented the size of the structure(s) holding the transactions
- Potterhat exposed metrics on the number of requests, time taken to serve the request, number of errors
- Size of blocks, number of transactions, uncle rate
- Number of available Ethereum nodes in the pool
- Node status (native Ethereum's JSON-RPC)
  - net_peerCount
  - net_listening
  - net_version
  - web3_clientVersion
  - eth_protocolVersion
  - eth_syncing
  - eth_mining
  - eth_hashrate
  - eth_gasPrice
  - eth_accounts
  - eth_blockNumber
