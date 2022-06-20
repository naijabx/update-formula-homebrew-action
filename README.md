# Update Homebrew Formula Actions

[![version](https://img.shields.io/badge/release-v1.1-blue)](https://github.com/marketplace/actions/update-homebrew-formula)

> use for github actions to update homebrew formula

## Prerequisite

1. Create homebrew tap repository with pattern `<username>/homebrew-<project-name>` [example](https://github.com/naijab/homebrew-levis/)
2. Create file in `Formula/<project-name>.rb` with blank file and commit
3. Setup secret use personal access token with full repository permissions for example set name **COMMIT_TOKEN**

## Example

```yaml
name: Release

on:
  release:
    types:
      - created

jobs:
  update_formula_version:
    name: Update the Homebrew formula with latest release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Get version
        id: get_version
        run: echo ::set-output name=version::${GITHUB_REF/refs\/tags\//}

      # add build step ...

      - name: Upload MacOS Release Asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ./bin/target/hello-${{ steps.get_version.outputs.version }}-macos-x64.tar.gz
          asset_name: hello-${{ steps.get_version.outputs.version }}-macos-x64.tar.gz
          asset_content_type: application/gzip

      - name: Set macOS release SHA 256
        id: shasum-mac-os
        run: |
          echo ::set-output name=sha::"$(shasum -a 256 ./bin/target/hello-${{ steps.get_version.outputs.version }}-macos-x64.tar.gz | awk '{printf $1}')"
      - uses: naijabx/update-formula-homebrew-action@v1
        with:
          repo: example/hello
          tap: example/homebrew-hello
          formula: Formula/hello.rb
          download-url: https://github.com/example/hello/releases/download/${{ steps.get_version.outputs.version }}/hello-${{ steps.get_version.outputs.version }}-macos-x64.tar.gz
          sha256: xxxxxxxxxxxxx
          commit-message: update hello formula
        env:
          COMMIT_TOKEN: ${{ secrets.COMMIT_TOKEN }}
```
