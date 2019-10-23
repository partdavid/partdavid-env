#!/usr/bin/env ruby

# Generates Karabiner complex_modification rules that can be incorporated into
# ~/.config/karabiner/karabiner.json - See https://pqrs.org/osx/karabiner/json.html

require 'json'

$vendor_id = 4176
$product_id = 1031
$yubikey_description = 'Yubico'

remaps = File.open(ARGV[0], 'r') { |fh| JSON.load(fh) }

rules = remaps.map do |from_key, to_key|
  {
    description: "Map Dvorak #{from_key} to Qwerty #{to_key} for Yubikey",
    manipulators: [
      {
        type: 'basic',
        from: {
          key_code: from_key
        },
        to: {
          key_code: to_key
        },
        conditions: [
          {
            type: 'device_if',
            identifiers: [
              {
                product_id: $product_id,
                vendor_id: $vendor_id,
                description: $yubikey_description
              }
            ]
          }
        ]
      }
    ]
  }
end

puts JSON.pretty_generate rules
