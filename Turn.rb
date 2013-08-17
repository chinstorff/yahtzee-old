
class Turn
  def initialize
    @dice     = [0,0,0,0,0]
    @preserve = [0,0,0,0,0]
    
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

  def roll
    @dice = roll_dice 5
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
