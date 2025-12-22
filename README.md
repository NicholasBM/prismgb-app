<p align="center"> <img src="https://github.com/NicholasBM/prismgb-pi/blob/main/prismgbpi.png" alt="PrismGB-Pi Logo" width="400"> </p>

---

## PrismGB-Pi (Raspberry Pi TV Dock)

PrismGB-Pi is a lightweight, always-on TV dock for the Mod Retro Chromatic built on top of PrismGB and designed to run on a Raspberry Pi.

Big credit goes to the original PrismGB developer for creating the desktop application. PrismGB-Pi does not replace or fork the core project. Instead, it provides a simple, repeatable way to run PrismGB on ARM hardware, effectively turning a Raspberry Pi into a dedicated Chromatic TV dock. Source > https://github.com/josstei/prismgb-app

This setup is ideal if you want a small, silent box connected to your TV that boots straight into PrismGB and is always ready to display your Chromatic. Raspberry Pi 4 is recommended.

### What PrismGB-Pi Does

PrismGB-Pi adapts the existing PrismGB desktop application to run cleanly on Raspberry Pi (ARM) and behave like a console-style dock rather than a general-purpose desktop app.

Once installed:

* The Pi boots directly into PrismGB
* PrismGB launches automatically in fullscreen
* No keyboard or mouse is required after setup
* The system waits idle until a Chromatic is connected
* Powering the Pi on or off effectively turns the dock on or off

### Hardware Required

* Raspberry Pi (Pi 4 recommended)
* SD card
* USB-C power supply
* Micro HDMI adapter
* HDMI cable
* Mod Retro Chromatic

### Raspberry Pi Setup Instructions

First, create a new OS image on your SD card using the Raspberry Pi Imager, available for macOS and Windows.

In the Raspberry Pi Imager:

* Select OS
* Choose “Other”
* Select “Raspberry Pi OS Lite”
* Enable SSH
* Set a username and password
* Add your Wi-Fi details
* Write the image to the SD card

Insert the SD card into the Raspberry Pi and power it on. After roughly ten seconds, the Pi should be available on your network.

SSH into the Pi using:
ssh pi@<local-ip-address>

You can find the IP address using a device scanning app or your router’s admin page. Enter your password when prompted.

Once logged in, run the following command:

curl -sSL [https://raw.githubusercontent.com/NicholasBM/prismgb-pi/main/raspberry-pi/install-pi4.sh](https://raw.githubusercontent.com/NicholasBM/prismgb-pi/main/raspberry-pi/install-pi4.sh) | bash

This script installs PrismGB along with all required ARM-compatible dependencies for the Raspberry Pi. Most dependencies are prepackaged to avoid timeouts or failed network requests during installation.

The installation typically takes around ten minutes depending on network speed.

When the script completes, reboot the system:

sudo reboot

### Usage

After reboot, the Raspberry Pi will boot directly into PrismGB-Pi.

From this point on:

* The system automatically launches PrismGB in fullscreen
* No desktop environment is shown
* The application waits for a Mod Retro Chromatic to connect
* Once connected, gameplay is displayed on your TV

Powering the Raspberry Pi on and off is all that’s needed to use the dock, giving a simple, console-like experience with full retro glory on the big screen.

---

If you want, next I can:

* Tighten this further to match the tone of the rest of the README exactly
* Split it into a separate PrismGB-Pi README
* Add a short “Differences vs Desktop PrismGB” section
* Adjust wording to be more formal or more hobbyist-friendly
