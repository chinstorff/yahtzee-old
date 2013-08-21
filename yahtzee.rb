
class Turn
  def initialize
    @dice     = roll_dice 5
    @preserve = [1,1,1,1,1]
    
    @reroll_count = 0
    @reroll_max   = 2
  end

  def roll_dice(num_dice)
    a = []
    
    num_dice.times do
      a.push Random.rand(6) + 1
    end
    
    return a
  end

  def set_preserve(pr)
    @preserve = pr
  end
  
  def get_preserve
    return @preserve
  end

  def get_dice
    return @dice
  end

  def get_reroll_count
    return @reroll_count
  end

  def reroll
    if @reroll_count < @reroll_max
      a = roll_dice 5
      5.times do |i|
        if @preserve[i] == 0
          @dice[i] = a[i]
        end
      end
    end
    @reroll_count += 1
  end
end

class Scorecard
  @@bonus_value          = 35
  @@full_house_value     = 25
  @@small_straight_value = 30
  @@large_straight_value = 40
  @@yahtzee_value        = 50
  @@yahtzee_bonus_value  = 100

  def initialize
    @categories = [ "aces", "twos", "threes", "fours", "fives", "sixes",
                    "3_of_a_kind", "4_of_a_kind", "full_house", "small_straight",
                    "large_straight", "yahtzee", "yahtzee_bonus" "chance" ]

    @turns = Array.new
    13.times { @turns.push Turn.new }
    
    @upper_section = { 
      "aces"   => -1, 
      "twos"   => -1,
      "threes" => -1,
      "fours"  => -1,
      "fives"  => -1,
      "sixes"  => -1
    }
    @upper_section_bonus = 0

    @lower_section = {
      "3_of_a_kind"    => -1,
      "4_of_a_kind"    => -1,
      "full_house"     => -1,
      "small_straight" => -1,
      "large_straight" => -1,
      "yahtzee"        => -1,
      "chance"         => -1,
      "yahtzee_bonus"  => 0,
    }
    
    @upper_section_subtotal = 0  # no bonus
    @upper_section_total    = 0  # possible bonus
    @lower_section_total    = 0

    @grand_total = 0
  end

  def get_turn(num)
    return @turns[num]
  end
  
  def calculate_dice(dice)
    cats = {
      "aces"   => 0,
      "twos"   => 0,
      "threes" => 0,
      "fours"  => 0,
      "fives"  => 0,
      "sixes"  => 0,
      "3_of_a_kind"    => 0,
      "4_of_a_kind"    => 0,
      "full_house"     => 0,
      "small_straight" => 0,
      "large_straight" => 0,
      "yahtzee"        => 0,
      "chance"         => 0
    }
    
    # upper section
    dice.each do |i|
      case i
      when 1
        cats["aces"]   += 1
      when 2
        cats["twos"]   += 2
      when 3
        cats["threes"] += 3
      when 4
        cats["fours"]  += 4
      when 5
        cats["fives"]  += 5
      when 6
        cats["sixes"]  += 6
      end
    end

    # lower section
    freq = [0,0,0,0,0,0]
    sum  = 0
    dice.size.times do |i|
      sum += dice[i]
      freq[dice[i]-1] += 1
    end
    sfreq = freq.sort.reverse
    max  = sfreq[0] # number of most frequent dice
    smax = sfreq[1] # number of second most frequent
    
    small = false
    large = false
    ssum  = 0
    sdice = dice.sort.uniq
    sdice.size.times do |i|
      ssum += sdice[i]
    end
    large = true if sdice.length >= 5 and (ssum == 15 or ssum == 20)
    small = true if sdice.length >= 4 and (ssum == 10 or ssum == 14 or ssum == 18) or large
    
    
    cats["3_of_a_kind"]    = sum if max >= 3
    cats["4_of_a_kind"]    = sum if max >= 4
    cats["full_house"]     = @@full_house_value if max == 3 and smax == 2
    cats["small_straight"] = @@small_straight_value if small
    cats["large_straight"] = @@large_straight_value if large
    cats["yahtzee"]        = @@yahtzee_value if max >= 5
    cats["chance"]         = sum
    
    return cats
  end

  def score(cat, dice)
    pot = calculate_dice dice
    
    case cat.split("")[-1]
    when 's'
      if @upper_section[cat] == -1
        @upper_section[cat] = pot[cat]
        calculate_totals
        return true
      end
    else
      if @lower_section[cat] == -1
        @lower_section[cat] = pot[cat]
        calculate_totals
        return true
      end
    end
    return false
  end
  
  def add_section(sect)
    sum = 0

    sect.each do |key, value|
      if value > -1
        sum += value
      end
    end

    return sum
  end

  def calculate_totals
    @upper_section_subtotal = add_section @upper_section
    
    @upper_section_total = @upper_section_subtotal
    @upper_section_bonus = @@bonus_value if @upper_section_subtotal >= 63
    @upper_section_total += @upper_section_bonus

    @lower_section_total = add_section @lower_section

    @grand_total = @upper_section_total + @lower_section_total
  end

  def get_all
    all = {
      "upper_subtotal" => @upper_section_subtotal,
      "upper_bonus"    => @upper_section_bonus,
      "upper_total"    => @upper_section_total,
      "lower_total"    => @lower_section_total,
      "grand_total"    => @grand_total
    }
    all.merge @upper_section.merge @lower_section
  end
end
