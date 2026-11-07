# Sample wallpapers

Eight original, MIT-licensed web wallpapers for WorkshopWall. Each folder holds a single `index.html` (a WebGL fragment shader with a tiny loader), a `project.json` and a `preview.jpg`.

| Folder | Look |
|---|---|
| [`aurora`](aurora) | Northern lights over a mountain ridge |
| [`caustics`](caustics) | Light rippling across the bottom of a pool |
| [`synthwave`](synthwave) | Retro sun over an endless neon grid |
| [`dunes`](dunes) | Desert dunes drifting at sunset |
| [`nebula`](nebula) | Slowly evolving space clouds and stars |
| [`lava-lamp`](lava-lamp) | Warm metaballs merging and splitting |
| [`silk`](silk) | Flowing, domain-warped color |
| [`bokeh`](bokeh) | Out-of-focus city lights floating upward |

## Use them

Drag this `examples` folder (or any single sample) onto the WorkshopWall library window. They also run in Wallpaper Engine, and you can open any `index.html` in a browser to preview it.

## How they're built

- The whole image is one fragment shader drawn on a full-screen triangle, so there are no textures or other files to load.
- They render below native resolution (`SCALE` at the top of the script) because soft images look the same at 50–60 % and use far less GPU time.
- They stop their animation loop when WorkshopWall or Wallpaper Engine calls `wallpaperPropertyListener.setPaused(true)`.
- `index.html?t=12` starts the animation at a fixed time, which is how the preview images were made.

## Make your own

Copy a folder, change `title` in `project.json`, and edit the `FRAGMENT` shader. `R` is the canvas size in pixels and `T` is the time in seconds; `hash`, `noise` and `fbm` are available. Replace `preview.jpg` with a screenshot of your result.

Pull requests with new samples are welcome. Please keep them original, self-contained and light on the GPU.
