# I've been making a free Tangent / MIDI version of Spektrafilm, looking for some early testers

Hi all, I'm Luka, a commercial DP based in Copenhagen, Denmark.

I've got a full Tangent Element set and wanted to get it controlling [Spektrafilm](https://github.com/chaert-s/spektrafilm-ofx) directly in Resolve. I like having actual knobs under my hands, and it seemed a shame to have all those controls sitting there while going through the plugin with a mouse. That sent me down a bit of a rabbit hole looking at Tangent, MIDI and what was possible with the public Spektrafilm source.

Anyway, I've put together a Windows prototype and am sharing it free, with the source, here: [Spektrafilm MIDI](https://github.com/nothing-complex/spektrafilm-midi).

It's a separate version of the effect with a small companion app, so you can keep your regular Spektrafilm installed alongside it. The maps cover all 24 continuous controls on the full Element set, with banks for the different features, resets and fine adjustment. The native Tangent connection also has support for sending names, values and bank information back to the panel screens. There's MIDI and OSC input as well if you've got a different controller you'd like to try.

This is still early testing territory. The software builds and the automated checks pass, but I haven't completed testing it on the physical panels or inside Resolve yet. The main thing to establish is whether Resolve exposes the controls needed for the companion to apply changes automatically. At the moment that route depends on explicitly binding to the effect's Apply MIDI button through Windows accessibility. There's a manual Apply button as a fallback, but obviously that's a fair bit less useful if you're trying to grade continuously with the panels.

It also uses the older public Spektrafilm source, so please don't expect every feature from the current official release. Some transport and Resolve commands still need doing too. I've written up the setup and the things that still need checking in the repo, rather than pretend it's ready to drop into a paid session.

If anyone has an Element set or a MIDI controller and feels like trying it on a spare project, I'd love to hear how you get on. Feedback, awkward bugs and help getting it further are all welcome.

And a shameless plug while I'm here: if you also shoot, my side business is [lensflare.io](https://lensflare.io), an in-browser storyboarding, shot planning and 3D previs tool. Completely separate from this; the plugin is free either way.

Anyway, hope this ends up useful to a few people. Mods, please delete if not allowed.
