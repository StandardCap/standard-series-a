# Standard Capital Series A Docs

See also, the [Standard Capital Series A Docs site](https://www.standardcap.com/docs).

The `.docx` files are the canonical source of truth.

The `.pdf` files under `pdfs/` are generated and provided for ease of viewing.

### PDF Build Process

To build the `.pdf`s from the `.docx` files, run:

```bash
./build.sh
```

This outputs to the `pdfs/` directory, depends on docker, and uses [gotenberg](https://github.com/gotenberg/gotenberg).

The GitHub Action CI checks that the `.pdf`s are up to date, so run `./build.sh` before committing.
