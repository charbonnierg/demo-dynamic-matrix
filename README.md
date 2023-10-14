# Demo repository: dynamic matrix strategy

This repository shows how to use a GitHub Action Worflow with a dynamic matrix strategy.

## Motivation

Docker images are only built once (at release time) for many open source projects. The problem with this approach is that if when CVE is detected in the base image, CVE is present in the docker image of the project until next release, and won't be fixed for historical releases. That seems to be the case for [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) according to [this issue](https://github.com/oauth2-proxy/oauth2-proxy/issues/2243) for example.

I was wondering how projects such as oauth2-proxy could automate periodic builds for historical releases, and I  identified workflows matrix as a potential solution to the problem, because matrices let build run concurrently (as opposed to a shell script performing a for loop within a single step).

Also, in order to avoid requiring an update to the workflow file each time a new release is out, I wanted a solution which did not require configuring the git references explicitely, but rather static configuration, for example, the last 4 releases.

*Note*: building images for the N most recent releases may not be a good strategy IMO. It does not make sense to build a new image for a release which was superseded by a more recent patch release for example. Building image for the N most recent minor releases for each supported major version seems a better strategy instead. But it would make this example more complex, and it's just a matter of interacting with GitHub API + adding some logic before generating JSON output, it has nothing to do with dynamic matrices.


## Example

A single action workflow is available: [./github/workflows/docker-images.yml](https://github.com/charbonnierg/demo-dynamic-matrix/blob/main/.github/workflows/docker-images.yml). Manual dispatch outcome is available in [Actions section](https://github.com/charbonnierg/demo-dynamic-matrix/actions/runs/6517850378). Aside from manual dispatch, workflow is scheduled to run twice a month using the cron expression `"30 1 1,15 * *"` (meaning the 1st and the 15th of every month at 1:30am).

The workflow is composed of two sequential jobs (i.e., the second is dependent on the first):

- First job has a single step and a single output coming from the step. This step:
  - fetches the 4 latest releases of this project using GitHub API
  - creates an array as a JSON string holding the tag reference for each release with `jq`
  - write tags array as a JSON string into step output.

- Second job relies on JSON output from previous job to define a matrix strategy, and runs several steps for each tag reference (e.g., each release):
  - checkout repo for this tag
  - login to ocker registry
  - prepare docker buildx environment
  - build and push docker images for this tag


## Key Take Aways

- A step may emit an output by echoing into `$GITHUB_OUTPUT`:

```yaml
steps:
  - id: <stepid>
    run: |
      VALUE="some value"
      echo "<step_output_name>=$VALUE" >> "$GITHUB_OUTPUT"
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
  needs: [<jobid1>]
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

- `gh` CLI is installed in default runner environments, but requires the `GH_TOKEN` environment variable to be set:

```yaml
    steps:
      - run: gh api <path> [options]
        env:
          GH_TOKEN: ${{ github.token }}
```

- It's easy to fetch tags for latest releases using GitHub CLI and `jq` (which is also installed by default):

```yaml
    steps:
      - run: gh api "/repos/${{ github.repository }}/releases?per_page=4" | jq -j -c "map( .tag_name )"
        env:
          GH_TOKEN: ${{ github.token }}
```

  This will output `["v5","v4","v3","v2"]` assuming that the four latest release tags are `v5`, `v4`, `v3` and `v2` (values are sorted from most recent to oldest).

  Some explanations:

  - github *variable* `${{ github.repository }}` is always available in workflows environments. It contains both the repository owner and the repository name separated with a `/`. For this repo, it is equal to `charbonnierg/demo-dynamic-matrix`.

  - query string parameter `per_page` is used to limit the number of releases returned (`?per_page=4`).  

  - jq *option* `-c` is used to output a single line (by default `jq` outputs pretty formatted JSON)

  - jq *option* `-j` is used to not add a line break at the end of JSON string (by default `jq` adds a linebreak)

  - jq *expression* `map( .tag_name )` is used to extract the property `"tag_name"` for each element present in the JSON array returned by GitHub API. By default a lot of information is returned, including URLs to release asserts, so it should be possible to download assets, and build docker images using the very same assets that were compiled at release time. I don't know if that would be a good idea though... In this example, there is no "compile" step, so there is no discussion 😅
