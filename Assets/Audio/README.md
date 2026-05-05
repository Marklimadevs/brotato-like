# Assets de Áudio

Estrutura esperada pelo `AudioManager`. **O sistema funciona mesmo sem esses arquivos** — calls de `play_sfx`/`play_music` ficam silenciosas até o arquivo ser adicionado.

Formatos aceitos: `.ogg` (preferido pra web), `.wav`, `.mp3`. Loop automático em músicas.

## Pasta SFX (`Assets/Audio/SFX/<nome>.ogg`)

Curtos, alguns segundos no máximo. Sugestão: gerar em https://sfxr.me — clica nos presets, ajusta sliders, exporta WAV, converte pra OGG.

| Nome do arquivo | Quando toca | Sugestão sfxr |
|-----------------|-------------|----------------|
| `shoot_pistol.ogg` | Pistol atira | preset Laser/Shoot, pitch médio |
| `shoot_smg.ogg` | SMG atira | Laser curto, mais agudo |
| `shoot_shotgun.ogg` | Shotgun atira | Explosion preset, curto |
| `shoot_sniper.ogg` | Sniper atira | Laser preset, grave + reverb |
| `bullet_hit.ogg` | Bala acerta inimigo | Hit preset, curto e seco |
| `enemy_hit_crit.ogg` | Hit crítico no inimigo | Hit + pitch alto + reverb |
| `enemy_death.ogg` | Inimigo comum morre | Explosion preset, curto |
| `enemy_split.ogg` | Splitter morre e divide | Explosion + pitch wobble |
| `boss_hit.ogg` | Boss recebe dano | Hit preset, grave |
| `boss_die.ogg` | Boss morre | Explosion longa + reverb |
| `boss_spawn.ogg` | Boss aparece | Explosion grave + reverb |
| `pickup.ogg` | Player coleta gem | Pickup/Coin preset |
| `level_up.ogg` | Tela de level up abre | Powerup preset, ascendente |
| `wave_start.ogg` | Nova wave começa | Powerup curto |
| `wave_complete.ogg` | Wave termina | Powerup ascendente, agudo |
| `player_hurt.ogg` | Player toma dano | Hit preset, grave |
| `player_die.ogg` | Player morre | Hit preset longo, descendente |
| `player_revive.ogg` | Player revive (rewarded ad) | Powerup ascendente longo |
| `shop_open.ogg` | Shop abre | UI/Click preset |
| `shop_buy.ogg` | Compra no shop | Pickup preset, agudo |
| `shop_sell.ogg` | Vende arma | Pickup preset, grave |
| `shop_lock.ogg` | Trava/destrava item | Click curto |
| `shop_reroll.ogg` | Reroll de ofertas | Click duplo |
| `ui_click.ogg` | Botão UI genérico | Click preset, curto |

## Pasta Music (`Assets/Audio/Music/<nome>.ogg`)

Tracks de 1-3 minutos com loop seamless. Sugestão: gerar em https://suno.com (Pro $10/mês permite uso comercial). Prompt em inglês.

| Nome do arquivo | Quando toca | Sugestão de prompt Suno |
|-----------------|-------------|---------------------------|
| `main_menu.ogg` | CharacterSelect | "ominous post-apocalyptic synthwave, slow tempo, eerie ambient" |
| `gameplay_normal.ogg` | Wave 1-2 | "tense action synthwave, mid tempo, driving beat, dystopian" |
| `gameplay_intense.ogg` | Wave 3-5 | "frenetic synthwave action, fast tempo, aggressive bass, post-apocalyptic" |
| `boss_theme.ogg` | Boss spawned (wave 5) | "epic boss battle synthwave, dramatic, heavy synths, climactic" |
| `victory.ogg` | WinScreen | "triumphant synthwave finale, uplifting but somber, hero's victory" |
| `game_over.ogg` | DeathScreen | "melancholic synthwave outro, slow, defeated, fading hope" |

## Onde gerar

- **SFX retrô (perfeito pro estilo primitive)**: [sfxr.me](https://sfxr.me) — grátis, web-based, exporta WAV
- **Música IA**: [suno.com](https://suno.com) — Pro $10/mês com licença comercial
- **Free music**: [freepd.com](https://freepd.com) ou [incompetech.com](https://incompetech.com) — CC0/CC-BY
- **Banco de SFX**: [freesound.org](https://freesound.org) — CC0/CC-BY

## Conversão WAV → OGG

WAV pesado, OGG é ideal pra web. No Audacity: File → Export → Export as OGG → Quality 5-7. Ou via ffmpeg:

```
ffmpeg -i input.wav -c:a libvorbis -q:a 5 output.ogg
```

Alvo de tamanho:
- SFX: <50KB cada
- Música: <2MB cada (em 96kbps mono ou 128kbps stereo)
