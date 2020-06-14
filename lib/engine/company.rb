# frozen_string_literal: true

require_relative 'ownable'

module Engine
  class Company
    include Ownable

    attr_accessor :desc, :revenue, :discount
    attr_reader :name, :sym, :value

    def initialize(sym:, name:, value:, revenue: 0, desc: '', abilities: [], **opts)
      @sym = sym
      @name = name
      @value = value
      @desc = desc
      @revenue = revenue
      @discount = opts[:discount] || 0
      @closed = false

      @abilities = abilities
        .map(&:dup)
        .group_by { |ability| ability[:type] }
        .transform_values!(&:first)
    end

    def abilities(type)
      return nil unless (ability = @abilities[type])

      correct_owner_type =
        case ability[:owner_type]
        when :player
          !owner || owner.player?
        when :corporation
          owner&.corporation?
        when nil
          true
        end

      correct_owner_type ? ability : nil
    end

    def remove_ability(type)
      @abilities.delete(type)
    end

    def remove_ability_when(time)
      @abilities.dup.each do |type, ability|
        remove_ability(type) if ability[:when] == time
      end
    end

    def all_abilities
      @abilities.map { |type, _| abilities(type) }.compact
    end

    def id
      @sym
    end

    def min_bid
      @value - @discount
    end

    def min_price
      @value / 2
    end

    def max_price
      @value * 2
    end

    def close!
      @closed = true
      return unless owner

      owner.companies.delete(self)
      @owner = nil
    end

    def closed?
      @closed
    end

    def player?
      false
    end

    def company?
      true
    end

    def corporation?
      false
    end

    def inspect
      "<#{self.class.name}: #{id}>"
    end
  end
end
