# Seasons Survival (Godot 4 prototype)

A one-screen, Terraria-style survival game. Survive the increasingly harsh
natural cycle for as long as possible. Mythological creatures only come out at night.

## How to open it
1. Install Godot 4.2 or newer (the standard version, not .NET): godotengine.org
2. Unzip this folder.
3. In Godot's project manager click **Import**, pick `project.godot`, then **Import & Edit**.
4. Press **F5** to run.

## Controls
| Key | Action |
|---|---|
| A / D or arrows | Move |
| W / Space / Up | Jump |
| E | Interact: chop tree (+3 logs), pick bush (+2 berries), draw water at the well |
| F | Attack |
| 1 / 2 | Eat / Drink |
| 3 | Build shelter (10 logs, 3 plots) |
| 4 | Build trap (3 logs, 1 plot) |
| 5 | Upgrade the shelter you're standing at (15 logs, then 25) |
| 6 | Upgrade the trap you're standing at/facing (5 logs, then 8) |
| Z | Sleep (night only, inside a shelter). Move or press Z to wake |
| R | Restart (after dying) |

The yellow marker under the ground shows which plot E acts on.

## Files
- `scripts/items.gd`  (Autoload) Item enum + hunger/thirst replenish values
- `scripts/clock.gd`  (Autoload) 24h cycle, seasons, day/night signals
- `scripts/player.gd` movement, hunger/thirst/health, inventory
- `scripts/enemy.gd`  Draugr + Wendigo behaviour
- `scripts/main.gd`   world plots, building, spawning, season effects, HUD, drawing

## Sleeping
Press Z inside a shelter at night to skip ahead. Time runs 10x faster (14x at shelter Lv 2,
20x at Lv 3), but hunger and thirst drain just as much game-time, so eat and drink first.
You wake automatically at dawn, if you start starving, or when you move.

## Upgrades (max level 3)
| Level | Shelter | Trap |
|---|---|---|
| 1 | Safe from creatures, 10x sleep | 5 damage, 1 charge |
| 2 | Heals 2 hp/s inside, 14x sleep | 8 damage, 2 charges |
| 3 | Heals 5 hp/s inside, 20x sleep | 12 damage, 3 charges |

All the numbers are constants at the top of `main.gd`.

## Season effects implemented
- Spring: fast regrowth
- Summer: thirst drains 1.5x
- Autumn: berries rot, Wendigo appears at night
- Winter: no regrowth, hunger drains 1.5x

## TODO ideas (from the whiteboard)
- Spring flash floods, summer forest fires
- Temperature stat
- More mythological enemies each yearly cycle (add a kind in enemy.gd + _spawn_enemy in main.gd)
- Real art and sound
