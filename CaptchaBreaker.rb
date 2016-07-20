# Based on https://github.com/eidge/ruby-captcha-breaker/blob/master/CaptchaBreaker.rb
require 'RMagick'

class CaptchaBreaker
  def initialize(image_file)
    @image = Magick::Image.read(image_file).first
  end

  def break
    select_captcha_case
    @image = remove_image_noise(@image)
    captcha = slices.map{|s| solve(s)}.join

    captcha
  end

  private

  def get_pixels(image)
    image.dispatch(0, 0, image.columns, image.rows, 'R')
  end

  def image_from_pixels(pixels)
    pixels = pixels.map{ |px| [px,px,px] }.flatten # Replicate channels to create an rgb image
    Magick::Image.constitute(@image.columns, @image.rows, 'RGB', pixels)
  end

  def erode(image)
    pixels = get_pixels(image)
    white = pixels.uniq.sort.last
    pixels.each_with_index do |px, i|
      next if px == white # skip white pixels
      pixels[i] = 1 if  pixels[i + 1] == white && pixels[i - 1] == white ||
                        pixels[i + image.columns] == white && pixels[i - image.columns] == white ||
                        pixels[i + 1] == white && pixels[i + image.columns] == white ||
                        pixels[i - 1] == white && pixels[i - image.columns] == white
    end
    pixels.each_with_index do |px, i|
      pixels[i] = white if px == 1
    end

    image_from_pixels(pixels)
  end

  def remove_image_noise(image)
    image = image.quantize(3, Magick::GRAYColorspace)
    image = erode(image)
  end

  def original_numbers
    @original_numbers ||= (0..9).map{|i| Magick::Image.read("./originals/#{i}_#{@case}.jpg").first}
  end

  def slices
      (0..5).map{|i| @image.crop(@first_pixel + (i * @separation),8,@width,16, true)}
  end

  def solve(slice)
    errors = {}
    for i in 0..9
      mean_error_per_pixel = slice.difference(original_numbers[i])
      errors[i] = mean_error_per_pixel[1]
    end
    number = errors.group_by{|k, v| v}.min_by{|k, v| k}.last.to_h.keys.join

    number
  end

  def select_captcha_case
    case1_a ||= Magick::Image.read("./cases_to_compare/case1_a.jpg").first
    case1_b ||= Magick::Image.read("./cases_to_compare/case1_b.jpg").first
    case1_c ||= Magick::Image.read("./cases_to_compare/case1_c.jpg").first
    case2_a ||= Magick::Image.read("./cases_to_compare/case2_a.jpg").first
    case2_b ||= Magick::Image.read("./cases_to_compare/case2_b.jpg").first
    case2_c ||= Magick::Image.read("./cases_to_compare/case2_c.jpg").first

    case1 = @image.difference(case1_a)[1] + @image.difference(case1_b)[1] + @image.difference(case1_c)[1]
    case2 = @image.difference(case2_a)[1] + @image.difference(case2_b)[1] + @image.difference(case2_c)[1]

    if case1 < case2
      @case = 1
      @width = 11
      @separation = 13
      @first_pixel = 15
    else
      @case = 2
      @width = 12
      @separation = 14
      @first_pixel = 16
    end
  end
end
