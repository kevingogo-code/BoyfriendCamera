# Design QA

## Comparison target

- Source visual truth: `/Users/didi/Documents/Hackathon/BoyfriendCamera/原型图/`
- Rendered implementation: `/Users/didi/Documents/Hackathon/BoyfriendCamera/test/goldens/`
- Side-by-side evidence: `/Users/didi/Documents/Hackathon/BoyfriendCamera/test/goldens/compare-*.png`
- States: 启动引导、首页、场景选择、拍照界面、拍摄完成、智能选片、相册、我的、照片详情
- Viewports: each implementation was rendered at the exact pixel size of its source image (375×733, 375×812, 375×981, 375×1014, or 375×1121).

## Full-view comparison evidence

All nine source images were paired side by side with their Flutter-rendered equivalents. The final pass confirms the same information hierarchy, screen order, primary-region proportions, navigation placement, card structure, grid density, blue/green/orange semantic colors, corner radii, and core copy.

## Focused-region comparison evidence

- Camera: compared the 326×438 viewfinder, rule-of-thirds grid, blue corner marks, pose rail, instruction pill, shutter, gallery target, and 0/5 counter.
- Home and album: compared two-column and three-column image grids, section spacing, chip states, summary copy, and bottom navigation.
- Completion and selection: compared classification rows, thumbnail strip, tabs, selection controls, recommendation labels, and fixed bottom action bar.
- Detail and profile: compared score placement, metric hierarchy, settings rows, switches, stats card, and action labels.

## Required fidelity surfaces

- Fonts and typography: Chinese text was rendered with a loaded system Chinese font for QA; sizes, weights, line hierarchy, wrapping, and truncation match the prototypes. Production uses the platform Chinese font fallback, so small optical differences across Android vendors are expected.
- Spacing and layout rhythm: source-specific viewport heights were matched; major regions align without overflow or clipped persistent controls.
- Colors and tokens: primary blue, recommendation green, backup orange, light-gray fills, borders, dark camera surfaces, and disabled states use shared app tokens.
- Image quality and asset fidelity: real captured photos are used when available; prototype gray image states are preserved for empty/loading states. Existing transparent pose assets are limited to suggestion thumbnails and are no longer overlaid on the live preview.
- Copy and content: visible product copy follows the supplied prototype and the revised principle of five-shot efficiency and lightweight two-sided guidance.
- Icons: Material icons were loaded into the renderer and checked for semantic and optical consistency with the prototype.
- Accessibility and resilience: primary controls use semantic Flutter buttons and practical tap targets; all tested target viewports render without overflow.

## Comparison history

### Iteration 1

- [P1] Camera preview and control-region proportions differed from the 375×812 source.
- [P2] Pose rail overflowed vertically by 10 px.
- [P2] Home and scene pages were initially compared at the wrong source heights.
- Fixes: set source-specific viewports; matched camera regions to 60/438/123/42/149 px; corrected pose rail padding and item height.
- Post-fix evidence: `compare-camera.png`, `compare-home.png`, and `compare-scene-selection.png`.

### Iteration 2

- [P2] Smart-selection tabs overflowed horizontally by 12 px.
- [P2] Home photo cells were too short and photo-detail score content sat too high.
- [P2] Capture-complete content began above the prototype rhythm.
- Fixes: equal-width tabs; corrected grid aspect ratio; matched photo-detail image region; shifted completion content; added explicit empty-photo surfaces.
- Post-fix evidence: `compare-smart-selection.png`, `compare-photo-detail.png`, `compare-capture-complete.png`.

### Final pass

No actionable P0, P1, or P2 visual findings remain. A P3 difference remains acceptable: exact Chinese glyph metrics can vary between the QA font and individual Android system fonts.

## Primary interactions checked

- Bottom navigation switches among 拍照、相册、我的.
- Scene chips update the selected scene; tapping the active scene opens full scene selection.
- Scene selection cards and confirmation return a manual override.
- Camera pose suggestions switch without showing a live silhouette overlay.
- Five-shot capture session returns to the completion flow; early finish is available after the first shot.
- Smart-selection categories, selection states, select-all, and save action are interactive.
- Profile switches update locally.
- Empty-camera error state and retry action render correctly.

## Residual test gap

The Android device was not connected during the final pass, so camera hardware, gallery permission, live ML inference cadence, and vendor-specific system-font rendering still require a real-device smoke test. This does not block the rendered design comparison or the successful Android build.

final result: passed
