# Hour Zero

**Project date: 28 October 2026.**

A single-player Godot challenge game. Answer timed questions as risk rises, collect rewards, and decide when to extract.

## Features

- Timed challenge flow with answer validation, scoring, and risk progression.
- Rewards and difficulty progression across a run.
- Local profile data and recent-question history.
- Browser export and a Python question-bank generation tool.

## Technologies

Godot 4.7, GDScript, Python, and a WebAssembly/WebGL browser export.

## Run locally

Open `ZeroHour/project.godot` in Godot 4.7 with matching export templates. The browser build can be previewed with the Node-based instructions in the hosting README.

## Notes

Progress is stored in the browser. Questions and answers are available to the client, so scores are not tamper-proof.
