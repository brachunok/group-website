# Sustainable and Resilient Systems Lab website

Website for the Sustainable and Resilient Systems Lab, led by Dr. Ben Rachunok in the Edward P. Fitts Department of Industrial and Systems Engineering at NC State University.

- Production domain: [brachunok.com](https://brachunok.com)
- Repository: [brachunok/group-website](https://github.com/brachunok/group-website)
- Platform: [al-folio](https://github.com/alshedivat/al-folio), Jekyll, and GitHub Pages

## Editing content

Most routine updates do not require changing layouts or application code.

| Content                         | Location                          |
| ------------------------------- | --------------------------------- |
| Site settings and feature flags | `_config.yml`                     |
| Homepage                        | `_pages/about.md`                 |
| Publications                    | `papers.bib` in `rachunok_CV`     |
| News                            | `_news/`                          |
| Research projects               | `_projects/`                      |
| People and profiles             | `_pages/profiles.md` and `_data/` |
| Contact and social links        | `_data/socials.yml`               |
| Images and documents            | `assets/img/` and `assets/pdf/`   |

## Local preview

Install the dependencies once:

```bash
npm ci
/opt/homebrew/opt/ruby/bin/bundle install
```

Start the local preview:

```bash
/opt/homebrew/opt/ruby/bin/bundle exec jekyll serve \
  --config _config.yml,_config_dev.yml \
  --host 127.0.0.1 \
  --port 4001
```

Open [http://127.0.0.1:4001](http://127.0.0.1:4001). Jekyll automatically rebuilds the site when content files change; refresh the browser to see the update.

The `_config_dev.yml` file disables demo-only processing that is unnecessary for local content previews. Production builds use `_config.yml`.

## Publications

The canonical bibliography remains in the private [`brachunok/rachunok_CV`](https://github.com/brachunok/rachunok_CV) repository. To refresh the site's local copy after editing `papers.bib`, run:

```bash
bin/sync_publications
```

This command uses your GitHub CLI login. It also converts the `selected` keyword in a BibTeX entry into the al-folio field that displays the entry under **Selected publications**. GitHub Actions performs the same import automatically before every site build using the `CV_REPO_TOKEN` repository secret.

## Validation

Before proposing a change, run:

```bash
npm run lint:prettier
npm run lint:style-contract
/opt/homebrew/opt/ruby/bin/bundle exec al-folio upgrade audit --no-fail
/opt/homebrew/opt/ruby/bin/bundle exec jekyll build
```

## Publishing workflow

1. Create a branch from `main`.
2. Make and preview the change locally.
3. Push the branch and open a pull request.
4. Confirm the automated checks pass.
5. Merge the pull request into `main`.
6. GitHub Actions builds and deploys the updated static site.

The `CNAME` file connects GitHub Pages to `brachunok.com`. DNS is managed separately through the domain registrar.

## Upstream template

This is an independent website repository, not a GitHub fork. The official al-folio project is retained locally as the `upstream` Git remote so template updates can be reviewed deliberately. Site-specific changes should be made in this repository and proposed against `brachunok/group-website`.

al-folio is distributed under the MIT License. See [LICENSE](LICENSE) for details.
