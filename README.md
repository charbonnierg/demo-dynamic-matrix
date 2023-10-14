# Demo repository: dynamic matrix strategy

This repository shows how it's possible to use a GitHub Action Worflow with a dynamic matrix strategy.

## Motivation

Docker images are only built once (at release time) for many open source projects. The problem with this approach is that if a CVE is detected in the base image, then the CVE is present in the docker image of the project until next release. That's [the case of for oauth2-proxy project](https://github.com/oauth2-proxy/oauth2-proxy/issues/2243) for example.

I was wondering how projects such as oauth2-proxy could automate periodic builds for historical releases, and quickly identified workflows matrix as a solution for the problem, because it allows build to happen concurrently (as compared to a shell script performing a for loop within a step).

Also, in order to avoid updating the workflow file each time a new release is out, I wanted a solution which did not require configuring the git references explicitely, but rather static configuration, for example, the last 4 releases.

> In practice, build images for the 4 latest releases may not be the best strategy. Building image for the N most recent minor releases for each supported major version seems a better strategy instead. But it would make this example more complex, and it's just a matter of interacting with GitHub API + adding some logic before generating JSON output, it has nothing to do with dynamic matrices.


## Example

A single action workflow is available: [./github/workflows/docker-images.yml](https://github.com/charbonnierg/demo-dynamic-matrix/blob/main/.github/workflows/docker-images.yml).

This workflow is composed of two sequential jobs:

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

- `gh` CLI is installed in default runner environments, but requires the `GH_TOKEN` environment variable to be set:

```yaml
    steps:
      - run: |
          gh api <path> [options]
        env:
          GH_TOKEN: ${{ github.token }}
```

- It's easy to fetch tags for latest releases using GitHub CLI and `jq` (both are installed by default in github runner environments):

```bash
gh api "/repos/${{ github.repository }}/releases?per_page=4" | jq -j -c "map( .tag_name )"
```

  This will output `["v5","v4","v3","v2"]` assuming that the four latest release tags are `v5`, `v4`, `v3` and `v2` (values are sorted from most recent to oldest).

  Some explanations:

  - `${{ github.repository }}` is a variable available in workflows environments. It contains both the repository owner and the repository name separated with a `/`. For this repo, it would be `charbonnierg/demo-dynamic-matrix`.

  - `per_page` query string parameter ( `?per_page=4`) is used to limit the number of releases returned. 

  - jq option `-c` is used to output a single line (by default `jq` outputs pretty formatted JSON)

  - jq option `-j` is used to not add a line break at the end of JSON string (by default `jq` adds a linebreak)

  - expression `map( .tag_name )` is used to extract the property `"tag_name"` for each element present in the JSON array returned by GitHub API. By default a lot of information is returned, including URLs to release asserts, so it should be possible to download assets, and build docker images using the very same assets that were compiled at release time. I don't know if that would be a good idea though... In this example, there is no "compile" step, so there is no discussion 😅
