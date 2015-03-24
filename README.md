
# Caleidenticon

![Example Identicons 1](https://dl.dropboxusercontent.com/s/8t5oww83d5vcagw/identicons.png)

Caleidenticon creates caleidoscope-like [identicons](https://en.wikipedia.org/wiki/Identicon).

It is based on [RubyIdenticon](https://github.com/chrisbranson/ruby_identicon) by Chris Branson which in turn was based on [go-identicon](https://github.com/dgryski/go-identicon) by Damian Gryski.

## Usage

    require 'caleidenticon'

Create an identicon png and save it to a path:

    Caleidenticon.create_and_save(user.email, user.identicon_path, {salt: my_salt})

create_and_save takes 3 parameters:

    input     # a string on which to base the identicon (usually an email or username)
    save_path # the storage path for the resulting identicon png file
    options   # a Hash (not required)

## Options

    complexity:      # Integer (2..n)  number of elements per image. affects image size.
    scale:           # Integer (1..n)  resolution of each element. affects image size.
    density:         # Integer (2..10) how densely the image is covered with elements
    spikiness:       # Integer (1..n)  higher values produce a more pointy overall shape
    corner_sprinkle: # Integer (0..n)  decorates bare corners if spikiness is > 0 
    colors:          # Array of 4 arrays with 3 Integers (0..255) each.
    salt:            # String of 21 alphanumeric chars, used for hashing the input.
    debug:           # Bool - if true, the gem will print a lot of debug information.

Using your own salt is optional, but it is recommended, as it ensures that the mapping from input to identicon will be unique to your application.

With the colors: option you can make the identicons fit in more closely with the color scheme of your app. E.g. if your app has bright green and blue colors you could do something like:

    identicon_options = {salt: my_salt, colors: [[80,255,100], [80,100,255], [0,200,255], [0,255,200]]}
    Caleidenticon.create_and_save(user.email, user.identicon_path, identicon_options)

Which will produce Identicons like these:

![Example Identicons 2](https://dl.dropboxusercontent.com/s/cvjlprdev4ibt0f/identicon_bluegreen.png)

Higher values for complexity, density and scale make the generation more expensive, but the results look better at a large scale:

More complex and dense →

![Example Identicons 3](https://dl.dropboxusercontent.com/s/zupywnv0lhst3nz/identicon_options.png)

To test your settings, create a large number of identicons by running:

    Caleidenticon.run_test(my_output_dir, number_of_identicons, my_options)
