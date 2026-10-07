# Frozen Spektrafilm catalogue reference

`SpektraFilmPlugin.cpp` is an unmodified, byte-preserving copy of `src/SpektraFilmPlugin.cpp` from [chaert-s/spektrafilm-ofx](https://github.com/chaert-s/spektrafilm-ofx), commit **86476afc5b077de77e2278e3658d1ba9309892a1**, inspected on 7 October 2026. SHA-256: `139156d814b7a8b932f11e67d67b3106e6107ec6825e0f1b334abb1f7b775428`.

Upstream Spektrafilm OFX is by Aedan Diez, based on work by Andrea Volpato and Johannes Hanika. The upstream `LICENSE.txt` and `Legal/SPEKTRAFILM_OFX_LICENSE.txt` are included unchanged and provide the GNU General Public License, version 3, and upstream source/binary licensing clarification. Retain this attribution and these licenses when redistributing the reference.

This file is an audit input, not an additional compiled plugin target. `profiles/tools/generate_profiles.py` extracts the frozen descriptor catalogue from it, so catalogue regeneration and checks require neither an ignored research checkout nor network access. The community sibling's compiled source lives under `plugin/`; its live OFX descriptors remain authoritative for actual controls, bounds, defaults, choice lists and availability.

The generated catalogue records its own normalized-text SHA-256. That hash can differ from a raw-file hash on platforms that normalize line endings. Updating the baseline requires deliberately replacing this reference, recording its commit/license/hash, regenerating profiles and reviewing coverage changes.
