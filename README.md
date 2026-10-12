# Zoom Webcam

Simple Bash scripts for a tighter webcam frame on Linux. Capture a 1280 × 720 MJPEG stream, crop it to a centered 400 × 400 square, and either view it in mpv or publish it to PipeWire as `Zoom_Cam`.

The zoom comes from cropping the image. Scaling the crop makes it larger without adding detail.

## Scripts

| Script | Purpose | Output |
| --- | --- | --- |
| [`webcam_mpv.sh`](webcam_mpv.sh) | View a cropped webcam preview with low-latency options | Borderless mpv window fitted to 360 × 360 |
| [`webcam_zoom.sh`](webcam_zoom.sh) | Publish the cropped feed as a PipeWire video source | 720 × 720 YUY2 video named `Zoom_Cam` |

Both scripts use `/dev/video0`, request 30 frames per second, and set the webcam's brightness control to `150` before starting.

## Requirements

- Linux with Bash and a V4L2 webcam that supports MJPEG at 1280 × 720, 30 fps.
- `v4l2-ctl` from `v4l-utils` and permission to access the camera device.
- For the preview: Flatpak and [mpv from Flathub](https://flathub.org/en/apps/io.mpv.Mpv), using the application ID `io.mpv.Mpv`.
- For the PipeWire feed: a running PipeWire desktop session, GStreamer tools, and the `v4l2src`, `jpegdec`, `videocrop`, `videoscale`, `videoconvert`, `queue`, and `pipewiresink` elements.

### Install dependencies

#### Ubuntu / Debian

On Ubuntu or Debian, install the dependencies for both scripts:

```bash
sudo apt update
sudo apt install git v4l-utils flatpak gstreamer1.0-tools \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-pipewire
```

The [GStreamer PipeWire package](https://packages.ubuntu.com/noble/gstreamer1.0-pipewire) supplies the PipeWire integration.

#### Fedora

On Fedora Workstation or another Fedora installation managed with DNF, install the dependencies for both scripts:

```bash
sudo dnf install git v4l-utils flatpak gstreamer1 \
    gstreamer1-plugins-base gstreamer1-plugins-good pipewire-gstreamer
```

Fedora's `gstreamer1` package includes `gst-launch-1.0` and `gst-inspect-1.0`. The [pipewire-gstreamer package](https://packages.fedoraproject.org/pkgs/pipewire/pipewire-gstreamer/) provides `pipewiresink`.

Your desktop must have a working PipeWire session to run `webcam_zoom.sh`; installing plugins alone does not configure one.

#### mpv via Flatpak (both distributions)

Install the mpv Flatpak, adding Flathub if needed:

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub io.mpv.Mpv
```

See the [Flatpak documentation](https://docs.flatpak.org/en/latest/using-flatpak.html) for remote and application installation details. On other distributions, install the equivalent packages with your package manager.

## Quick start

```bash
git clone https://github.com/oyogi/Zoom-Webcam.git
cd Zoom-Webcam
```

Find your webcam and check its supported capture modes and controls:

```bash
v4l2-ctl --list-devices
v4l2-ctl -d /dev/video0 --list-formats-ext
v4l2-ctl -d /dev/video0 --list-ctrls
```

If the camera uses a different device or capture mode, edit the scripts as described below before running them.

### Preview the cropped webcam

```bash
bash webcam_mpv.sh
```

The preview requests a borderless window near the bottom-right corner, with a 20-pixel offset. Placement depends on your window manager or compositor. mpv's on-screen controls and default input bindings are disabled; stop it with **Ctrl+C** in the terminal that launched it.

### Start the PipeWire camera feed

```bash
bash webcam_zoom.sh
```

Keep the terminal open while using the feed. In an application that supports PipeWire cameras, look for `Zoom_Cam` in its camera selector. Stop the feed with **Ctrl+C**.

The script publishes a PipeWire source; it does not create a `/dev/video*` loopback device. Visibility in Zoom or other conferencing apps depends on their camera backend and your desktop's PipeWire integration. Applications that only enumerate V4L2 devices may not list this source.

Run one script at a time if your webcam does not support multiple simultaneous clients.

## Customize the frame

Settings are edited directly in the scripts; there are no command-line options.

| Setting | Where to change it |
| --- | --- |
| Camera device | Every `/dev/video0` occurrence in each script, including the brightness command |
| Brightness | `--set-ctrl=brightness=150` in both scripts; choose a value supported by your camera or remove the line |
| Capture mode | mpv's `video_size`, `framerate`, and `input_format`; GStreamer's `image/jpeg` caps |
| Preview crop | `--vf=crop=400:400` in `webcam_mpv.sh` |
| Preview size and position | `--autofit=360x360` and `--geometry=-20-20` in `webcam_mpv.sh` |
| PipeWire crop | `videocrop top=160 bottom=160 left=440 right=440` in `webcam_zoom.sh` |
| PipeWire output size | `video/x-raw,width=720,height=720` in `webcam_zoom.sh` |
| Camera label | `node.description=Zoom_Cam` in `webcam_zoom.sh` |

For the default GStreamer crop:

```text
width:  1280 - 440 - 440 = 400
height:  720 - 160 - 160 = 400
```

For a centered square of size `S`, crop `(input_width - S) / 2` from each side and `(input_height - S) / 2` from the top and bottom. Use whole-pixel values that leave a positive frame size. A smaller crop gives a tighter frame; a larger crop includes more of the scene.

If you change the capture resolution, recalculate the crop. See the [GStreamer crop documentation](https://gstreamer.freedesktop.org/documentation/videocrop/videocrop.html) and [mpv manual](https://mpv.io/manual/stable/) for additional options.

Brightness changes apply to the camera itself and are not restored when the scripts exit.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Camera missing or wrong image | Run `v4l2-ctl --list-devices` and update every device reference in the script. |
| Device busy | Close other camera applications and stop the other script before retrying. |
| Permission denied | Check device permissions and your desktop's camera access settings. For the preview, also check the mpv Flatpak's device permissions. |
| Brightness error | Inspect `--list-ctrls`; the camera may use a different range or lack a brightness control. Adjust or remove the brightness command. |
| Unsupported format or negotiation error | Inspect `--list-formats-ext` and choose a supported format, resolution, and frame rate. If switching away from MJPEG, also adapt the GStreamer caps and decoder. |
| `no element "pipewiresink"` or another missing element | Install the corresponding GStreamer plugin package. Use `gst-inspect-1.0 pipewiresink` to check the PipeWire plugin. |
| mpv Flatpak not found | Install `io.mpv.Mpv`. A native mpv installation alone does not satisfy the script's `flatpak run` command. |
| `Zoom_Cam` missing from an app | Confirm the pipeline is still running and PipeWire is available. Reopen the app's camera selector; check whether the app supports PipeWire video sources. |

When reporting an issue, include the script used, terminal error output, Linux distribution, and webcam capture modes.

## License

Licensed under the [MIT License](LICENSE).
