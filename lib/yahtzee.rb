require 'grape'

module Yahtzee
  class API < Grape::API
    version 'v1.1', using: :header, vendor: :yahtzee
    
  end
  
  class Controller
    def initialize
      @sc = Scorecard.new
      
      @turns = Array.new
      13.times { @turns.push Turn.new }
      @current_turn = 0

      map = {
        :reroll => ->(a) {

        },
        :score => ->(a) {

        },
        :get_data => ->() {

        }
      }
      
      def run f, a
        map[f].call a
      end
    end
  end
 
  class Turn
    def initialize
      @dice     = roll_dice 5
      
      @reroll_count = 0
      @reroll_max   = 2
      
      @joker = false
    end

    def roll_dice(num_dice)
      a = []
      
      num_dice.times do
        a.push Random.rand(6) + 1
      end
      
      return a
    end

    def can_reroll?
      return true if @reroll_count < @reroll_max
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

    def joker?
      return @joker
    end

    def set_joker value
      @joker = value
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
      @lower_section = [ :3_of_a_kind, :4_of_a_kind, :full_house, :small_straight,
                         :large_straight, :yahtzee, :yahtzee_bonus :chance ]
      
      @categories = { 
        :aces   => -1, 
        :twos   => -1,
        :threes => -1,
        :fours  => -1,
        :fives  => -1,
        :sixes  => -1,
        :upper_section_bonus => 0,

        :3_of_a_kind    => -1,
        :4_of_a_kind    => -1,
        :full_house     => -1,
        :small_straight => -1,
        :large_straight => -1,
        :yahtzee        => -1,
        :chance         => -1,
        :yahtzee_bonus  => 0,
        
        :upper_section_subtotal = 0
        :upper_section_total    = 0
        :lower_section_total    = 0
        
        :grand_total = 0
      }
    end

    def calculate_dice(dice, joker)
      cats = {
        :aces   => 0,
        :twos   => 0,
        :threes => 0,
        :fours  => 0,
        :fives  => 0,
        :sixes  => 0,
        :3_of_a_kind    => 0,
        :4_of_a_kind    => 0,
        :full_house     => 0,
        :small_straight => 0,
        :large_straight => 0,
        :yahtzee        => 0,
        :chance         => 0
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
      
      
      cats[:3_of_a_kind]    = sum if (max >= 3 || joker)
      cats[:4_of_a_kind]    = sum if (max >= 4 || joker)
      cats[:full_house]     = @@full_house_value if (max == 3 and smax == 2 || joker)
      cats[:small_straight] = @@small_straight_value if (small || joker)
      cats[:large_straight] = @@large_straight_value if (large || joker)
      cats[:yahtzee]        = @@yahtzee_value if (max >= 5 || joker)
      cats[:chance]         = sum
      
      return cats
    end

    def score(cat, joker)
      pot = calculate_dice @turns[@current_turn].get_dice, joker
      
      case cat
      when (:aces or :twos or :threes or :fours or :fives or :sixes)
        if @upper_section[cat] == -1
          @upper_section[cat] = pot[cat]
          calculate_totals
          return true
        end
      when :yahtzee
        case @upper_section[cat]
        when -1
          @lower_section[cat] = pot[cat]
          calculate_totals
          return true
        when @@yahtzee_value
          @lower_section[:yahtzee_bonus] += @@yahtzee_bonus_value
        end
        which = @upper_section[@categories[get_turn.get_dice[0]]]
        if which == -1 
          return score which
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

      @categories.each do |key, value|
        if sect.include? key && value > -1
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
