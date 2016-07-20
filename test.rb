require 'cutest'
require_relative 'CaptchaBreaker'


test "solves sample1 image" do
  ok = 0
  testquantity = 0
  Dir["./images_case1/*.jpg"].each_with_index do |filename, i|
    solution = CaptchaBreaker.new(filename, i).break
    testquantity = i + 1
    if solution == File.basename(filename, ".jpg")
      ok = ok + 1

    else
      print "| "
      print solution
      print " - fail - "
      print File.basename(filename, ".jpg")
      print "| "
    end
    #assert_equal(value, solution)
  end
  confianza = (ok * 100 / testquantity)
  print "|||||| " + confianza.to_s + "% ||||||"
end
