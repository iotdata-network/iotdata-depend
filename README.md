# iotdata-depend

Shared third-party-ish dependencies used in **multiple** places across the iotdata
system, aggregated here as git submodules so there is a single pinned source of
truth rather than copies scattered through each consumer.

Each entry is its own independently-controlled upstream repository:

| Submodule       | Upstream                                       |
| --------------- | ---------------------------------------------- |
| `e22900t22`     | `github.com/matthewgream/e22900t22`            |
| `hostmon`       | `github.com/matthewgream/hostmon`              |
| `mqtt-deployer` | `github.com/matthewgream/mqtt-deployer`        |

## Clone

```sh
git clone --recurse-submodules https://github.com/iotdata-network/iotdata-depend
# or, after a plain clone:
git submodule update --init --recursive    # == make init
```

## Update submodules to their latest upstream

```sh
make bump        # move every submodule to upstream HEAD and commit the new pins
# or step by step:
make update      # move the checkouts only
make status      # review what changed
make commit      # record the new pins
```

The commit pinned in this superproject is the version the rest of the system builds
against; bump it deliberately. Run `make` with no target for the full list.
