# Based on https://github.com/eidge/ruby-captcha-breaker/blob/master/CaptchaBreaker.rb
require 'RMagick'
#require 'rtesseract'

class CaptchaBreaker
  def initialize(image_file, index)
    @image = Magick::Image.read(image_file).first
    @index = index.to_s
  end

  def break
    #remove gray pixels
    #@image = @image.opaque_channel('#5e5e5e', 'white', invert=false, fuzz=10000 )
    #to grayscale
    @image = @image.quantize(3, Magick::GRAYColorspace)
    #@image = complete_graybar(@image)
    @image = erode(@image)
    #@image.write("to_blob" + @index + ".png")
    #@image = remove_blacks(@image)
    #compare with original numbers
    for i in 0..5
      crop = @image.crop(15 + (i * 13),8,11,16, true)
      #crop.write("number_cropped_#{i}.jpg")
      errors = {}
      for j in 0..9
        original_number = Magick::Image.read("./originals/#{j}.jpg").first
        mean_error_per_pixel = crop.difference(original_number)
        errors[j] = mean_error_per_pixel[1]
      end
      number = errors.group_by{|k, v| v}.min_by{|k, v| k}.last.to_h.keys.join
      captcha = captcha.to_s + number.to_s
    end

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

  def erode(image, action = :erode)
    pixels = get_pixels(image)

    if action == :erode
      white = pixels.uniq.sort.last
    else
      white = pixels.uniq.sort.first
    end

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

  def complete_graybar(image)
    #fill with black the gray deleted pixels according to the context
    pixels = get_pixels(image)
    black = pixels.uniq.sort.first
    i = 1800
    105.times {
      cerca = 0
      if pixels[i - 120] == black
        cerca = cerca + 1
      end
      if pixels[i - 240] == black
        cerca = cerca + 1
      end
      if pixels[i + 240] == black
        cerca = cerca + 1
      end
      if pixels[i + 360] == black
        cerca = cerca + 1
      end
      if cerca > 2
        pixels[i] = black
        pixels[i + 120] = black
      end
      i = i + 1
    }
    image_from_pixels(pixels)
  end

  def remove_blacks(image)
    #delete black isoleted points
    pixels = get_pixels(image)
    black = pixels.uniq.sort.last

    pixels.each_with_index do |px, i|
      cerca = 0
      if pixels[i - 119] == black
        cerca = cerca + 1
      end
      if pixels[i - 120] == black
        cerca = cerca + 1
      end
      if pixels[i - 121] == black
        cerca = cerca + 1
      end
      if pixels[i + 30] == black
        cerca = cerca + 1
      end
      if pixels[i - 30] == black
        cerca = cerca + 1
      end
      if pixels[i + 119] == black
        cerca = cerca + 1
      end
      if pixels[i + 120] == black
        cerca = cerca + 1
      end
      if pixels[i + 121] == black
        cerca = cerca + 1
      end
      pixels[i] = black if cerca > 7
    end
    image_from_pixels(pixels)
  end
end
