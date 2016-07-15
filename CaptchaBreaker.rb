require 'RMagick'
require 'rtesseract'

class CaptchaBreaker
  def initialize(image_file, index)
    @image = Magick::Image.read(image_file).first
    @index = index.to_s
  end

  def break
    #borro la barra gris
    @image = @image.opaque_channel('#5e5e5e', 'white', invert=false, fuzz=10000 )

    #paso a gray
    @image = @image.quantize(3, Magick::GRAYColorspace)

    #completo barra borrada
    @image = complete_graybar(@image)


    #dejo el times para ir probando con algunos pasos más
    @image = erode(@image)
    @image = erode(@image, :inflate)
    @image = remove_blacks(@image)

    #exporto la imagen
    #@image.write("to_blob" + @index + ".png")

    # Use tesseract to read the characters
    @image.format = 'JPEG'
    tesseract = RTesseract.new('options: :digits')
    tesseract.from_blob @image.to_blob

    #armo array
    captcha = tesseract.to_s_without_spaces.split(//)

    #elimino todo lo que no es numero
    captcha.each_with_index do |value, i|
      if '0123456789'.split('').include?(value)
        captcha[i] = value
      else
        captcha[i] = ""
      end
    end

    #paso a string
    captcha = captcha.join

    #si no tengo 6 numeros, le paso otro filtro para inflar y vuelvo a reconocer
    if captcha.length != 6
      1.times { @image = erode(@image) }
      @image = remove_blacks(@image)
      1.times { @image = erode(@image, :inflate) }

      # Use tesseract to read the characters
      @image.format = 'JPEG'
      tesseract = RTesseract.new('options: :digits')
      tesseract.from_blob @image.to_blob
      captcha = tesseract.to_s_without_spaces.split(//)

      captcha.each_with_index do |value, i|
        if '0123456789'.split('').include?(value)
          captcha[i] = value
        else
          captcha[i] = ""
        end
      end
      captcha = captcha.join
    end

    #muestro
    return captcha
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
    #intento completar el espacio vaciodo por la barra gris
    pixels = get_pixels(image)
    black = pixels.uniq.sort.first
    i = 1800
    gris = 30000
    110.times {
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
    #borramos los puntos negros que quedan sueltos
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
