# Accessibility verification evidence template

Use this template to record real manual accessibility runs for release-hardening
issue #7. Keep checklist language aligned with `docs/release-checklist.md`.

- Save each completed run under `docs/release-evidence/` with a dated filename,
  for example `docs/release-evidence/2026-09-07-accessibility.md`.
- Include links to unedited screen recordings, screenshots, or test logs.
- Leave unchecked boxes as blockers. Do not infer a pass from automation.

## Run metadata

- Tester:
- Date:
- App commit SHA:
- Build artifact source (CI run URL + artifact name):
- Notes:

## Android / TalkBack

### Device + OS

- Device model:
- Android version:
- TalkBack version:
- Font scale / display size:
- Reduced motion setting:
- Evidence link(s):

### Checklist

- [ ] First-run, Setup, Due, Upcoming, Completed, and Data screens are announced
      in a logical order with TalkBack enabled.
- [ ] Every icon-only action has a meaningful name; status is conveyed by text or
      icon as well as color.
- [ ] Create/edit, complete, snooze, attach, export, restore, delete, and reset
      flows can be completed without touch exploration traps.
- [ ] Camera, notifications, and file-picker denial return focus to useful app
      content and leave core due/history behavior available.
- [ ] 200% font size and Display size Large do not clip essential content.
- [ ] Interactive targets are at least 48 logical pixels and switch/keyboard
      focus order matches reading order.
- [ ] Remove animations is respected; no task depends on motion.

## iOS / VoiceOver

### Device/simulator + OS

- Device or simulator model:
- iOS version:
- VoiceOver settings:
- Dynamic Type size:
- Reduce Motion setting:
- Evidence link(s):

### Checklist

- [ ] Primary and destructive flows have logical VoiceOver labels, values,
      hints, headings, and traversal order.
- [ ] Dynamic Type at an accessibility size preserves readable, operable layouts
      without clipped essential text.
- [ ] Camera/photo/file and notification denial return focus predictably and do
      not block the local due list.
- [ ] Button targets meet 44-by-44-point guidance and hardware-keyboard focus is
      visible and ordered.
- [ ] Reduce Motion is respected; status never relies on color alone.

## Result summary

- [ ] Android TalkBack run completed and all checks passed.
- [ ] iOS VoiceOver run completed and all checks passed.
- [ ] Remaining blockers (if any):
