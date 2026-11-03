# Hour Zero — Firebase-ready browser package

This folder is prepared for your Firebase project. No project ID, account credentials, database, analytics, billing configuration, or deployed URL is included.

## What to send / upload

- `public/` is the compiled browser game. Keep every file together and keep their names unchanged.
- `firebase.json` publishes only `public/`, not the editable source or this guide.
- `ZeroHour/` is the editable Godot 4.7 project, including its Web export preset and custom loading page.
- `serve-local.mjs` is an optional local preview server requiring Node.js, with no npm dependencies.

The compiled web game does not require players to install Godot or Python. It requires a browser with WebAssembly and WebGL 2.0 support. Desktop Chrome, Edge, or Firefox is the initial target; phones and Safari should be checked on the actual devices before sharing widely.

## Preview locally first

Open a terminal in this folder and run:

```sh
node serve-local.mjs
```

Visit `http://127.0.0.1:8417`. Click **ENTER HOUR ZERO**, then interact with the in-game menu to enable browser audio. Stop the server with Ctrl+C. Do not open `public/index.html` by double-clicking: the game must be served over HTTP/HTTPS.

## Publish to Firebase Hosting

Install the Firebase CLI using the current supported Node.js version, then sign in using your own account:

```sh
npm install -g firebase-tools
firebase login
```

Create/select your project in the Firebase Console. From this package's root directory, replace `YOUR_PROJECT_ID` with its real project ID and choose ONE deployment option:

Temporary preview link (7 days):

```sh
firebase hosting:channel:deploy zerohour-demo --expires 7d --project YOUR_PROJECT_ID
```

Or the project's normal live Hosting site:

```sh
firebase deploy --only hosting --project YOUR_PROJECT_ID
```

The CLI prints the resulting URL. **A preview URL is public to anyone who has the link; it is not password-protected.** Check the selected Firebase project before deploying: the live command updates that project's default Hosting site. Use a dedicated project/site if the default site already hosts something else.

Do not run Firebase initialization over this package unless you preserve the existing `firebase.json` and `public/index.html`. No SPA rewrite is needed. No Firebase SDK, Firestore, Cloud Functions, or Firebase App Hosting is needed for this static game.

## Browser behavior

- Progress, credits, inventory, sound settings, and recent-question history are local to this browser and website origin, using Godot's browser persistence. They do not sync between devices or automatically import the desktop save. A preview URL and a live URL have separate storage.
- Private browsing, disabled storage, clearing site data, or browser eviction can remove/prevent saved progress. Never treat the local wallet as server-authoritative currency.
- The game pauses while the tab is hidden and adjusts the answer clock when returning. This is a casual single-player demo, not an anti-cheat system.
- Audio requires user interaction. The original sound mute preference is retained.
- This is a single-threaded build. It does not require COOP/COEP isolation headers or a service worker. Caching uses revalidation to avoid stale engine/data combinations after a new deployment.
- Question content and answers are shipped to the client. This package is not suitable for a prize competition requiring secret answers or tamper-proof scores without additional server-side work.

## Rebuild after editing

1. Install Godot **4.7** and its matching official Web export templates.
2. Import `ZeroHour/project.godot` in Godot.
3. Choose **Project → Export → Web → Export Project** and export to `public/index.html` in the package root. Use a release export.
4. Keep `data/*.json` included in the export filters. Otherwise the question bank will be missing.
5. Test locally, then redeploy the entire `public/` folder with the Firebase command above.

With a `godot` command available, the equivalent export is:

```sh
godot --headless --path ZeroHour --export-release Web ../public/index.html
```

Original desktop gameplay data, scoring, detection rules, and perks are retained. Browser-only adaptations are isolated in the export preset, HTML shell, web display settings, and visibility handling.

## References

- https://firebase.google.com/docs/hosting/quickstart
- https://firebase.google.com/docs/hosting/test-preview-deploy
- https://firebase.google.com/docs/hosting/full-config
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
