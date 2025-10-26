# Blog Infrastructure

This repository contains the Hugo project that powers [softwarenotes.netlify.app](https://softwarenotes.netlify.app/).

## Plausible Analytics configuration

The blog emits the Plausible tracking script from `layouts/partials/plausible.html`, which is included in `layouts/partials/head/custom.html`. The partial renders the script using the site parameters defined in [`hugo.toml`](hugo.toml). For the script to work, the domain configured in Hugo must match the site that is registered inside your Plausible account.

1. Log in to [Plausible](https://plausible.io/sites) and click **Add a new site**.
    2. Enter `softwarenotes.netlify.app` (or whatever domain you are tracking) and complete the setup wizard. Plausible does not require API keys—only the site URL.
3. If Plausible gives you a site-specific script URL (for example `https://plausible.io/js/pa-XXXXXXXX.js`), set it as `params.analytics.plausible.scriptURI` and enable `params.analytics.plausible.hashedScript = true` in [`hugo.toml`](hugo.toml). The partial will then emit the snippet Plausible expects, including the `plausible.init()` bootstrap code.
4. Optional: if you self-host Plausible or use a custom script endpoint, you can still set `params.analytics.plausible.scriptURI` or `params.analytics.plausible.apiURI` in [`hugo.toml`](hugo.toml); when `hashedScript` is `false`, the partial falls back to Plausible's standard `data-domain` embed.
5. Deploy the blog; once visitors arrive, the data will appear on the dashboard for the site you created in Plausible.

With this setup, no additional secrets or API keys are necessary. As long as the domain matches, Plausible will attribute page views coming from the embedded script to the site in your dashboard.
