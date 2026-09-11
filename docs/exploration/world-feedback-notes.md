# World feedback synthesis

The V0.2 world cues are original analytic sine-harmonic synthesis in `scripts/world/world_feedback.gd`, generated once on initialization. No third-party samples, downloads, dependencies, or external assets are used. Existing basic audio remains independent.

Rotor uses a short low resonance; charge rises gently; resume descends slightly. Breeze is silent. Every visual is a short expanding ring or arc from a committed event. Per-kind cooldowns, three mono voices, conservative gain, and finite visual lifetimes bound event bursts. Mute preserves visuals; disabling stops voices and clears transients. Presentation never modifies physics.

Automated waveform and lifecycle tests are in `tests/test_world_feedback.gd`. Actual sound preference and overall experience remain pending user audition; machine checks do not establish listening approval.
