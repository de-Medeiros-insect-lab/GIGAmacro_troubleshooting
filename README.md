# GIGAmacro Troubleshooting Guide

A summary of the problems we have solved with the **GIGAmacro** macro-imaging system at
the Field Museum (de Medeiros Lab), 2024–2026, drawn from our support correspondence with
GIGAmacro and day-to-day use. A few problems are still open; those are marked
**Unresolved**.

The system is a motorized **X/Y/Z stage** carrying a **DSLR + macro or telecentric lens
and a flash powered from the control box**, driven by two Windows programs:

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

Entries marked **Unresolved** were reported to GIGAmacro but have no confirmed fix in the
record; they list what is known and what to collect if it happens again.

---

## Quick reference

| Symptom | Most likely cause | Go to |
|---|---|---|
| Takes one photo at startup, then live view fails / test photos do nothing / capture "sticks" at the first position; console says `mxj: could not find Java 2 Runtime Environment` | Max can't find Java: the `CurrentVersion` registry value was lost in an automatic Java update | [1.1](#11-capture-wont-take-photos--sticks-at-the-first-position-java--openjdk) |
| Capture app won't start, no "test port" screen, Max console stalls | Unresolved — seen after IT changed accounts/Windows edition | [1.2](#12-capture-app-wont-start-properly-after-it-changes) |
| A shot from DSLR Remote works, but Capture won't drive a run | Capture ↔ camera link (Java, USB, or a competing session) | [1.1](#11-capture-wont-take-photos--sticks-at-the-first-position-java--openjdk), [2.1](#21-intermittent-camera-connection--capture-freezes-competing-session), [2.2](#22-intermittent-usb-dropouts-keyboard-also-cuts-out) |
| Test images seem to vanish | High-Speed Mode writes them to `highspeedtemp` | [1.3](#13-test-images-appear-missing-in-high-speed-mode) |
| Intermittent camera disconnects; capture freezes mid-run | A second user/session has the software open **or** flaky USB | [2.1](#21-intermittent-camera-connection--capture-freezes-competing-session), [2.2](#22-intermittent-usb-dropouts-keyboard-also-cuts-out) |
| DSLR Remote error "cannot write photo" / can't create folders | New-user DSLR Remote configuration step missed | [2.3](#23-dslr-remote-cannot-write-the-photo--cannot-create-folders) |
| Home position wrong after restart | Readout not synced to the controller until you jog | [3.1](#31-home-position-resets-on-software-restart) |
| New users keep hitting the Z limits | Limit-switch wear / spares needed | [3.2](#32-users-hit-the-z-limits--limit-switch-wear) |
| Negative number of rows; camera only moves on Z | Possibly reversed boundaries (unconfirmed) | [3.3](#33-negative-row-count--camera-only-moves-on-z) |
| Blurry/doubled stacks; machine drifts in X/Y while stacking | Unresolved — collect logs | [3.4](#34-xy-drift-during-stacking) |
| Flash not firing at all | Dead flash **or** no power from the control box/adapter | [4.1](#41-flash-not-firing) |
| Flash skips an image or two on long runs | Flash model QC | [4.2](#42-flash-misfires-on-long-runs) |
| Lighting inconsistent / shutter visible in frame | Shutter speed above flash sync | [4.4](#44-inconsistent-lighting--shutter-visible-shutter-sync) |
| Stitch puts tiles in the wrong order | Unresolved | [6.1](#61-tiles-stitched-in-the-wrong-order) |
| PTGui crashes partway through a batch | GPU error, possibly random | [6.2](#62-ptgui-crashes-mid-batch-gpu) |
| PTGui "license expired" | Yearly license lapsed | [6.3](#63-ptgui-license-expired) |

---

## Before you start

A few habits that make every problem below faster to solve:

1. **One user at a time.** Only **one** Windows user should have the GIGAmacro software
   (Capture *and* DSLR Remote) open at once. A second session left open in the background
   has made the camera connection unstable — see
   [2.1](#21-intermittent-camera-connection--capture-freezes-competing-session).
2. **Capture the log first.** Open the **Max console viewer** from the app menu, copy the
   contents, and paste them into a text file (e.g. `YYYYMMDD_gigamacro_log.txt`) **before**
   restarting. The Java failure in [1.1](#11-capture-wont-take-photos--sticks-at-the-first-position-java--openjdk)
   was diagnosed from this log, and support asks for it.
3. **The MaxRT runtime file sometimes fails to save.** If "max runtime" won't save, copy
   the information into Notepad so it isn't lost.
4. **Installers are local.** GIGAmacro keeps the software installers on the machine under
   **`C:\gigamacro\`** (look for the *software installers* folder). If you need a fresh
   copy and it isn't there, ask GIGAmacro support for the link.
5. **Isolate the layer.** If **a shot taken directly in DSLR Remote works**, the camera and
   its connection are fine and the problem is on the **GIGAmacro Capture** side (Java, USB
   to the control box, a competing session, or the project).

---

## 1. Capture software & computer

### 1.1 Capture won't take photos / "sticks" at the first position (Java / OpenJDK)

**Symptoms**
- Capture takes a **single image on startup**, then **live view won't open**, **test
  photos do nothing**, and a project run **moves to the first position and stays there
  forever**.
- A shot taken **directly from DSLR Remote still works**.
- The Max console log shows:
  ```
  mxj: could not find Java 2 Runtime Environment.
  (mxj) mxj_platform_init failed. Could not initialize the Java Runtime Environment.
  newobj: shell: No such object
  ```

**Cause** — Java is usually **still installed**; Max just **can't find it**. Max's Java
bridge (`mxj`) locates Java through the registry: it reads
`HKLM\SOFTWARE\JavaSoft\Java Runtime Environment\CurrentVersion` (normally `1.8`) and follows
that subkey to `jvm.dll`. On this machine centrally managed patching upgrades OpenJDK
(Eclipse Temurin JRE 8) automatically about once a month, and an upgrade can leave the `1.8` subkey in place but **drop the `CurrentVersion`
value**. Without it, `mxj` fails. On Windows, Capture's `shell` object is itself a Java
class (`shell.class`, loaded through `mxj`), and it is what runs `DSLRRemoteTest.exe` to fire
the camera. So the capture commands are printed in the console but **never executed**, and
no photos are taken. (The one photo at startup is triggered by the control box, not by
`shell`.)

Seen twice in 2026, each a few days after an automatic Java update: 8/25 update → failed
8/31, and 11/10 update → failed 11/16. Java is **not** being removed: the MSI logs show no
removal of Java, and `java -version` works throughout.

**Diagnose** (any terminal):
```
reg query "HKLM\SOFTWARE\JavaSoft\Java Runtime Environment" /v CurrentVersion
```
If it says it is *unable to find the specified registry key or value*, this is the problem.

**Fix** — In a **Command Prompt opened with "Run as administrator"**:
```
reg add "HKLM\SOFTWARE\JavaSoft\Java Runtime Environment" /v CurrentVersion /t REG_SZ /d 1.8 /f
```
Then fully close and reopen GIGAmacro Capture and confirm live view and a test photo work.

**Permanent fix (installed on the imaging PC 2026-11-16)** — A scheduled task,
`\GIGAmacro\Restore JavaSoft CurrentVersion`, runs as SYSTEM **at startup** and **a minute
after any Windows Installer activity** (so right after each automatic Java update). It puts
`CurrentVersion = 1.8` back if the `1.8` key exists. To reinstall it (e.g. on a rebuilt PC),
right-click [`fixes/java-currentversion/setup.cmd`](fixes/java-currentversion/setup.cmd) →
**Run as administrator**. It applies the value, registers the task, tests that the task
restores the value, and writes `setup-cmd.log` next to itself.

**Don't** keep running the bundled `OpenJDK8U-jre_x64_windows_hotspot_8u292b10.msi` from
`C:\gigamacro\`: it fails with error 1603 ("a later version … is already installed") because
the centrally managed Java is newer. That's expected and harmless. Reinstall Java only if it is
really gone (`java -version` fails, or the `1.8` key is missing). Then the installer's
**JavaSoft (Oracle) registry keys** option is the one that matters to Max, not the PATH.

**Quick things to try first**
- **Rename the project** to something short and simple and retry (support's first
  suggestion, before the log pointed at Java).
- Check the **Max console** for errors (see [Before you start](#before-you-start)).

### 1.2 Capture app won't start properly after IT changes

**Unresolved in the record** — support offered a Zoom call; the outcome isn't in the emails.

**Symptoms** — After the machine came back from IT (April 2024: separate Windows users
added for Field Museum logins, Windows 11 Home upgraded to Pro), **GIGAmacro Capture had trouble
starting**, the usual **"test port" screen didn't appear**, and the **Max console stalled
and stopped responding**.

**What to do**
1. Open the **Max console** and look for errors — the first thing support asked for.
2. Confirm Max can still find **Java**: check the `CurrentVersion` registry value (see
   [1.1](#11-capture-wont-take-photos--sticks-at-the-first-position-java--openjdk)).
3. Send the log to support and arrange a call. At the time support also offered a revised
   version of its workflow software (v0.7.2); check you are on a current version.

### 1.3 Test images appear "missing" in High-Speed Mode

**Not a fault.** In **High-Speed Mode**, **all *test* images are written to the
`highspeedtemp` folder**, not to the `testimages` project. If test shots look like they
"disappeared," check `highspeedtemp` first.

### 1.4 High-Speed Mode misreads the buffer

**Symptoms** — In High-Speed Mode, Capture can't reliably read the camera buffer vs. the
output folder, **slows down**, and **reports too many photos in the buffer** when they
have actually already been written to the output folder.

**Unresolved** — reported to support in June 2026 alongside the folder-creation problem in
[2.3](#23-dslr-remote-cannot-write-the-photo--cannot-create-folders); no specific fix was
recorded. If it recurs, save the console log and report it.

### 1.5 Make MaxRT the default for every user

**Goal** — Have every Windows user open **MaxRT** (the runtime) + Capture, not the full
Max editor.

**How** — Set the default app for the **`.maxpat`** file type to **MaxRT**:
- Windows *Default apps* settings, **or**
- Right-click the capture program's **`.maxpat`** file → **Properties** → **Open with** →
  choose **MaxRT**.

This alone may not be enough: in October 2024 the lab had apparently already tried it and
Capture still didn't open properly for other users (an earlier workaround support had
applied for a specific Max version was hard to replicate). If that happens, arrange a call
with support.

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

**Symptoms** — The camera connection fails intermittently and **unplugging and replugging
the control box's USB brings it back**. A tell on this machine: the **keyboard also stops
working** at times and is likewise restored by replugging its USB. That points at the
**USB ports**, not the camera.

**Likely cause** — The computer's **onboard USB ports shutting down intermittently**
(support agreed this could cause it).

**Fix** — Install a dedicated **PCIe USB expansion card** and move the GIGAmacro USB
connections onto it. Support recommended this (Amazon ASIN **B081Y4TK5H**, the card they
use) and has shipped new systems with one for the last couple of years because of mixed
results with onboard USB. Support couldn't promise it would fix it, but since the lab
upgraded the USB ports (2026) the system has run smoothly.

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
2. If the step above is already done: support suspected **default security settings
   limiting the account's privileges**. Compare the failing account against a working one.
3. **Workaround:** manually create the output folder path, then capture.

---

## 3. Motion, axes & limits

### 3.1 Home position resets on software restart

**Symptoms** — "Home" is initialized at **wherever the stage happens to be** when the
software starts, instead of staying constant between sessions.

**Cause (support's explanation)** — On restart, the new Capture version **doesn't update
its position readout to the control box's current coordinates.**

**Workaround** — **Jog any axis once** after launching; the readout then updates to the
real position. Support said they would add this to their bug list.

### 3.2 Users hit the Z limits / limit-switch wear

**Symptoms** — With limits enabled, new users **easily drive into the limits**, raising
concern about mechanical wear.

**Fix** — Replace the **limit switch**. Support calls it about a 5-minute job: **two small
screws per switch.** Support ordered a set of spares for the lab in June 2026; keep them
with the instrument.

### 3.3 Negative row count / camera only moves on Z

**Symptoms** — After setting the capture boundaries, the **grid view shows a *negative*
number of rows**, and when you start a run the **camera only moves on the Z axis** (no
X/Y).

**Unconfirmed cause** — Seen twice in one day (June 2026). Support's guess was **reversed
boundaries** (positive and negative values flipped); the software has logic to prevent that,
and support planned to try to reproduce it. No confirmation is in the record.

**What to do** — Re-set the boundaries and check the row/column counts are positive before
starting. If it happens again, save the Max console log and a screenshot of the grid view
for support. (Possibly related to [3.5](#35-no-grid-shown--camera-moves-sideways-instead-of-imaging).)

### 3.4 X/Y drift during stacking

**Unresolved.**

**Symptoms** — Bad focus stacks from an unattended overnight run (June 2026); the stage
appeared to **move slightly in X and Y while the Z axis moved**.

**What to do** — The cause was not established (support had ideas to test on a call; the
outcome wasn't recorded). If it recurs, **save the Max console log**, note which axes moved
and whether it lines up with Z moves, and send both to support.

### 3.5 No grid shown / camera moves sideways instead of imaging

**Symptoms** — Occasionally, after setting boundaries, Capture **fails to show a grid** and
the camera **moves sideways** instead of running the capture. Hard to reproduce.

**Unresolved** — couldn't be reproduced on the June 2026 support call. If it happens,
**don't just restart**: first **open the Max console viewer, copy the logs, and send them
to support**.

### 3.6 Failing axis stopper

**Symptoms** — The **stopper on one of the axes is failing.**

**Fix** — This is a hardware part; **request a replacement stopper from GIGAmacro support**
and swap it. (Reported for this machine in November 2026 — pending replacement part.)

---

## 4. Flash & lighting

> The flash shipped with the system (a non-Canon model) is powered from the control box
> through a **battery adapter** in its battery compartment; the compartment was modified so
> the door shuts over the cable. The adapter replaces the batteries, so its **orientation and
> polarity matter.** Per support, the Canon flashes have **reverse-polarity protection**, so
> a wrong polarity won't damage them.

### 4.1 Flash not firing

**Symptoms** — The flash doesn't fire at all.

**Cause** — Either the **flash itself is dead**, or **power from the control box/adapter
isn't reaching it** (bad contact or wrong orientation).

**Diagnose & fix — in order**
1. **Reseat the battery adapter.** Reinstall it and **push it firmly** into the flash
   battery compartment; it can lose contact with the battery tabs. Check its orientation
   (when it was reassembled wrongly in 2025, support's correction was to rotate it 180°).
2. **Isolate flash vs. power.** Put **ordinary batteries** in the flash (it still accepts
   them) and test:
   - Flash **fires on batteries** → the flash is fine; the problem is the **power input
     from the control box/adapter**.
   - Flash **still dead on batteries** → the **flash unit is likely dead**; replace it
     (see [4.3](#43-installing--modifying-a-replacement-flash)).

In June 2025 neither step worked, and the flash was replaced.

> 💡 Before dismantling: **photograph the battery compartment.** The power adapter is a
> custom modification and is easy to put back the wrong way.

### 4.2 Flash misfires on long runs

**Symptoms** — The flash **skips an image or two** during a long capture run
(1,000–2,000 photos). Support has seen this on some units of the shipped model; it hasn't
been reported on the lab's machine.

**Cause** — GIGAmacro chose the non-Canon model it shipped because it **holds its settings
when power-cycled**, but **manufacturing quality seems to have dropped** in recent years:
some units miss a flash now and then on long runs, others are fine.

**Fix / options**
- For reliability, move to the **Canon MT-26EX** (more expensive but more dependable; it's
  what GIGAmacro switched back to). A **Canon MT-24EX** also works.
- Keep a **cheap spare** flash of the shipped model on hand as a backup for quick swaps.
- See [4.3](#43-installing--modifying-a-replacement-flash) for the adapter differences
  between models.

### 4.3 Installing / modifying a replacement flash

Getting a new flash onto the system:

- **Modifying the flash is optional.** GIGAmacro grinds the battery compartment (with a
  Dremel sanding disk) so the door shuts over the adapter, but the real requirement is that
  the **adapter sits snug and won't work loose.** A **shim** after installation can hold it
  in place without modifying anything.
- **Adapter orientation/polarity differs between Canon models.** On the adapter, red is
  positive and the black mark is negative. Support sent reference photos of the correct
  orientation for the **MT-26EX** and **MT-24EX** (email, 16 June 2025). Moving an adapter
  to an MT-24EX may require **reversing the polarity**: loosen the two nuts and swap the
  connectors (it's a tight fit; the adapter can be taken apart to make it easier).
- GIGAmacro can **pre-modify a flash and ship it** if you'd rather not do the mechanical
  work.

### 4.4 Inconsistent lighting / shutter visible (shutter sync)

**Symptoms** — Unreliable lighting across frames, or **the shutter visible over the
sensor** in some shots.

**Cause** — **Shutter speed set above the flash sync speed.** If you use **1/250 s**, the
flash may not synchronize.

**Fix** — Keep the **maximum shutter speed at 1/200 s.**

---

## 5. Lens care & lens settings

### 5.1 Smudge / spot on the lens

- Use a proper **lens-cleaning kit** (gentle brush, cleaning solution, microfiber cloth) or
  **Zeiss lens wipes**; wipe **gently**. Try **blown air** first for loose particles.
- If a **stubborn spot survives** cloth + solution + air (as happened on the
  OptoEngineering lens in June 2024), check whether it's on an **interior element** before
  rubbing harder, and use a proper lens-cleaning tool for it.

### 5.2 "Manually adjusted" depth-of-field warning (OptoEngineering lens)

**Not a fault — cosmetic.** Selecting the **OptoEngineering (telecentric) lens** in *Set
Field of View* permanently shows a **"manually adjusted"** warning on the depth of field
(e.g. at 6.200). That lens has a **fixed** depth of field, which the software forces, so it
*thinks* the value was overridden. **The DoF is correct; ignore the warning.** (The warning
is meaningful only for variable lenses such as the Canon MP-E 65 mm.)

---

## 6. Stitching & processing

### 6.1 Tiles stitched in the wrong order

**Unresolved in the record.**

**Symptoms** — April 2024 test run on boxes of beetles: capture was fine, but **stitching
placed tiles in the wrong order** even though the **row/column numbers in the filenames
were correct** (10 rows × 9 columns). Some parallax was also making tiles hard to match.

**What to do** — The emails don't record the cause or fix (it may have been an import
mistake). If it happens, check how the images were imported into the stitcher, then send
support the file list and screenshots of the result.

### 6.2 PTGui crashes mid-batch (GPU)

**Symptoms** — In March 2025 a batch of 10 stitched fine through GIGAmacroFlow; a batch of
18 **got stuck on one of the last projects**, and opening that project manually in
**PTGui** gave a **GPU error**. PTGui was using the right GPU (RTX 4060).

**Cause** — Unclear. Support hadn't seen this error in PTGui before, but has had periodic,
**seemingly random GPU crashes**; other users report GPU issues on the PTGui forum:
<https://groups.google.com/g/ptgui/search?q=gpu>.

**Fix / options**
1. **Retry** the project to see whether it was a fluke.
2. If it persists, **disable GPU acceleration** in PTGui (it will be slower).

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
- Example invocation on a Mac (adjust the path on Windows) that worked well for **flat
  subjects** such as grasshopper wings; untested on more 3-D specimens:

  ```
  /Applications/HeliconFocus.app/Contents/MacOS/HeliconFocus -silent -save:$FILENAME.dng -sort:asc -rp:8 -sp:4 -va:3 -ha:3 -im:2 -dmf:3 -ma:5 -mp:1 $FOLDER
  ```

  where `$FOLDER` holds the source frames and `$FILENAME` is the output name.

### 6.5 In-house batch processing (BulkBug)

The lab also runs an **in-house tool (BulkBug)** that stacks and stitches GIGAmacro
captures and detects insects in bulk-sample trays. Use it as an alternative to the
GIGAmacro desktop workflow for large jobs. (Access is internal to the lab.)

---

## Appendix

### Key locations, software & defaults

| Item | Value |
|---|---|
| Software installers | `C:\gigamacro\` (*software installers* folder) |
| Capture app | GIGAmacro Capture, running on **Max / MaxRT**; project files are `.maxpat` |
| Required runtime | **Java 8** (Eclipse Temurin, kept up to date by central patch management). Max finds it through `HKLM\SOFTWARE\JavaSoft\Java Runtime Environment\CurrentVersion` = `1.8`; the `\GIGAmacro\Restore JavaSoft CurrentVersion` task keeps that set |
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
It records what was tried and what worked, and marks what is still unresolved. It is
**not** an official GIGAmacro manual; when in doubt, capture a log and contact support.
Corrections and new cases welcome — please open an issue or PR.
