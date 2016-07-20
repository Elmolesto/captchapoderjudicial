# Based on https://github.com/eidge/ruby-captcha-breaker/blob/master/CaptchaBreaker.rb
require 'RMagick'

class CaptchaBreaker
  def initialize(image_file)
    @image = Magick::Image.read(image_file).first
  end

  def break
    @image = remove_image_noise(@image)
    characters = slices(@image)
    captcha = (0..5).map{|i| solve(characters[i])}.join

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
    @original_numbers ||= (0..9).map{|i| Magick::Image.read("./originals/#{i}.jpg").first}
  end

  def slices(image)
    (0..5).map{|i| image.crop(15 + (i * 13),8,11,16, true)}
  end

  def solve(slice)
    errors = {}
    original_numbers
    for i in 0..9
      mean_error_per_pixel = slice.difference(original_numbers[i])
      errors[i] = mean_error_per_pixel[1]
    end
    number = errors.group_by{|k, v| v}.min_by{|k, v| k}.last.to_h.keys.join

    number
  end
end
