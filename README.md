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

## Prerequisites

- A running Ethereum node. A light node is acceptable.

```
docker run -it \
  -v ~/docker-ethereum:/root \
  -p 8545:8545 \
  -p 8546:8546 \
  -p 30303:30303 \
  ethereum/client-go --syncmode "light" \
  --rpc --rpcaddr "0.0.0.0" \
  --ws --wsaddr "0.0.0.0"
```

## Usage

1. Start Potterhat

  ```
  RPC_PORT=8545 mix run --no-halt
  ```

2. Health check

  ```
  curl http://localhost:8545
  ```

3. Do an RPC call

  ```
  curl -X POST http://localhost:8545 \
    -H "Content-Type: application/json" \
    --data '{
      "jsonrpc":"2.0",
      "method":"eth_blockNumber",
      "params":[],
      "id":1
    }' -s | jq
  ```

## Usage remarks

Currently Potterhat behaves as a dumb relay to Ethereum nodes, meaning that discrepancies
between implementations like Geth v.s. Parity are not handled. It is up to the user to make sure
that either:

1. Potterhat's consumers do not rely on any client-type specific features, or
2. Use the same client type for all Potterhat backend nodes

Cross-client support maybe considered for Potterhat in the future but it will take some time.

## Umbrella architecture

### Active
- `potterhat_node`: Maintains a connection to an Ethereum node
- `potterhat_rpc`: Handles external requests and responses under a disguise as an Ethereum client

### Coming soon
- `potterhat_pub_sub`: Emits Ethereum Pub/Sub events under a disguise as a single Ethereum client
- `potterhat_metrics`: Collects & computes metrics from each `node`. Emits alerts on threshold crossing
- `potterhat_cache`: Stores the Ethereum data received by `node` for later use
