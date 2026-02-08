# FleshHatcher

<img width="686" height="386" alt="image" src="https://github.com/user-attachments/assets/20d5570d-74d9-4530-87e0-93a624cc0f54" />


Fully automated Flesh Hatcher boss killer script. Handles the entire kill loop from banking to looting with full mechanic avoidance.

## Features

- **Full Kill Loop** — Banks, restores prayer & adrenaline, enters instance, navigates to the boss, fights, loots, and repeats
- **Mechanic Dodging** — Automatically detects and avoids all telegraph attacks:
  - 3x3 Square Telegraphs
  - Outer Ring Telegraphs
  - Middle Ring Telegraphs
  - Inner Ring Telegraphs
  - Uses Dive when available, walks out when on cooldown
- **Smart Banking** — Loads last preset and waits for full HP restoration before continuing
- **Prayer Management** — Only uses the Altar of War when prayer is below max
- **Adrenaline Crystal** — Surges to and interacts with the adrenaline crystal, waits until 100% before entering
- **Curse Activation** — Automatically activates Sorrow or Ruination before each fight
- **Instance Management** — Detects expired instances and starts fresh when needed
- **Emergency Teleport** — Teleports out if HP drops below emergency threshold
- **War's Retreat Integration** — Optionally starts from War's Retreat and teleports between kills

## Setup

1. Have your preset saved as your **last preset** at the bank chest in War's Retreat
2. Ensure you have **Sorrow** or **Ruination** curse available
3. Make sure **Dive** and **Surge** are on your action bar
4. Start the script at War's Retreat (recommended) or at the boss entrance

## Configuration

| Option | Description |
|--------|-------------|
| **Start at War's Retreat** | Toggle whether to begin the loop from War's Retreat |
| **Teleport Between Kills** | Toggle whether to teleport back to War's Retreat between kills |

## Requirements

- Access to the Flesh Hatcher boss
- War's Retreat unlocked
- Dive & Surge abilities
- Sorrow or Ruination curse
- A combat preset saved as last preset

## Feedback

Feel free to drop any feedback or bug reports!
