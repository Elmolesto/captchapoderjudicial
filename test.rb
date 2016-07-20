require 'cutest'
require_relative 'CaptchaBreaker'


test "solves sample1 image" do
  ok = 0
  test_quantity = 0
  Dir["./images_test/*.jpg"].each_with_index do |filename, i|
    solution = CaptchaBreaker.new(filename).break
    test_quantity = i + 1
    if solution == File.basename(filename, ".jpg")
      ok = ok + 1
    else
      puts "FAIL - resolve: #{solution} - original: #{File.basename(filename, ".jpg")}"
    end
    #assert_equal(value, solution)
  end
  confidence_level = (ok * 100 / test_quantity)
  puts "|||| Confidence Level: #{confidence_level.to_s}% ||||"
end
