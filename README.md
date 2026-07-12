# Next.js Template

Minimal Next.js App Router template for Cloudflare Workers SSR with vinext.

## Deploy with Tachyon Cloud Apps

Create a repository with **Use this template**, clone it, and run:

```sh
./scripts/tachyon-apply.sh --dry-run
./scripts/tachyon-apply.sh
tachyon compute builds trigger \
  --branch main \
  --tenant-id tn_01hjjn348rn3t49zz6hvmfq67p
```

The helper derives the GitHub owner, repository, and Cloud App name from the
`origin` remote, renders `tachyon.yml`, and registers the app. The build command
can then omit the app name because Tachyon resolves the registered app from the
same remote. A successful build deploys the Worker automatically.

No file edits are required for repositories in the default Tachyon tenant. For
a different tenant or app name, override only the value that differs:

```sh
TACHYON_TENANT_ID=tn_example ./scripts/tachyon-apply.sh
TACHYON_APP_NAME=my-app ./scripts/tachyon-apply.sh
```

Set `TACHYON_BIN=/path/to/tachyon` if the CLI is not on `PATH`. The generated
Cloud App uses the Kubernetes Kata runner, Node.js 22, `npm ci`, `npm run build`,
and `/` as its readiness check.

## Commands

```sh
npm install
npm run dev
npm run build
npm run deploy
```

`npm run deploy` expects Wrangler to be authenticated and a Cloudflare account
to be selected through Wrangler or `CLOUDFLARE_ACCOUNT_ID`.
