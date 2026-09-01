# GCR_doc

The documentation site behind [gcr.junbingao.com](https://gcr.junbingao.com).

## Layout

    html/            everything the web server exposes
    docker-compose.yml   Apache serving html/ on port 49862
    sync-gcr.sh      mirrors the GCR repository into html/

## Serving the site

    docker compose up -d

## Mirroring GCR

`sync-gcr.sh` keeps a shallow clone of the GCR repository beside this checkout
and publishes three generated files into `html/`:

| file | purpose |
| --- | --- |
| `install.sh` | the installer, so `curl -fsSL https://gcr.junbingao.com/install.sh \| sh` works |
| `gcr.tar.gz` | the repository, unpacking to `GCR/`, used by the installer instead of cloning from GitHub |
| `gcr.commit` | the commit the mirror sits on, also used to skip needless republishing |

Run it once by hand, then from cron:

    ./sync-gcr.sh
    crontab -e
    */10 * * * * /opt/GCR_doc/sync-gcr.sh >> /var/log/gcr-sync.log 2>&1

The three files are generated and stay out of git.
