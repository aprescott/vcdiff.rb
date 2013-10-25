# VCDIFF

A pure-Ruby implementation VCDIFF encoder/decoder. Aims to provide similar
functionality to Google's [open-vcdiff](https://code.google.com/p/open-vcdiff)
(which the [vcdiff](https://github.com/romanbsd/vcdiff) gem wraps), but without
the C.

Some important notes and to-be-implemented things:

* Encoding isn't implemented yet, although the plan is to use the
  [`bentley_mcilroy`](https://github.com/aprescott/bentley_mcilroy) gem,
  following the same strategy as open-vcdiff. There is a question of what block
  size to use for windows when finding common substrings.
* The decoder can't handle custom code tables or any sort of compression flags.
  Compression is probably a won't-fix on account of there being no compressor
  ID standards and the RFC for VCDIFF doesn't specify one. Custom code table
  support is desirable so every VCDIFF encoding is supported when decoding.
* The decoder doesn't handle any window where the `VCD_TARGET` bit is set in
  the window indicator (`Win_indicator`). As with custom code tables, it would
  be good to have this. It's currently omitted for simplicity.

Further reading:

* [RFC3284](http://tools.ietf.org/html/rfc3284#section-7) — The VCDIFF Generic Differencing and Compression Data Format

# Installation

Add this line to your application's Gemfile:

```
gem "vcdiff.rb"
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install vcdiff.rb
```

# Usage

## Encoding

Not yet implemented.

## Decoding

```ruby
decoder = VCDIFF::Decoder.new("path/to/dictionary_source")
original_target = decoder.decode("path/to/delta_file")
```

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

The issue tracker is [on GitHub](https://github.com/aprescott/vcdiff.rb/issues).
If you find any bugs, just open an issue.

# License

Copyright (c) Adam Prescott, released under the MIT license. See the license file.
