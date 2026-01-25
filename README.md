# Battleground Defender (v3.7)

**Battleground Defender** is a powerful communication and tactical reporting tool for World of Warcraft (Retail & Midnight). It is designed for coordinated Battleground play, combining the classic logic of *AB Defender* with a modern, flexible interface and automated event detection.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![WoW Version: 11.0.7 / 12.0.0](https://img.shields.io/badge/WoW-Retail%20%2F%20Midnight-blue)](https://worldofwarcraft.com)

---

## 🛡️ Key Features

* **Modular Snap-Layout:** Drag action buttons (INC, HELP, EFC, SAFE) to any side of the numeric core. They snap into place and stay anchored to the center frame.
* **Elastic UI:** The background frame automatically resizes its bounding box to perfectly fit your custom button arrangement.
* **Auto-Event Reporting:** Automatically announces in group chat when you pick up/drop a flag, capture a base, or control an orb in Temple of Kotmogu (Disabled by default, can be toggled in settings).
* **Smart Localization:** Automatically detects German and English sub-zone names. Includes a "Force English" option for international groups.
* **Modern Integration:** Full support for the **Addon Compartment** (Esc -> Addons) and a customizable **Minimap Button**.
* **Media Support:** Use any custom fonts or sounds registered via `LibSharedMedia-3.0`.

---

## 🚀 Installation

1.  Download the latest version as a `.zip` file.
2.  Extract the folder into your WoW directory: `_retail_/Interface/AddOns/BattlegroundDefender`.
3.  Ensure the folder name is exactly `BattlegroundDefender`.
4.  Restart World of Warcraft.

> [!NOTE]
> All required libraries (LibStub, LibDBIcon, etc.) are **embedded** within the addon. No additional library downloads are necessary.

---

## 🛠️ Commands & Usage

| Command | Action |
| :--- | :--- |
| `/bd` or `/bd help` | Displays the command overview in the chat. |
| `/bd open` | Toggles the main interface visibility. |
| `/bd reset` | Resets all settings, positions, and scales to default. |

**Controls:**
* **Left-Click (Numbers):** Reports the number of incoming enemies + your current sub-zone.
* **Left-Click (Actions):** Reports the specific status (Inc, Help, EFC, Safe).
* **Right-Click (Minimap Icon):** Opens the Settings Menu directly.
* **Drag (Unlocked):** Move the frame or snap action buttons to new positions.

---

## 📂 Project Structure

* `core.lua`: The primary logic and event handling.
* `libs.xml`: Loading instructions for embedded libraries.
* `icon.tga`: Official in-game icon (64x64).
* `LICENSE`: MIT License terms.
* `libs/`: Contains the embedded library suite (LibDBIcon, LibDataBroker, etc.).

---

## ✍️ Author & Credits

* **Developed by:** Triplehxh-Blackhand
* **Concept:** Based on the logic of the classic *AB Defender*.

---

## ⚖️ License

This project is licensed under the **MIT License** – see the `LICENSE` file for details.