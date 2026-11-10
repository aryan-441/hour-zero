# Hour Zero

Hour Zero is a single-player challenge game built in Godot. Players answer timed questions while risk rises, manage run rewards, and decide when to extract. This draft describes the `v5.1` source candidate; the canonical version still needs confirmation.

## Features in the reviewed source

- Challenge flow, answer validation, scoring, and risk/detection systems are separated into GDScript modules.
- Runs track questions, rewards, and difficulty progression.
- Profile data and recent-question history are stored locally by the game.
- The project includes a browser export and a Python question-bank generation tool.

## Technologies

Godot 4.7 and GDScript; Python for question-bank generation; WebAssembly/WebGL browser export.

## Run locally

Open `ZeroHour/project.godot` in Godot 4.7 with matching export templates. The existing `v5.1` hosting README gives a Node-based local preview path for the browser export. Verify the source and export match before release.

## Limitations

This is a single-player game. Progress is browser-local; questions and answers are delivered to the client, so scores are not tamper-proof. Browser/device compatibility needs confirmation. The repository should use one source version and exclude duplicate exports and caches.

## Date and credits

The folder name `GAMEJAM_2026` suggests a 2026 game-jam context; confirm the date and attribution. The source files do not state a release date. Review game asset and audio licenses before publication. No license has been selected.
