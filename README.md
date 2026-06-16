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
git submodule update --init --recursive
```

## Update a submodule to its latest upstream

```sh
git -C <submodule> pull origin main      # move the submodule's checkout
git add <submodule> && git commit        # record the new pinned commit here
```

The commit pinned in this superproject is the version the rest of the system builds
against; bump it deliberately.
