require "./lib/yahtzee"

def format(score)
  return "  " if score == -1
  return "%2d" %[score]
end

def display(score, dice, m1, m2, m3)
  puts   " ______________________________________ " 
  printf "|a Aces    [%s] |g 3 of a kind    [%s] | Dice:\n", format(score[:aces]), format(score[:three_of_a_kind])
  printf "|b Twos    [%s] |h 4 of a kind    [%s] |   a %d\n", format(score[:twos]), format(score[:four_of_a_kind]), dice[0]
  printf "|c Threes  [%s] |i Full house     [%s] |   b %d\n", format(score[:threes]), format(score[:full_house]), dice[1]
  printf "|d Fours   [%s] |j Small straight [%s] |   c %d\n", format(score[:fours]), format(score[:small_straight]), dice[2]
  printf "|e Fives   [%s] |k Large straight [%s] |   d %d\n", format(score[:fives]), format(score[:large_straight]), dice[3]
  printf "|f Sixes   [%s] |l Yahtzee        [%s] |   e %d\n", format(score[:sixes]), format(score[:yahtzee]), dice[4]
  printf "|               |  Yahtzee bonus   %3d |\n", score[:yahtzee_bonus]
  printf "|Subtotal:   %2d |m Chance         [%s] | %s\n", score[:upper_section_subtotal], format(score[:chance]), m1
  printf "|Bonus:      %2d |                      | %s\n", score[:upper_section_bonus], m2
  printf "|Total:     %3d |Total:            %3d | %s\n", score[:upper_section_total], score[:lower_section_total], m3
  printf "|______ Grand Total:%4d ______________|   > ", score[:grand_total]
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

def parse c
  case c
  when 'a'
    cat = :aces
  when 'b'
    cat = :twos
  when 'c'
    cat = :threes
  when 'd'
    cat = :fours
  when 'e'
    cat = :fives
  when 'f'
    cat = :sixes
  when 'g'
    cat = :three_of_a_kind
  when 'h'
    cat = :four_of_a_kind
  when 'i'
    cat = :full_house
  when 'j'
    cat = :small_straight
  when 'k'
    cat = :large_straight
  when 'l'
    cat = :yahtzee
  when 'm'
    cat = :chance
  else
    return false
  end
  return cat
end

game = Yahtzee::Controller.new

13.times do |i|
  display game.get_data, [0,0,0,0,0], "", "", "Press enter to roll"
  game.roll
  selection = display game.get_data, game.get_dice, "", "Select which dice you would like to roll again.", "Type the letters of the dice followed by enter: "
  game.reroll determine_preserve(selection)
  selection = display game.get_data, game.get_dice, "", "Select which dice you would like to roll again.", "Type the letters of the dice followed by enter: "
  game.reroll determine_preserve(selection)
  
  m1 = ""
  success = false
  while !success
    selection = display game.get_data, game.get_dice, m1, "Select the category for this roll. Type the", "letter of the category followed by enter: "
    m1 = "Selection invalid"
    success = game.score(parse(selection.split("")[0]))
  end
end
display sc, [0,0,0,0,0], "", "Game complete", ""
