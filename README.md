# Hour Zero

**Play the game: https://hourzero.web.app**

Hour Zero is a single-player challenge game about solving puzzles under pressure and deciding when to bank your rewards. The network grows more dangerous as exposure rises. Extract in time to keep your unbanked credits.

## How a run works

1. Solve a timed challenge. The game includes math, patterns, logic, memory, and attention puzzles.
2. Build your score and earn credits. Correct answers can lower exposure, while mistakes and overtime can raise it.
3. Choose whether to continue deeper or extract and secure your unbanked credits.
4. Watch the detection chance rise with exposure. A detected run loses its unbanked cache.

Boss challenges arrive during longer runs. Five single-use perks give you ways to manage the timer, signal risk, and rewards.

## Game features

- Local progress, scores, credits, perk inventory, and sound settings saved in your browser
- Five detection bands, timed challenges, overtime, and escalating risk
- Five perks and recurring boss encounters
- Stats for accuracy, response time, completed runs, and banked or lost credits
- Laptop-first browser interface with a dedicated phone notice
- Original harbor artwork and sound effects created for Hour Zero

Progress is stored separately by browser and website. It does not sync between devices.

## Play or preview locally

The live game is available at **https://hourzero.web.app**. You do not need to install Godot to play it.

To preview the exported browser build, install Node.js and run this from the project folder:

    node serve-local.mjs

Open http://127.0.0.1:8417. Serve the files over HTTP instead of opening public/index.html directly.

## Project files

- ZeroHour/ — editable Godot 4.7 project, game scripts, question bank, and Web export settings
- public/ — exported browser game and website pages
- serve-local.mjs — small local preview server with no extra packages
- firebase.json — Firebase Hosting configuration for the public/ folder

## Build the web game

Install Godot 4.7 and its matching Web export templates. Import ZeroHour/project.godot, then export the Web preset to public/index.html.

With the Godot command line available:

    godot --headless --path ZeroHour --export-release Web ../public/index.html

Keep the exported files together when previewing or hosting the game.

## Website and support

- Game: **https://hourzero.web.app**
- Privacy policy: https://hourzero.web.app/privacy.html
- Terms of service: https://hourzero.web.app/terms.html
- Support: hourzerosupport@gmail.com

## License

Hour Zero is proprietary. See LICENSE for usage terms. Godot and other third-party components remain under their respective licenses.

