#require 'grape'

module Yahtzee
 # class API < Grape::API
 #   version 'v1.1', using: :header, vendor: :yahtzee
 # end
  
  class Controller
    def initialize
      @message = ""
      
      @sc = Scorecard.new
      
      @turn = Turn.new
    end
    
    def roll
      @turn = Turn.new
    end
    
    def reroll a
      @turn.reroll a
    end
    
    def score a 
      case @sc.score a, @turn.get_dice, @turn.joker?
      when -1
        return -1
      when 0
        @turn.set_joker true
        return 0
      else
        next_turn
        return 1
      end
    end
    
    def next_turn
      @turn = Turn.new
    end

    def get_dice
      return @turn.get_dice
    end

    def set_dice a
      @turn.set_dice a
    end
    
    def get_data
      return @sc.get_cats
    end
      
    def get_potential
      return sc.calculate_dice @turn.get_dice
    end    
  end

  class Turn
    def initialize
      @dice     = roll_dice 5
      
      @reroll_count = 0
      @reroll_max   = 2
      
      @joker = false
      @done  = false
    end

    def roll_dice num_dice
      a = []
      
      num_dice.times do
        a.push Random.rand(6) + 1
      end
      
      return a
    end

    def can_reroll?
      return true if @reroll_count < @reroll_max
    end
    
    def set_preserve pr
      @preserve = pr
    end
    
    def set_dice a
      @dice = a
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

    def joker?
      return @joker
    end

    def set_joker value
      @joker = value
    end

    def done?
      return @done
    end

    def finish
      @done = true
    end
    
    def reroll preserve # [1,1,1,1,1] preserves all
      if @reroll_count < @reroll_max
        a = roll_dice 5
        5.times do |i|
          if preserve[i] == 0
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
      @upper_section = [ :aces, :twos, :threes, :fours, :fives, :sixes ]
      @lower_section = [ :three_of_a_kind, :four_of_a_kind, :full_house, :small_straight,
                         :large_straight, :yahtzee, :chance, :yahtzee_bonus ]
      
      @categories = { 
        :aces   => -1, 
        :twos   => -1,
        :threes => -1,
        :fours  => -1,
        :fives  => -1,
        :sixes  => -1,
        :upper_section_bonus => 0,

        :three_of_a_kind => -1,
        :four_of_a_kind  => -1,
        :full_house      => -1,
        :small_straight  => -1,
        :large_straight  => -1,
        :yahtzee         => -1,
        :chance          => -1,
        :yahtzee_bonus   => 0,
        
        :upper_section_subtotal => 0,
        :upper_section_total    => 0,
        :lower_section_total    => 0,
        
        :grand_total => 0
      }
    end

    def calculate_dice dice, joker
      cats = {
        :aces   => 0,
        :twos   => 0,
        :threes => 0,
        :fours  => 0,
        :fives  => 0,
        :sixes  => 0,
        :three_of_a_kind => 0,
        :four_of_a_kind  => 0,
        :full_house      => 0,
        :small_straight  => 0,
        :large_straight  => 0,
        :yahtzee         => 0,
        :chance          => 0
      }
      
      # upper section
      dice.each do |i|
        case i
        when 1
          cats[:aces]   += 1
        when 2
          cats[:twos]   += 2
        when 3
          cats[:threes] += 3
        when 4
          cats[:fours]  += 4
        when 5
          cats[:fives]  += 5
        when 6
          cats[:sixes]  += 6
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
      
      
      cats[:three_of_a_kind] = sum if (max >= 3 || joker)
      cats[:four_of_a_kind]  = sum if (max >= 4 || joker)
      cats[:full_house]      = @@full_house_value if (max == 3 and smax == 2 || joker)
      cats[:small_straight]  = @@small_straight_value if (small || joker)
      cats[:large_straight]  = @@large_straight_value if (large || joker)
      cats[:yahtzee]         = @@yahtzee_value if (max >= 5 || joker)
      cats[:chance]          = sum
      
      return cats
    end

    def score cat, dice, joker
      pot = calculate_dice dice, joker
      
      case cat
      when (:aces or :twos or :threes or :fours or :fives or :sixes)
        if @categories[cat] == -1
          @categories[cat] = pot[cat]
          calculate_totals
          return 1
        end
      when :yahtzee
        return -1 if joker
        case @categories[:yahtzee]
        when -1
          @categories[:yahtzee] = pot[:yahtzee]
          calculate_totals
          return 1
        when @@yahtzee_value
          @categories[:yahtzee_bonus] += @@yahtzee_bonus_value
        end
        which = @upper_section[dice[0]-1]
        if @categories[which] == -1 
          return score which, dice, joker
        end
        return 0
      else
        if @categories[cat] == -1
          @categories[cat] = pot[cat]
          calculate_totals
          return 1
        end
      end
      return -1
    end
    
    def add_section sect
      sum = 0

      @categories.each do |key, value|
        if (sect.include? key) && value > -1
          sum += value
        end
      end

      return sum
    end

    def calculate_totals
      @categories[:upper_section_subtotal] = add_section @upper_section
      
      @categories[:upper_section_total] = @categories[:upper_section_subtotal]
      @categories[:upper_section_bonus] = @@bonus_value if @categories[:upper_section_subtotal] >= 63
      @categories[:upper_section_total] += @categories[:upper_section_bonus]

      @categories[:lower_section_total] = add_section @lower_section

      @categories[:grand_total] = @categories[:upper_section_total] + @categories[:lower_section_total]
    end

    def get_cats
      return @categories
    end
  end
end
