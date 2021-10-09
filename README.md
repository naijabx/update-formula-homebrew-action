# Update Homebrew Formula Actions

> use for github actions to update homebrew formula

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
      - uses: naijabcom/update-formula-homebrew@master
        with:
          repo: example/hello
          tap: example/homebrew-hello
          formula: Formula/hello.rb
          download-url: https://github.com/example/hello/releases/download/1.0.0/hello.tar.gz
          sha256: xxxxxxxxxxxxx
          commit-message: update hello formula 
        env:
          COMMIT_TOKEN: ${{ secrets.COMMIT_TOKEN }}
```
