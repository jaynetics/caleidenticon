module Caleidenticon

  ['bcrypt', 'oily_png'].each {|gem| require gem}

  DEFAULT_OPTIONS = {
    complexity: 6,      # (2..n)  number of elements per image. affects image size.
    scale: 10,          # (1..n)  resolution of each element. affects image size.
    density: 6,         # (2..10) how densely the image is covered with elements
    spikiness: 2,       # (1..n)  higher values produce a more pointy overall shape
    corner_sprinkle: 4, # (0..n)  decorates bare corners if spikiness is > 0
    colors: [ [255,10,125], [255,50,10], [15,50,255], [140,255,10] ],
    salt: "KGvNwCoZtioSTC07piREn",
    debug: false
  }

  BCRYPT_SALT_HEAD = '$2a$10$'

  def self.create_and_save(input, save_path, options = {})
    blob = create_blob(input, options)
    if blob.nil?
      debug('blob creation failed')
      return false
    end
    File.open(save_path, 'wb') {|f| f.write(blob)}
  end

  def self.create_blob(input, options)
    options = DEFAULT_OPTIONS.merge(options)

    full_salt = "#{BCRYPT_SALT_HEAD}#{options[:salt]}."
    
    # ensure workable settings
    options[:complexity] = [options[:complexity], 2].max
    options[:scale]      = [options[:scale], 1].max
    options[:density]    = [[options[:density], 2].max, 10].min
    options[:spikiness]  = [options[:spikiness], 1].max

    raise ArgumentError.new('input cannot be empty') if input.nil? || input == ''
    raise ArgumentError.new('salt must be a string of 21 ASCII chars') unless BCrypt::Engine.valid_salt?(full_salt)
    raise ArgumentError.new('invalid colors') unless options[:colors].map{|array| array.size} == [3,3,3,3] &&
                                                     options[:colors].flatten.all?{|val| (0..255).include?(val)}

    @debug = options[:debug]
    debug("creating blob for input '#{input}'")

    hash = BCrypt::Engine.hash_secret(input, full_salt)
    hash.slice!(0, BCRYPT_SALT_HEAD.length) # else the first few hash bits would be the same for all inputs
    hash = (hash * options[:complexity]).bytes.inject {|a, b| (a << 8) + b}

    debug("hash bits: #{hash.to_s(2).length}")

    # use the first few bytes of the hash to define a tint color for the identicon
    tint_rgb = Array.new(3) {hash >>= 8; hash >> 8 & 0xff}

    debug("tint color: #{tint_rgb.inspect}")

    colors = options[:colors].map do |option_rgb|
      # use a saturated version of each color from options that is only lightly influenced by the input
      [ChunkyPNG::Color.rgba(
        (option_rgb[0] + tint_rgb[0]) / 2, # r
        (option_rgb[1] + tint_rgb[1]) / 2, # g
        (option_rgb[2] + tint_rgb[2]) / 2, # b
        0xff), # alpha
      # ... and a darker version that is more strongly influenced by the input
      ChunkyPNG::Color.rgba(
        (option_rgb[0] * 2 + tint_rgb[0] * 5) / 9, # r
        (option_rgb[1] * 2 + tint_rgb[1] * 5) / 9, # g
        (option_rgb[2] * 2 + tint_rgb[2] * 5) / 9, # b
        0xff)] # alpha
    end.flatten

    # creat color shifts and size multiplicators from the next bytes,
    # so that colors dont have to appear in the same array order for all users,
    # and so that some elements are larger (in an input-specific order)
    color_shifts        = Array.new(10) {hash >>= 3; hash >> 3 & 7} # 0-7
    size_multiplicators = Array.new(10) {hash >>= 2; [(hash >> 2 & 3), 1].max} # 1-3

    debug("shifts: #{color_shifts.inspect} mults: #{size_multiplicators.inspect}")

    # -------
    # create the actual graphics
    # -------

    grid_size      = options[:complexity] * 2 + 1
    unused_cells   = [((options[:complexity] * options[:spikiness])/4), (grid_size - 2)].min
    circle_radius  = options[:scale]/2
    margin         = circle_radius * 3 # circles can have up to 3x their default radius
    image_size     = (grid_size * options[:scale] + margin) * 2
    image          = ChunkyPNG::Image.new(image_size, image_size, ChunkyPNG::Color::TRANSPARENT)

    # use up to (options[:corner_sprinkle] ** 2) cells in the
    # outer corner of a quadrant to add a bit of "sprinkle"
    sprinkle_inset = options[:complexity]/2 + 1
    usable_space   = [unused_cells - sprinkle_inset, 0].max
    space_to_use   = [usable_space, options[:corner_sprinkle]].min
    sprinkle_range = space_to_use > 0 ? sprinkle_inset..(sprinkle_inset + space_to_use) : []

    debug("grid size: #{grid_size} non-main: #{unused_cells} sprinkled: #{space_to_use}")

    element_scarcity = 10 - options[:density]
    rectangle_amount = (hash >> 1 & 1) + 1
    rect_matcher     = rectangle_amount == 1 ? 1 : 3

    column, row = 0, 0
    rectangles_per_row = {}

    # fill the single grid cells
    (grid_size ** 2).times do |i|

      if column > grid_size # a row was just completed, proceed with first column of next row
        row += 1
        column = 0
      end

      # skip this cell if we are not in the primary cells or in a sprinkleable corner
      in_sprinkle_range = sprinkle_range.include?(row) && sprinkle_range.include?(column)
      in_primary_cells  = row >= unused_cells
      unless in_primary_cells || in_sprinkle_range
        column += 1
        next
      end
      
      hash >>= element_scarcity
      if (hash >> element_scarcity & element_scarcity) == element_scarcity

        x = (column + 1) * circle_radius * 2 + margin
        y = (row + 1)    * circle_radius * 2 + margin

        # draw the elements mirrored within the quadrant, and all quadrants point-symmetric to the center.
        # despite drawing each element eight times, this is actually much less expensive than drawing once
        # and then rotating, flipping and merging the result!
        vectors = [[x, y],                       [y, x],                       # top left quadrant
                   [image_size-x, y],            [image_size-y, x],            # top right quadrant
                   [x, image_size-y],            [y, image_size-x],            # bottom left quadrant
                   [image_size-x, image_size-y], [image_size-y, image_size-x]] # bottom right quadrant

        # choose element color and size by using color shift and size at index 0-9
        color        = colors[color_shifts[i%10]]
        element_size = circle_radius * size_multiplicators[i%10]

        rectangles_per_row[row] = 0 unless rectangles_per_row.has_key?(row)

        # create lengthy rectangles for a bit more than half of all cells
        hash >>= rectangle_amount
        if ((hash >> rectangle_amount & rect_matcher) != rect_matcher || rectangles_per_row[row] == 2)
          rectangles_per_row[row] += 1
          rect_width, rect_length = element_size, element_size/4
          rect_width, rect_length = rect_length, rect_width if hash >> 1 & 1 == 1 # rotate half of all rects
          hash >>= 1
          vectors.each_with_index do |v, idx|
            x_size, y_size = rect_width, rect_length
            # rects are lengthy, so their 2nd drawing in each quadrant must be rotated by 90°
            x_size, y_size = y_size, x_size if idx % 2 != 0 
            image.rect(v[0]-x_size, v[1]-y_size, v[0]+x_size, v[1]+y_size, color, color)
          end
          type = 'rect'
        # create circles for other cells
        else
          vectors.each {|v| image.circle(v[0], v[1], element_size, color, color)}
          type = 'circle'
        end
        debug("cell #{i} color: #{color}, size: #{size_multiplicators[i%10]}, type: #{type}")
      end
      column += 1
    end

    image.to_blob color_mode: ChunkyPNG::COLOR_INDEXED
  end

  def self.run_test(output_dir, iterations = 20, options = {})
    options[:debug] = true
    start = Time.now.to_i

    if output_dir && File.directory?(output_dir)
      output_dir = File.join(output_dir, "caleidenticon_test_#{start}")
      Dir.mkdir(output_dir)
    else
      raise ArgumentError.new('no output_dir')
    end

    iterations.times do
      random_string = (0...8).map{(65 + rand(26)).chr}.join
      save_path = File.join(output_dir, "#{random_string}.png")
      self.create_and_save(random_string, save_path, options)
    end

    debug("creating #{iterations} pngs took #{Time.now.to_i - start} seconds")
  end

  private

  def self.debug(string)
    puts string if @debug
  end

end
