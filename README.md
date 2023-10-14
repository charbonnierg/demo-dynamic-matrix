# Demo repository: dynamic matrix strategy

This repository shows how it's possible to use a GitHub Action Worflow with a dynamic matrix strategy.

## Example

A single action workflow is available: [./github/workflows/docker-images.yml](https://github.com/charbonnierg/demo-dynamic-matrix/blob/main/.github/workflows/docker-images.yml).

This workflow is composed of two sequential jobs:

- First job fetches the 4 latest releases of this project using GitHub API and then creates an array as JSON output holding the tag names for each release.

- Second job relies on JSON output from previous job to define a matrix strategy, and runs build & publish steps for each tag.

## Take Aways


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
