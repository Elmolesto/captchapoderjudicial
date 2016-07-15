require 'cutest'
require_relative 'CaptchaBreaker'

solutions = ['402417','014530','670850','789445','970314','861000','760449','960827','053960','822458','213760','501922','416964','123954','397451','165837','654348','787814','694421','507188','598529','399263','869895','538425']

test "solves sample1 image" do
  ok = 0
  solutions.each_with_index do |value, i|
    image = "images_case1/" + (i+1).to_s + ".jpg"
    solution = CaptchaBreaker.new(image, i).break
    if solution == value
      ok = ok + 1
      print "| " + (i).to_s + " - "
      print solution
      print " - ok |"
    else
      print "| " + (i).to_s + " - "
      print solution
      print " - fail |"
    end
    #assert_equal(value, solution)
  end
  confianza = (ok * 100 / 24)
  print "%" + confianza.to_s + "%"
end
