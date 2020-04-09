# Using Dvorak Keybord Layout on MacOS with Yubikey

I first got a yubikey nano (or yubico, or whatever, honestly I'm not
sure what the product is called--it's the little yubikey that goes in
the USB-C port and (infuriatingly, if you're a Dvorak user) is a USB
HID keyboard sending scancodes for when it posts its secret values.

## Previous Solutions

Yubi themselves are pretty unresponsive and unsympathetic to this
issue.  Their "preferred" solution is to switch the keyboard layout to
US and back to Dvorak whenever using this key. When I first
encountered this problem, I used this solution, since at the time
I met the following criteria:

* I had a touchbar MacBook, so I could include a layout switch softkey
  in the touchbar
* I didn't have to use the yubikey two-factor that frequently: just
  once or twice a day
* I was only using the Dvorak keyboard layout, so the key could be
  used as a toggle. If you use (as I did at subsequent jobs) more than
  one (for example, a main one and an international one), it's much
  less convenient

It sort of worked, it was an annoyance I could deal with. When I moved
on from that position I moved on from the annoying Yubikey.

Yubi [proposes other solutions](https://www.yubico.com/2013/07/yubikey-keyboard-layouts/)
for the key, including holding down the SHIFT key if you happen to be
using AZERTY, and loading custom scan maps into a Yubikey NEO.

These are not very good solutions and you can accurately read it as
Yubi giving a middle finger to Dvorak users/Colemak users/the French. The
TL;DR here is "We don't care, you're on your own".

Luckily I found a
[blog post from 2014](https://superuser.do/2014/10/22/yubikey-support-for-non-qwerty-keyboard-layouts-on-mac-os-x/)
describing how to use Karabiner key remapping software to essentially
apply a layer of remapping to the Yubikey scancodes to "Un-Dvorak"
them. This is great. It probably worked great in 2014, but Karabiner has
changed since then and is now configured differently: I couldn't use the
XML file referenced in the solution.

So I sat down, did some scripting, and worked out how to generate the
appropriate remappings so you could include them in Karabiner's configuration
file. I describe that solution below under **My Solution**. Unfortunately I
didn't do *enough* searching and I didn't find **The Best Solution** below
until after I had done the work.

## The Best Solution

I basically duplicated
[Adam Johnson's work here](https://adamj.eu/tech/2018/09/17/using-yubikey-with-colemak/)
by accident except his solution is much better, since it incorporates
a much simpler `simple_modifications` block where it can apply to only
one device. If you use Dvorak or Colemak, use it.

If you are using something else (maybe something weirder) then maybe
you might find my solution useful. But it's probably better to just do
it the above way anyway.

## My Solution

My solution uses a poorly-written Ruby script to generate the
`complex_modifications` rules necessary to remap just the input from
the Yubikey to "un-Dvorak" them. Essentially, you take the simple
remaps in [yubikey-remap.json](yubikey-remap.json), run
[yubikey-gen-rules.rb](yubikey-gen-rules.rb) on it and paste the
result as the value of the `rules` key in the correct
`.profiles.complex_modifications` section of your `karabiner.json`.

## My Yubikey

This is part of the output from `system_profiler SPUSBDataType`:

```
    USB 3.0 Bus:

      Host Controller Driver: AppleUSBXHCISPTLP
      PCI Device ID: 0x9d2f
      PCI Revision ID: 0x0021
      PCI Vendor ID: 0x8086

        Yubikey 4 OTP+U2F+CCID:

          Product ID: 0x0407
          Vendor ID: 0x1050
          Version: 4.37
          Speed: Up to 12 Mb/s
          Manufacturer: Yubico
          Location ID: 0x14400000 / 2
          Current Available (mA): 500
          Current Required (mA): 30
          Extra Operating Current (mA): 0
 ```

