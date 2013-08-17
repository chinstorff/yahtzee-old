require "./Turn.rb"
require "./Scorecard.rb"

def display(s, dice, m1, m2, m3, turn_num, roll_num)
  score = s.get_all

  puts
  puts   " ______________________________________ "
  printf "|a Aces    [%2d] |g 3 of a kind    [%2d] | Dice:                                Turn %2d/13\n", score["aces"], score["3_of_a_kind"], turn_num
  printf "|b Twos    [%2d] |h 4 of a kind    [%2d] |   a %d                                Roll  %1d/3\n", score["twos"], score["4_of_a_kind"], dice[0], roll_num
  printf "|c Threes  [%2d] |i Full house     [%2d] |   b %d\n", score["threes"], score["full_house"], dice[1]
  printf "|d Fours   [%2d] |j Small straight [%2d] |   c %d\n", score["fours"], score["small_straight"], dice[2]
  printf "|e Fives   [%2d] |k Large straight [%2d] |   d %d\n", score["fives"], score["large_straight"], dice[3]
  printf "|f Sixes   [%2d] |l Yahtzee        [%2d] |   e %d\n", score["sixes"], score["yahtzee"], dice[4]
  printf "|               |  Yahtzee bonus   %3d |\n", score["yahtzee_bonus"]
  printf "|Subtotal:   %2d |m Chance         [%2d] | %s\n", score["upper_subtotal"], score["chance"], m1
  printf "|Bonus:      %2d |                      | %s\n", score["upper_bonus"], m2
  printf "|Total:      %2d |Total:             %2d | %s\n", score["upper_total"], score["lower_total"], m3
  printf "|______ Grand Total:%4d ______________|   > ", score["grand_total"]
  input = STDIN.gets.chomp
  return input
end


def determine_preserve(s)
  ret = [1,1,1,1,1]
  s.split("").each do |c|
    case c
    when 'a'
      ret[0] = 0
    when 'b'
      ret[1] = 0
    when 'c'
      ret[2] = 0
    when 'd'
      ret[3] = 0
    when 'e'
      ret[4] = 0
    end
  end
  return ret
end

def score(s, c, dice)
  case c
  when 'a'
    cat = "aces"
  when 'b'
    cat = "twos"
  when 'c'
    cat = "threes"
  when 'd'
    cat = "fours"
  when 'e'
    cat = "fives"
  when 'f'
    cat = "sixes"
  when 'g'
    cat = "3_of_a_kind"
  when 'h'
    cat = "4_of_a_kind"
  when 'i'
    cat = "full_house"
  when 'j'
    cat = "small_straight"
  when 'k'
    cat = "large_straight"
  when 'l'
    cat = "yahtzee"
  when 'm'
    cat = "chance"
  else
    return false
  end
  return s.score cat, dice
end

sc = Scorecard.new
t = [1...13]

13.times do |i|
  t[i] = Turn.new
  display sc, t[i].get_dice, "", "", "Press enter to roll", i+1, 0
  t[i].roll
  selection = display sc, t[i].get_dice, "", "Select which dice you would like to roll again.", "Type the letters of the dice followed by enter: ", i+1, t[i].get_reroll_count+1
  t[i].set_preserve determine_preserve(selection)
  t[i].reroll
  selection = display sc, t[i].get_dice, "", "Select which dice you would like to roll again.", "Type the letters of the dice followed by enter: ", i+1, t[i].get_reroll_count+1
  t[i].set_preserve determine_preserve(selection)
  t[i].reroll
  m1 = ""
  success = false
  while !success
    selection = display sc, t[i].get_dice, m1, "Select the category for this roll. Type the", "letter of the category followed by enter: ", i+1, t[i].get_reroll_count+1
    m1 = "Selection invalid"
    success = score sc, selection.split("")[0], t[i].get_dice
  end
end
