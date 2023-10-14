# Demo repository: dynamic matrix strategy

This repository shows how it's possible to use a GitHub Action Worflow with a dynamic matrix strategy.

## Example

A single action workflow is available: [./github/workflows/docker-images.yml](https://github.com/charbonnierg/demo-dynamic-matrix/blob/main/.github/workflows/docker-images.yml).

This workflow is composed of two sequential jobs:

- First job fetches the 4 latest releases of this project using GitHub API and then creates an array as JSON output holding the tag names for each release.

- Second job relies on JSON output from previous job to define a matrix strategy, and runs build & publish steps for each tag.

## Key Take Aways


- A step may emit an output by echoing into `$GITHUB_OUTPUT`:

```yaml
steps:
  - id: <stepid>
    run: |
      echo "<name>=<value>" >> "$GITHUB_OUTPUT"
```

- A job with steps emitting outputs to be consumed by other jobs must declare job outputs explicitely:

```yaml
jobs:
  <jobid1>:
    runs-on: ubuntu-latest
    outputs:
      <output_name>: ${{ steps.<stepid>.outputs.<step_output_name> }}
```

- A matrix parameter can be loaded from any JSON array output from a needed job (e.g., a previous job):

```yaml
<jobid2>:
  needs: [prepare]
  strategy:
    max-parallel: 4
    matrix:
      <param_name>: ${{ fromJson(needs.<jobid1>.outputs.<output_name>) }}
```

- Matrix parameters can be consumed just like usual:

```yaml
steps:
  - name: checkout tag for release
    uses: actions/checkout@v4
    with:
      ref: ${{ matrix.<param_name> }}
```

## Good to know

- It's easy to fetch tags for latest releases using GitHub CLI and `jq`:

```bash
gh api "/repos/${{ github.repository }}/releases?per_page=4" | jq -j -c "map( .tag_name )"
```

  > `-c` option is used to output a single line and `-j` option is used to not add a line break at the end of JSON string.

  This will output `["v5","v4","v3","v2"]` assuming that the four latest release tags are `v5`, `v4`, `v3` and `v2` (values are sorted from most recent to oldest).

> Note: gh CLI has an option named `--jq` which accepts `jq` expressions, but I don't know how to combine it with `-c` and `-j` `jq` options.


- `gh` CLI is installed in default runner environments, but requires the `GH_TOKEN` environment variable to be set:

```yaml
    steps:
      - run: |
          gh api <path> [options]
        env:
          GH_TOKEN: ${{ github.token }}
```
