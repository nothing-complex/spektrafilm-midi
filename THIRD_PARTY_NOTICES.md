# Third-party notices and provenance

## Spektrafilm OFX

The `plugin/` tree derives from [chaert-s/spektrafilm-ofx](https://github.com/chaert-s/spektrafilm-ofx), commit `86476afc5b077de77e2278e3658d1ba9309892a1`. Spektrafilm OFX is by Aedan Diez, based on work by Andrea Volpato and Johannes Hanika.

Retained upstream notices include [GPL licence](plugin/LICENSE.txt), [source/binary licensing clarification](plugin/Legal/SPEKTRAFILM_OFX_LICENSE.txt) and the other files in [Legal](plugin/Legal). Existing data, LUTs, images and documentation were retained from the public checkout. Licensed Academy printer-density CSVs missing from that checkout are not included, and no installed-only official plugin data was imported.

The unchanged descriptor source in `profiles/reference/` is an audit input from the same upstream commit, with its own [provenance and licence copies](profiles/reference/README.md). It is not another compiled plugin target.

Community modifications are recorded in [MODIFICATIONS.md](MODIFICATIONS.md). This project is not an official Spektrafilm release.

## OpenFX

The build fetches the [Academy Software Foundation OpenFX SDK](https://github.com/AcademySoftwareFoundation/openfx) at `e40728885390ec16276d11e00025de9b4282060c`. It is a build dependency, not vendored into this repository. Its upstream licence and copyright notices remain with the fetched SDK.

## Research references

These public projects informed the initial investigation of Tangent/MIDI integration:

- [FoxDanger / Control-Booster-OpenSourceCode](https://github.com/FoxDanger/Control-Booster-OpenSourceCode)
- [chaos-dotcom / tangentdesign_osc2midi](https://github.com/chaos-dotcom/tangentdesign_osc2midi)
- [Hammerspoon Tangent protocol implementation](https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/tangent/tangent.lua), originally by Chris Hocking and David Peterson for CommandPost

They are not bundled runtime dependencies. This implementation uses the native Tangent protocol, Windows WinMM and the OFX parameter/action interfaces described in the project source.

## Microsoft .NET runtime

Windows binary releases include the self-contained [Microsoft .NET runtime](https://github.com/dotnet/runtime) and [Windows Desktop runtime](https://github.com/dotnet/windowsdesktop). Their original licence and third-party notices ship in `licenses/dotnet/` in both release archives. `build-manifest.json` records the included framework versions. The repository does not vendor these runtimes; `Package.ps1` restores their Microsoft NuGet runtime packs for publication. These components retain their own licences.

## New project code

New companion, profiles, build/package scripts and test code are provided under GPL-3.0-or-later. See [LICENSE.txt](LICENSE.txt). The project is free to download and use under its licence. Names of third-party products identify compatibility; no endorsement or affiliation is claimed.
