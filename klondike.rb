require 'colorize'

module Klondike

    module Suit
        SPADES = 1
        CLUBS = 2
        DIAMONDS = 3
        HEARTS = 4
    end

    module Rank
        ACE = 1
        TWO = 2
        THREE = 3
        FOUR = 4
        FIVE = 5
        SIX = 6
        SEVEN = 7
        EIGHT = 8
        NINE = 9
        TEN = 10
        JACK = 11
        QUEEN = 12
        KING = 13
    end

    class Card
        include Klondike::Suit
        include Klondike::Rank
        def initialize(suit, rank)
            @suit = suit
            @rank = rank
            @face_up = false
        end

        def suit
            return @suit
        end

        def rank
            return @rank
        end

        def flip
            @face_up = !@face_up
        end

        def black?
            return [SPADES, CLUBS].include? @suit
        end
        
        def red?
            return [DIAMONDS, HEARTS].include? @suit
        end

        def face_up?
            return @face_up
        end

        def face_down?
            return !@face_up
        end

        def ==(other)
            return false unless other.is_a?(Card)
            return @suit == other.suit && @rank == other.rank
        end

        def to_s
            str = ""
            case @suit
            when SPADES
                str += "\u2660"
            when CLUBS
                str += "\u2663"
            when DIAMONDS
                str += "\u2666"
            when HEARTS
                str += "\u2665"
            end
            case @rank
            when ACE
                str += "A"
            when JACK
                str += "J"
            when QUEEN
                str += "Q"
            when KING
                str += "K"
            when TEN
                str += "0"
            else
                str += @rank.to_s
            end
            str = str.encode('utf-8')
            str = str.red if red?
            str
        end
    end

    class Table
        include Klondike::Suit
        include Klondike::Rank
        def initialize
            @foundations = [
                FoundationPile.new(SPADES),
                FoundationPile.new(CLUBS),
                FoundationPile.new(DIAMONDS),
                FoundationPile.new(HEARTS)
            ]
            @tableau = [
                TableauPile.new,
                TableauPile.new,
                TableauPile.new,
                TableauPile.new,
                TableauPile.new,
                TableauPile.new,
                TableauPile.new
            ]
            @stock = StockPile.new
            @discard = DiscardPile.new
            deal
        end

        def deal
            @stock.shuffle
            (0..6).each do |x|
                @tableau[x..6].each do |pile|
                    pile.push @stock.pop
                end
            end
            @tableau.each(&:flip_top)
        end

        def game_over?
            @foundations.map(&:done?).all?
        end

        def ascii
            # clunky, because layout
            strs = ["","",""]
            (0..2).each do |row|
                @foundations.each do |f|
                    strs[row] += f.ascii[row] + " "
                end
                strs[row] += "     "
                strs[row] += @stock.ascii[row] + " "
                strs[row] += @discard.ascii[row] + " "
            end
            strs += [""]
            tableau_asciis = @tableau.map(&:ascii)
            max_length = tableau_asciis.map(&:length).max
            (0..(max_length - 1)).each do |row|
                new_row = ""
                tableau_asciis.each do |ta|
                    begin
                        new_row += ta[row] + " "
                    rescue NoMethodError
                        new_row += "     "
                    end
                end
                strs += [new_row]
            end
            strs
        end

        def to_s
            ascii
        end

        # lame intepreter line interface for testing
        def move(from, card, to)
            from_pile = parse_pile(from)
            to_pile = parse_pile(to)
            result = from_pile.move(card, to_pile)
            puts ascii
            result
        end

        def draw
            @stock.draw(@discard)
            puts ascii
        end

        def show
            puts ascii
        end

        # slightly less lame text interface
        def parse_move(str)
            case str[0]
            when "1","2","3","4","5","6","7"
                idx = str[0].to_i - 1
                from = @tableau[idx]
                case str[1]
                when "1","2","3","4","5","6","7"
                    to = @tableau[str[1].to_i - 1]
                    num = find_number(from,to)
                    raise "NOPE #{str}" unless num
                when "F","f"
                    num = 1
                    to = find_foundation(from)
                else
                    puts "try again #{str}"
                end
                from.move(num, to)
            when "D", "d"
                if str.length == 2
                    @stock.draw(@discard)
                else
                    case str[1]
                    when "1","2","3","4","5","6","7"
                        to = @tableau[str[1].to_i-1]
                        @discard.move(1, to)
                    when "F","f"
                        to = find_foundation(@discard)
                        @discard.move(1, to)
                    else
                        raise "NOPE #{str}"
                    end
                end
            end
        end

        # game state for ai
        def game_state
        end

        # debugging only
        # TODO REMOVE ME
        def tableau
            @tableau
        end
        def stock
            @stock
        end
        def discard
            @discard
        end
        def foundations
            @foundations
        end
        
        private

        def find_number(from,to)
            return from.find_rank(KING) if to.empty?
            from.find_rank(to.top_card.rank - 1)
        end

        def find_foundation(from)
            case from.top_card.suit
            when SPADES
                @foundations[0]
            when CLUBS
                @foundations[1]
            when DIAMONDS
                @foundations[2]
            when HEARTS
                @foundations[3]
            end
        end

        def parse_pile(pile_name)
            case pile_name[0]
            when "F"
                idx = pile_name[1].to_i - 1
                if idx < 0 || idx > 3
                    raise "NOPE NOPE NOPE #{pile_name} isn't a pile\nF1-4 T1-7 S D"
                end
                @foundations[idx]
            when "T"
                idx = pile_name[1].to_i - 1
                if idx < 0 || idx > 6
                    raise "NOPE NOPE NOPE #{pile_name} isn't a pile\nF1-4 T1-7 S D"
                end
                @tableau[idx]
            when "S"
                @stock
            when "D"
                @discard
            else
                raise "NOPE NOPE NOPE #{pile_name} isn't a pile\nF1-4 T1-7 S D"
            end
        end

    end

    class Pile
        def initialize
            @cards = []
        end

        def push(card)
            @cards.push card
        end

        def pop
            @cards.pop
        end

        def allowed?(card)
            true
        end

        def top_card
            @cards.last
        end

        def num_face_up_cards
            @cards.select(&:face_up?).length
        end

        def num_face_down_cards
            @cards.select(&:face_down?).length
        end

        def empty?
            @cards.empty?
        end

        def ascii
            strs = ["+--+","","+--+"]
            
            if empty?
                strs[1] = "|  |"
            elsif top_card.face_down?
                strs[1] = "|XX|"
            else
                strs[1] = "|" + top_card.to_s + "|"
            end
            strs
        end

        def move(num_cards, target_pile)
            key_card = @cards[num_cards * -1]
            return false if key_card.face_down?
            return false if !target_pile.allowed?(key_card)
            target_pile.add @cards.slice!(num_cards * -1, num_cards)
            return true
        end

        def add(cards)
            @cards += cards
        end

    end

    class FoundationPile < Pile
        include Klondike::Rank
        def initialize(suit)
            super()
            @suit = suit
        end

        def allowed?(card)
          next_card && next_card == card
        end

        def next_card
            if empty?
                Card.new(@suit,ACE)
            elsif @cards.length == 13
                return nil
            else
                Card.new(@suit, top_card.rank + 1)
            end
        end

        def done?
            @cards.length == 13
        end
    end

    class TableauPile < Pile
        include Klondike::Rank
        def allowed?(card)
            if empty? 
                return card.rank == KING
            end
            return false if top_card.rank == ACE
            return unless top_card.rank - 1 == card.rank
            return card.red? if top_card.black?
            return card.black? if top_card.red?
        end

        def flip_top
            top_card.flip if top_card.face_down?
        end

        def move(num,to)
            super
            flip_top unless empty?
        end

        def find_rank(rank)
            target = @cards.select {|c| c.face_up? && c.rank == rank }.first
            return @cards.length - @cards.find_index(target)
        end

        def ascii
            return super if empty?
            strs = []
            @cards.each do |card|
                strs += ["+--+"]
                strs += ["|" + card.to_s + "|"] if card.face_up?
            end
            strs += ["|XX|"] if strs.last == "+--+"
            strs += ["+--+"]
        end
    end

    class StockPile < Pile
        def initialize
            super
            (1..4).each do |suit|
                (1..13).each do |rank|
                    @cards << Card.new(suit,rank)
                end
            end
        end

        def shuffle
            @cards.shuffle!
        end

        def available?(card)
            false
        end

        def draw(discard_pile)
            if empty?
                while !discard_pile.empty?
                    card = discard_pile.pop
                    card.flip
                    @cards.push card
                end
            end
            card = @cards.pop
            card.flip
            discard_pile.push card
        end
    end

    class DiscardPile < Pile
    end

    class Player
        def initialize
            @table = Table.new
            @table.show
            game_loop
        end

        def game_loop
            while true 
                print "> "
                input = gets
                @table.parse_move(input)
                @table.show
                break if @table.game_over?
            end
            puts "You finished congrats!"
        end

    end
end

Klondike::Player.new


