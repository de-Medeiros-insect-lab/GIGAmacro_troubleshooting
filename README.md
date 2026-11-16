# GIGAmacro Troubleshooting Guide

Practical troubleshooting notes for the de Medeiros Lab / Field Museum **GIGAmacro**
macro-imaging system. The entries below are distilled from several years of support
correspondence with GIGAmacro and from problems the lab has hit and solved
in day-to-day use (2024–2026).

The system is a motorized **X/Y/Z stage** carrying a **DSLR + macro or telecentric lens
and a ring/twin flash**, driven by two Windows programs:

- **GIGAmacro Capture** — the motion-control + capture app, built in **Max / MaxRT**
  (Cycling '74 Max runtime). This is what plans the grid and drives the stage.
- **DSLR Remote Pro** (Breeze Systems) — tethered camera control; it actually fires the
  camera and writes the image files.

Downstream, tiles are **focus-stacked** (Helicon Focus / Zerene) and **stitched** into a
gigapixel mosaic (**PTGui**, usually wrapped by **GIGAmacroFlow**). The lab also has an
in-house stack/stitch/metadata tool (**BulkBug**) for batch processing.

> ⚠️ **Most failures here are silent or intermittent.** When something misbehaves, your
> single most useful action is to **open the Max console viewer, copy the log, and save
> it** before you close or restart anything — see [Before you start](#before-you-start).

---

## Quick reference

| Symptom | Most likely cause | Go to |
|---|---|---|
| Takes one photo at startup, then live view fails / test photos do nothing / capture "sticks" at the first position | Java (OpenJDK) runtime missing | [1.1](#11-capture-wont-take-photos--sticks-at-the-first-position-java--openjdk) |
| Capture app won't start, no "test port" screen, Max console stalls | Software/environment broken (often right after IT updates) | [1.2](#12-capture-app-wont-start-properly-often-after-it-updates) |
| A shot from DSLR Remote works, but Capture won't drive a run | Capture ↔ camera link (Java, USB, or a competing session) | [1.1](#11-capture-wont-take-photos--sticks-at-the-first-position-java--openjdk), [2.1](#21-intermittent-camera-connection--capture-freezes-competing-session), [2.2](#22-intermittent-usb-dropouts-keyboard-also-cuts-out) |
| Test images seem to vanish | High-Speed Mode writes them to `highspeedtemp` | [1.3](#13-test-images-appear-missing-in-high-speed-mode) |
| Intermittent camera disconnects; capture freezes mid-run | A second user/session has the software open **or** flaky USB | [2.1](#21-intermittent-camera-connection--capture-freezes-competing-session), [2.2](#22-intermittent-usb-dropouts-keyboard-also-cuts-out) |
| DSLR Remote error "cannot write photo" / can't create folders | New-user config step missed + folder permissions | [2.3](#23-dslr-remote-cannot-write-the-photo--cannot-create-folders) |
| Home position wrong after restart | Readout not synced to the controller until you jog | [3.1](#31-home-position-resets-on-software-restart) |
| New users keep hitting the Z limits | Limit-switch wear / spares needed | [3.2](#32-users-hit-the-z-limits--limit-switch-wear) |
| Negative number of rows; camera only moves on Z | Capture boundaries reversed | [3.3](#33-negative-row-count--camera-only-moves-on-z) |
| Blurry/doubled stacks; machine drifts in X/Y while stacking | Mechanical drift during Z moves | [3.4](#34-xy-drift-during-stacking) |
| Flash not firing at all | Dead flash **or** no power from the control box/adapter | [4.1](#41-flash-not-firing) |
| Flash skips an image or two on long runs | Flash model QC | [4.2](#42-flash-misfires-on-long-runs) |
| Lighting inconsistent / dark band across frame | Shutter speed above flash sync | [4.4](#44-inconsistent-lighting--dark-band-shutter-sync) |
| Stitch puts tiles in the wrong order | Import order / naming not honored | [6.1](#61-tiles-stitched-in-the-wrong-order) |
| PTGui crashes partway through a batch | Random GPU crash | [6.2](#62-ptgui-crashes-mid-batch-gpu) |
| PTGui "license expired" | Yearly license lapsed | [6.3](#63-ptgui-license-expired) |

---

## Before you start

A few habits that make every problem below faster to solve:

1. **One user at a time.** Only **one** Windows user should have the GIGAmacro software
   (Capture *and* DSLR Remote) open at once. A second session left open in the background
   is a frequent, confusing cause of "the camera keeps disconnecting" — see
   [2.1](#21-intermittent-camera-connection--capture-freezes-competing-session).
2. **Capture the log first.** Open the **Max console viewer** from the app menu, copy the
   contents, and paste them into a text file (e.g. `YYYYMMDD_gigamacro_log.txt`) **before**
   restarting. Java/runtime errors and motion errors show up here, and support needs them.
3. **The MaxRT runtime file sometimes fails to save.** If "max runtime" won't save, copy
   the information into Notepad so it isn't lost.
4. **Installers are local.** GIGAmacro keeps the software installers on the machine under
   **`C:\gigamacro\`** (look for the *software installers* folder). If you need a fresh
   copy and it isn't there, ask GIGAmacro support for the link.
5. **Isolate the layer.** A quick test: if **a single shot taken directly in DSLR Remote
   works**, the camera, lens and flash are basically fine and the problem is in the
   **Capture/motion/stack** layer (Java runtime, USB, a competing session, or the project).

---

## 1. Capture software & computer

### 1.1 Capture won't take photos / "sticks" at the first position (Java / OpenJDK)

**Symptoms**
- Capture takes a **single image on startup**, then **live view won't open**, **test
  photos do nothing**, and a project run **moves to the first position and stays there
  forever**.
- A shot taken **directly from DSLR Remote still works**.
- The Max console log may show **JavaScript / Java runtime errors**.

**Cause** — The **Java runtime (OpenJDK)** that GIGAmacro Capture needs is **not installed
/ was removed**. This has recurred several times on this machine.

**Fix**
1. Reinstall **OpenJDK** from the installer in **`C:\gigamacro\`** (*software installers*
   folder). If it isn't there, request the OpenJDK installer from GIGAmacro support.
2. **During install, tick the option to add Java to the environment (PATH).** The runtime
   is useless to Capture if it isn't on the PATH — this checkbox is the step people miss.
3. Restart GIGAmacro Capture and confirm live view and a test photo work before running a
   project.

**Quick things to try first**
- **Rename the project** to something short and simple and retry (a known quick check from
  support).
- Check the **Max console** for errors (see [Before you start](#before-you-start)).

> 🔎 **Why it keeps coming back.** On this machine the OpenJDK removal is caused by
> **automated updates running in the background** on the computer, which remove or break
> the OpenJDK install — so the problem **recurs** even after a clean reinstall.
> Reinstalling OpenJDK (above) is the **interim fix**; the **durable fix** is to stop the
> automated updates from removing it, which is being worked on separately. If you hit this,
> reinstall, confirm Java is present and on PATH (`java -version` in a terminal), and note
> the date so the recurrences can be tracked.

### 1.2 Capture app won't start properly (often after IT updates)

**Symptoms** — After the machine comes back from IT (new user accounts, Windows edition
change, security updates, etc.), **GIGAmacro Capture won't start up properly**, the usual
**"test port" screen doesn't appear**, and/or the **Max console stalls and stops
responding**.

**Cause** — An OS/account/environment change broke the software's assumptions. On this
machine it has followed IT work such as adding Field-Museum-linked user accounts and
upgrading Windows 11 Home → Pro. The underlying trigger is frequently the same missing
Java runtime as [1.1](#11-capture-wont-take-photos--sticks-at-the-first-position-java--openjdk),
or per-user privileges.

**Fix / how to diagnose**
1. Open the **Max console** and look for errors as it starts (this is the first thing
   support checks).
2. Confirm the **Java/OpenJDK** runtime is still installed and on PATH (see
   [1.1](#11-capture-wont-take-photos--sticks-at-the-first-position-java--openjdk)).
3. Check that the problem user has the needed **privileges** and the **same software
   setup** as a known-good user (see [2.3](#23-dslr-remote-cannot-write-the-photo--cannot-create-folders)
   and [1.5](#15-make-maxrt-the-default-for-every-user)).
4. If it persists, grab the console log and set up a screen-share with support — these are
   usually resolved live rather than by a single setting.

### 1.3 Test images appear "missing" in High-Speed Mode

**Not a fault.** In **High-Speed Mode**, **all *test* images are written to the
`highspeedtemp` folder**, not to the `testimages` project. If test shots look like they
"disappeared," check `highspeedtemp` first.

### 1.4 High-Speed Mode misreads the buffer

**Symptoms** — In High-Speed Mode, Capture can't reliably read the camera buffer vs. the
output folder, **slows down**, and **reports too many photos in the buffer** when they
have actually already been written to the output folder.

**Notes** — Known quirk. Make sure the output folder is writable and uncluttered (see
[2.3](#23-dslr-remote-cannot-write-the-photo--cannot-create-folders)); if it's blocking
work, drop out of High-Speed Mode and report it to support with a console log.

### 1.5 Make MaxRT the default for every user

**Goal** — Have every Windows user open **MaxRT** (the runtime) + Capture, not the full
Max editor.

**How** — Set the default app for the **`.maxpat`** file type to **MaxRT**:
- Windows *Default apps* settings, **or**
- Right-click the capture program's **`.maxpat`** file → **Properties** → **Open with** →
  choose **MaxRT**.

If a particular user still can't open Capture the way others can, it's usually a per-user
setup/permissions gap — compare against a known-good account.

---

## 2. Camera connection & USB

### 2.1 Intermittent camera connection / capture freezes (competing session)

**Symptoms** — The camera connection drops or the capture freezes partway through, often
with no obvious trigger.

**Cause #1 (check this first)** — **Another user still has GIGAmacro software open.** If a
second Windows user has a **DSLR Remote session running in the background**, it competes
for the camera. **Only one user may have the GIGAmacro software open at a time.**

**Fix** — Make sure no other account has Capture or DSLR Remote open (log out other
sessions entirely, not just switch users), then reconnect.

If that's not it, go to [2.2](#22-intermittent-usb-dropouts-keyboard-also-cuts-out).

### 2.2 Intermittent USB dropouts (keyboard also cuts out)

**Symptoms** — Camera/stage connection drops intermittently; the problem **comes back
after unplugging and replugging USB**. A strong tell on this machine: the **keyboard also
stops working** and is restored by replugging USB. That points at the **USB ports**, not
the camera.

**Cause** — The computer's **onboard USB controller is shutting down intermittently.**

**Fix** — Install a dedicated **PCIe USB expansion card** and move the GIGAmacro (and
other) USB connections onto it. GIGAmacro now ships machines with such a card for exactly
this reason. (A card equivalent to Amazon ASIN **B081Y4TK5H** is the one support has
recommended/used.) After upgrading the USB ports this instability has stayed away in
practice.

> If you don't have the card yet and need to keep working, unplugging/replugging the USB
> temporarily clears it — but that's a stopgap, not a fix.

### 2.3 DSLR Remote: "cannot write the photo" / cannot create folders

**Symptoms** — **DSLR Remote Pro throws a "cannot write photo" error even on *test*
photos.** The real problem is that it **can't create the output *folder***: if you
**manually create the folder path first, the photos then save fine**. It typically works
for already-set-up users but fails for **new users**.

**Causes & fixes**
1. **Missed DSLR Remote configuration step for new users.** There is a DSLR Remote
   configuration step that must be done when setting up a new user; if it's skipped, saving
   photos fails. Follow the new-user setup checklist (kept in the lab's *new users*
   materials) and make sure this step is applied for the account that's failing.
2. **Folder permissions / default security settings** on the account can prevent folder
   creation. Compare the failing account against a working one; grant the user write access
   to the capture output location.
3. **Workaround:** manually create the output folder path, then capture.

---

## 3. Motion, axes & limits

### 3.1 Home position resets on software restart

**Symptoms** — "Home" is initialized at **wherever the stage happens to be** when the
software starts, instead of staying constant between sessions.

**Cause** — On restart, the new Capture version **doesn't automatically sync its on-screen
readout to the controller's current coordinates.**

**Fix / workaround** — **Jog any axis once** after launching; the position readout then
updates to the real controller position. (Known software quirk on GIGAmacro's bug list.)

### 3.2 Users hit the Z limits / limit-switch wear

**Symptoms** — With limits enabled, new users **easily drive into the limits**, raising
concern about mechanical wear.

**Fix** — Replace a worn/failing **limit switch**. It's a quick job: **two small screws
per switch.** Keep **spares on hand** (support has shipped spares from Amazon). Train new
users on safe jogging so they stop short of the limits.

### 3.3 Negative row count / camera only moves on Z

**Symptoms** — After setting the capture boundaries, the **grid view shows a *negative*
number of rows**, and when you start a run the **camera only moves on the Z axis** (no
X/Y).

**Cause** — The **capture boundaries are reversed** (min/max, i.e. positive/negative
values, flipped). The software has logic to catch reversed boundaries but it can still slip
through.

**Fix** — Re-set the boundaries, making sure the start/end corners are in the correct order
so the row/column counts come out positive.

### 3.4 X/Y drift during stacking

**Symptoms** — Focus stacks come out blurred/doubled; on inspection the **stage drifts
slightly in X and Y while the Z axis is moving** during a stack. Worst on unattended
overnight runs.

**How to diagnose** — This is mechanical. If it recurs, **open the Max console viewer, copy
the logs, and send them to support** so the motion can be reviewed. Note which axis/axes
and whether it correlates with Z moves.

### 3.5 No grid shown / camera moves sideways instead of imaging

**Symptoms** — Occasionally, after setting boundaries, Capture **fails to show a grid** and
the camera **moves sideways** instead of running the capture. Hard to reproduce.

**What to do** — If it happens, **don't just restart** — first **open the Max console
viewer, copy the logs, and send them to support** so they can diagnose a transient that
otherwise disappears. (Related to the reversed-boundary behavior in
[3.3](#33-negative-row-count--camera-only-moves-on-z).)

### 3.6 Failing axis stopper

**Symptoms** — A mechanical **stopper on one of the axes fails/loosens.**

**Fix** — This is a hardware part; **request a replacement stopper from GIGAmacro support**
and swap it. (Reported for this machine in November 2026 — pending replacement part.)

---

## 4. Flash & lighting

> The GIGAmacro flash is a Canon-style macro twin/ring flash whose **battery compartment is
> modified** so it can be powered from the control box through an adapter. Because the
> adapter replaces the batteries, **orientation and polarity of the adapter matter.** The
> flash has **reverse-polarity protection**, so you **cannot damage it** by experimenting
> with adapter orientation.

### 4.1 Flash not firing

**Symptoms** — The flash doesn't fire at all.

**Cause** — Either the **flash itself is dead**, or **power from the control box/adapter
isn't reaching it** (bad contact or wrong orientation).

**Diagnose & fix — in order**
1. **Reseat the battery adapter.** Reinstall it and **push it firmly** into the flash
   battery compartment; it can lose contact with the battery tabs. Correct adapter
   orientation is usually **rotated 180°** from the "obvious" way — and because of the
   reverse-polarity protection, getting it backwards won't hurt anything.
2. **Isolate flash vs. power.** Put **ordinary batteries** in the flash (it still accepts
   them) and test:
   - Flash **fires on batteries** → the flash is fine; the problem is the **power input
     from the control box/adapter** (contact, adapter, or cable).
   - Flash **still dead on batteries** → the **flash unit is likely dead**; replace it
     (see [4.3](#43-installing--modifying-a-replacement-flash)).

> 💡 Before dismantling: **note the orientation of everything** in the battery
> compartment (photograph it). The power adapter is a custom modification and is easy to
> misremember when reassembling.

### 4.2 Flash misfires on long runs

**Symptoms** — The flash **skips an image or two** across a long capture run
(~1,000–2,000 photos); lighting is inconsistent on a handful of frames.

**Cause** — The non-Canon flash model GIGAmacro historically shipped was chosen because it
**holds its settings when power-cycled**, but **manufacturing quality dropped** in recent
years and some units intermittently miss a flash on long runs (others are fine — it's
unit-to-unit).

**Fix / options**
- For reliability, move to the **Canon MT-26EX** (more expensive but more dependable; it's
  what GIGAmacro switched back to). A **Canon MT-24EX** also works.
- Keep a **cheap spare** flash of the shipped model on hand as a backup for quick swaps.
- See [4.3](#43-installing--modifying-a-replacement-flash) for the adapter differences
  between models.

### 4.3 Installing / modifying a replacement flash

Getting a new flash onto the system:

- **You don't necessarily have to dremel the doors.** The historical mod grinds the battery
  door (e.g. with a Dremel sanding disk) so it closes over the adapter — but the real
  requirement is that the **adapter sits snug and won't work loose.** A **shim** after
  installation can hold it in place without modifying the door.
- **Adapter orientation/polarity differs by model.** Match the adapter to the flash:
  - **MT-26EX** — install the battery adapter in that model's orientation (red = positive,
    black-marked = negative).
  - **MT-24EX** — orientation differs; you may need to **reverse the polarity** on an
    existing adapter (loosen the two nuts and reverse the connectors; the adapter comes
    apart to make this easier). Reverse-polarity protection means a wrong guess is safe.
- GIGAmacro can **pre-modify a flash and ship it** if you'd rather not do the mechanical
  work.

### 4.4 Inconsistent lighting / dark band (shutter sync)

**Symptoms** — Unreliable lighting across frames, or a **view of the shutter/dark band
over the sensor** in some shots.

**Cause** — **Shutter speed set above the flash sync speed.** If you use **1/250 s**, the
flash may not synchronize.

**Fix** — Keep the **maximum shutter speed at 1/200 s.**

---

## 5. Lens care & lens settings

### 5.1 Smudge / spot on the lens

- Use a proper **lens-cleaning kit** (gentle brush, cleaning solution, microfiber cloth) or
  **Zeiss lens wipes**; wipe **gently**. Try **blown air** first for loose particles.
- If a **stubborn spot survives** cloth + solution + air, it may be on an **interior
  element** — don't force it. Stop and ask for the right tool / support rather than
  scrubbing a coated or telecentric element.

### 5.2 "Manually adjusted" depth-of-field warning (OptoEngineering lens)

**Not a fault — cosmetic.** Selecting the **OptoEngineering (telecentric) lens** in *Set
Field of View* permanently shows a **"manually adjusted"** warning on the depth of field
(e.g. at 6.200). That lens has a **fixed** depth of field, which the software forces, so it
*thinks* the value was overridden. **The DoF is correct; ignore the warning.** (The warning
is meaningful only for variable lenses such as the Canon MP-E 65 mm.)

---

## 6. Stitching & processing

### 6.1 Tiles stitched in the wrong order

**Symptoms** — Capture and stacking succeed, but **stitching places tiles in the wrong
order**, even though the **row/column numbers in the filenames are correct** (e.g. a 10×9
grid comes out scrambled).

**How to diagnose / fix**
- Confirm the stitcher is actually **reading tile positions from the filenames** (correct
  row/column convention) rather than import order; re-import honoring the naming.
- Rule out overlap problems from **parallax** (see note below) vs. a true ordering bug.
- If the order is still wrong with correct names, send the file list + a screenshot to
  support; this has been reported and worked through with GIGAmacro.
- **Parallax tip:** some tile mismatch is parallax at tile edges — maximize overlap and
  keep specimens within the usable (flatter) center of the field to reduce it.

### 6.2 PTGui crashes mid-batch (GPU)

**Symptoms** — A batch stitches fine for a while (small batches are OK), then **gets stuck
on one project**; opening that project manually in **PTGui** throws a **GPU-related
error/crash**. PTGui is using the correct GPU (e.g. an RTX 4060).

**Cause** — **Random/intermittent GPU crashes** in PTGui — a known, seemingly random issue
(others report it on the PTGui forum: <https://groups.google.com/g/ptgui/search?q=gpu>).

**Fix / options**
1. **Retry** the failed project — it's often a one-off fluke.
2. If it recurs, **disable GPU acceleration** in PTGui and stitch on CPU (slower but
   stable).
3. Keep batches moderate so one bad project doesn't stall a long queue.

### 6.3 PTGui "license expired"

**Symptoms** — Stitching stops with a **"license expired"** error in PTGui.

**Cause** — The PTGui license in use is a **yearly** license that lapsed.

**Fix** — Renew, or buy the **perpetual license** option: <https://ptgui.com/order.html>.
(For a long-lived instrument the perpetual license is usually the better buy.)

### 6.4 Focus stacking settings (Helicon Focus, raw → DNG)

For command-line focus stacking with **Helicon Focus** writing a DNG (one approach the lab
has used):

- Background on raw-in/DNG-out: <https://www.heliconsoft.com/raw-in-dng-out/> and
  <https://www.heliconsoft.com/adobedng/> (install the **Adobe DNG Converter**).
- CLI reference:
  <https://www.heliconsoft.com/focus/help/english/HeliconFocus.html#HF_COM_LINE>.
- Example invocation (macOS paths; adapt per machine) that worked well for **flat
  subjects** such as grasshopper wings — expect to tune for more 3-D structures:

  ```
  HeliconFocus -silent -save:$FILENAME.dng -sort:asc -rp:8 -sp:4 -va:3 -ha:3 -im:2 -dmf:3 -ma:5 -mp:1 $FOLDER
  ```

  where `$FOLDER` holds the source frames and `$FILENAME` is the output name.

### 6.5 In-house batch processing (BulkBug)

The lab also runs an **in-house tool (BulkBug)** that stacks, stitches, and adds scale
bars/metadata to GIGAmacro folders in batch, and can be adapted (together with
**DrawerDissect**) to detect specimens in trays. Use it as an alternative/complement to the
GIGAmacro desktop workflow for large jobs. (Details and access are internal to the lab.)

---

## Appendix

### Key locations, software & defaults

| Item | Value |
|---|---|
| Software installers | `C:\gigamacro\` (*software installers* folder) |
| Capture app | GIGAmacro Capture, running on **Max / MaxRT**; project files are `.maxpat` |
| Required runtime | **Java / OpenJDK** — must be installed **and on PATH** |
| Camera control | **DSLR Remote Pro** (Breeze Systems) |
| Stitching | **PTGui** (often via **GIGAmacroFlow**) |
| Focus stacking | **Helicon Focus** / Zerene |
| Max shutter speed (flash sync) | **1/200 s** (not 1/250) |
| Test images in High-Speed Mode | `highspeedtemp` folder |
| Concurrency rule | **One** user with GIGAmacro software open at a time |
| USB reliability | Use a **PCIe USB card**, not onboard ports (ASIN B081Y4TK5H) |

### Getting the log for support

1. Open the **Max console viewer** from the app menu.
2. Select all, copy, and paste into a text file named e.g. `YYYYMMDD_gigamacro_log.txt`.
3. Note what you were doing, the user account, and whether a **direct DSLR Remote shot**
   works.
4. Send it to GIGAmacro support.

### Support contact

- **GIGAmacro support**, via <https://www.gigamacro.com/> (support troubleshoots over
  video calls).

### About this guide

Compiled 2026-11-16 from GIGAmacro support correspondence and lab experience (2024–2026).
It records real fixes but is **not** an official GIGAmacro manual; when in doubt, capture a
log and contact support. Corrections and new cases welcome — please open an issue or PR.
