# Pi Screensaver

A daemon for Raspberry Pi that manages an image slideshow screensaver with touch input monitoring, scheduled blank periods, and a web-based management interface.

## Features

### Core Functionality
- **Idle-based screensaver**: Automatically starts an image slideshow after a configurable idle timeout
- **Touch input monitoring**: Detects touch events via libinput to wake from screensaver
- **Night mode**: Scheduled screen blanking periods (e.g., 23:00-07:00) where the display is powered off
- **Display control**: Uses `wlr-randr` to power display on/off for blank periods

### Web Interface
- **Image gallery**: Browse images in a Bootstrap-powered grid layout
- **Image upload**: Upload multiple images via web interface
- **Enable/Disable images**: Temporarily hide images without deleting them (renames with `.disabled` extension)
- **Separate views**: Images are organized into "Active" and "In-Active" sections

### REST API
- **Start/Stop screensaver**: Control screensaver via HTTP API endpoints
- **Swagger documentation**: Interactive API documentation at `/swagger/index.html`
- **Schedule-aware**: API respects blank window schedule (won't start during night mode)

## Building

### Prerequisites
- Go 1.16 or higher
- For Swagger docs: `swag` tool (install with `go install github.com/swaggo/swag/cmd/swag@latest`)

### Build for Raspberry Pi

Use the included build script for cross-compilation:

```bash
# Build for 64-bit Raspberry Pi (Pi 3+, Pi 4) - default
./build-pi.sh

# Build for 32-bit Raspberry Pi (Pi 1, Zero, Pi 2)
./build-pi.sh arm

# Build for 64-bit explicitly
./build-pi.sh arm64
```

This will create:
- `piscreensaver-arm64` for 64-bit builds
- `piscreensaver-arm` for 32-bit builds

### Manual Build

You can also build manually:

```bash
# For 64-bit ARM
GOOS=linux GOARCH=arm64 go build -o piscreensaver-arm64 ./main.go

# For 32-bit ARM
GOOS=linux GOARCH=arm GOARM=7 go build -o piscreensaver-arm ./main.go
```

### Generate Swagger Documentation

If you modify the API annotations, regenerate the Swagger docs:

```bash
swag init
```

## Installation on Raspberry Pi

### 1. Transfer the Binary

```bash
# From your development machine
scp piscreensaver-arm64 pi@your-pi-ip:~/
```

### 2. Make it Executable

```bash
ssh pi@your-pi-ip
chmod +x ~/piscreensaver-arm64
```

### 3. Install Dependencies

The daemon requires:
- `libinput` - for touch input monitoring
- `imv-wayland` - for image slideshow display
- `wlr-randr` - for display power control (usually part of wlr-randr package)

```bash
sudo apt-get update
sudo apt-get install libinput-tools imv-wayland wlr-randr
```

## Configuration

### Command-Line Options

| Option | Default | Description |
|--------|---------|-------------|
| `--timeout` | `900` | Idle timeout in seconds before screensaver starts |
| `--device` | `/dev/input/event5` | Input device node for touch events |
| `--dir` | `/home/ralfonso/Pictures/screensaver` | Directory containing images for slideshow |
| `--imv` | `/usr/bin/imv-wayland` | Path to imv-wayland binary |
| `--imv-args` | `"-f -s full -t 30"` | Arguments passed to imv-wayland (excluding directory) |
| `--logfile` | `/tmp/screensaver-daemon.log` | Log file path |
| `--debug` | `false` | Enable verbose logging to stdout |
| `--blank_start` | `"23:00"` | Time to begin screen blanking (HH:MM, 24h) |
| `--blank_end` | `"07:00"` | Time to end screen blanking (HH:MM, 24h) |
| `--output_name` | `"HDMI-A-1"` | Wayland/wlr-randr output name for display control |
| `--web_port` | `"8087"` | Port for web server (empty string to disable) |
| `--no-touch` | `false` | Disable touch input monitoring (for testing) |

### Finding Your Touch Device

To find the correct touch device:

```bash
libinput list-devices | grep -A 5 "Touchscreen"
```

Look for the device path (e.g., `/dev/input/event5`).

### Finding Your Display Output

To find the correct display output name:

```bash
wlr-randr
```

Look for the output name (e.g., `HDMI-A-1`, `DP-1`, etc.).

## Autostart on Linux (systemd)

### 1. Create systemd Service File

Create `/etc/systemd/system/piscreensaver.service`:

```ini
[Unit]
Description=Pi Screensaver Daemon
After=graphical.target

[Service]
Type=simple
User=pi
ExecStart=/home/pi/piscreensaver-arm64 \
  --timeout 900 \
  --device /dev/input/event5 \
  --dir /home/pi/Pictures/screensaver \
  --imv /usr/bin/imv-wayland \
  --imv-args "-f -s full -t 30" \
  --logfile /var/log/piscreensaver.log \
  --blank_start 23:00 \
  --blank_end 07:00 \
  --output_name HDMI-A-1 \
  --web_port 8087
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
```

**Important:** Adjust the paths and parameters to match your system:
- Update `User` to your username
- Update `ExecStart` path to where you placed the binary
- Update `--device` to your touch device path
- Update `--dir` to your images directory
- Update `--output_name` to your display output

### 2. Enable and Start the Service

```bash
# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable piscreensaver.service

# Start the service immediately
sudo systemctl start piscreensaver.service

# Check status
sudo systemctl status piscreensaver.service

# View logs
sudo journalctl -u piscreensaver.service -f
```

### 3. Service Management

```bash
# Stop the service
sudo systemctl stop piscreensaver.service

# Restart the service
sudo systemctl restart piscreensaver.service

# Disable autostart
sudo systemctl disable piscreensaver.service
```

## Usage

### Running Manually

```bash
./piscreensaver-arm64 \
  --timeout 900 \
  --device /dev/input/event5 \
  --dir /home/pi/Pictures/screensaver \
  --web_port 8087 \
  --blank_start 23:00 \
  --blank_end 07:00
```

### Web Interface

Once running, access the web interface at:
```
http://your-pi-ip:8087
```

Features:
- View all images in a grid
- Upload new images (multiple files supported)
- Click filename to view full-size image
- Click × button to disable an image
- Click ✓ button to re-enable a disabled image

### API Endpoints

**Start Screensaver**
```bash
curl -X POST http://your-pi-ip:8087/api/startscreensaver
```

**Stop Screensaver**
```bash
curl -X POST http://your-pi-ip:8087/api/stopscreensaver
```

**Swagger Documentation**
```
http://your-pi-ip:8087/swagger/index.html
```

## Image Management

### Active vs Inactive Images

- **Active images**: Shown in the "Active" section, included in the slideshow
- **Inactive images**: Shown in the "In-Active" section (grayed out), excluded from slideshow

### Disabling Images

When you disable an image via the web interface, it's renamed with a `.disabled` extension:
- `photo.jpg` → `photo.jpg.disabled`

The file is not deleted, so you can re-enable it later. Disabled images are still visible in the web interface but are excluded from the slideshow.

### Re-enabling Images

Click the green ✓ button on any disabled image to re-enable it. The `.disabled` extension is removed.

## Troubleshooting

### Screensaver Not Starting

1. Check that images exist in the specified directory
2. Verify `imv-wayland` is installed and at the correct path
3. Check logs: `journalctl -u piscreensaver.service -n 50`

### Touch Not Working

1. Verify the device path: `libinput list-devices`
2. Check permissions: `ls -l /dev/input/event*`
3. Test manually: `libinput debug-events --device /dev/input/event5`
4. You may need to add your user to the `input` group:
   ```bash
   sudo usermod -a -G input $USER
   # Log out and back in
   ```

### Display Not Blanking

1. Verify display output name: `wlr-randr`
2. Test manually: `wlr-randr --output HDMI-A-1 --off`
3. Check that `blank_start` and `blank_end` times are correct

### Web Interface Not Accessible

1. Verify the service is running: `systemctl status piscreensaver.service`
2. Check if port is in use: `sudo netstat -tlnp | grep 8087`
3. Check firewall: `sudo ufw status`
4. Check logs for errors: `journalctl -u piscreensaver.service -n 50`

## Development

### Testing on macOS

For development/testing on macOS where libinput isn't available:

```bash
go run main.go --no-touch --web_port 8087 --debug
```

This disables touch monitoring and allows you to test the web interface.

### Generating Swagger Docs

After modifying API annotations:

```bash
swag init
```

## License

MIT

