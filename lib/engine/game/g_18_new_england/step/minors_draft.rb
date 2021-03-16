# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18NewEngland
      module Step
        class MinorsDraft < Engine::Step::Base
          attr_reader :corporations, :choices, :minor_slots

          ACTIONS = %w[float reserve].freeze
          ACTIONS_WITH_PASS = %w[float reserve pass relinquish].freeze

          def setup
            @companies = @game.companies.sort_by { @game.rand }
            @choices = Hash.new { |h, k| h[k] = [] }
            @draw_size = entities.size + 2
            build_minor_slots
          end

          def build_minor_slots
            %i[50 55 60 65 70].each do |price|
              @minor_slots[price] = []
              %i[top bottom].each do |pos|
                @minor_slots[price][pos] = :available
              end
            end
          end

          def slot_available(par, position)
            @minor_slots[par][position] == :available
          end

          def pass_description
            'Pass (Buy)'
          end

          def available
            @companies.first(@draw_size)
          end

          def may_purchase?(_company)
            false
          end

          def may_choose?(_company)
            true
          end

          def auctioning; end

          def bids
            {}
          end

          def blank?(company)
            company.name.include?('Pass')
          end

          def all_blank?
            @companies.size < @draw_size && available.all? { |company| blank?(company) }
          end

          def only_one_company?
            @companies.one? && !blank?(@companies[0])
          end

          def visible?
            only_one_company?
          end

          def players_visible?
            false
          end

          def name
            'Draft Round'
          end

          def description
            'Draft Companies'
          end

          def finished?
            all_blank? || @companies.empty?
          end

          def actions(entity)
            return [] if finished?

            actions = only_one_company? ? ACTIONS_WITH_PASS : ACTIONS

            entity == current_entity ? actions : []
          end

          def process_pass(_action)
            raise GameError, 'Cannot pass' unless only_one_company?

          end

          def process_float(action)
            choose_company(action.entity, action.company)
            @round.next_entity_index!
            action_finalized
          end

          def process_reserve(action)
            company = action.company
            player = action.entity
            available_companies = available
            @reserved[player] << company 
            available_companies.delete(company)
          end

          def process_relinquish(action)
          end

          def choose_company(player, company)
            available_companies = available

            raise GameError, "Cannot choose #{company.name}" unless available_companies.include?(company)

            @choices[player] << company

            if only_one_company?
              @log << "#{player.name} chooses #{company.name}"
              @companies.clear
            else
              @log << "#{player.name} chooses a company"
              @companies -= available_companies
              discarded = available_companies.sort_by { @game.rand }
              discarded.delete(company)
              @companies.concat(discarded)
            end

            company.owner = player
          end

          def action_finalized
            return unless finished?

            @round.reset_entity_index!

            @choices.each do |player, companies|
              companies.each do |company|
                if blank?(company)
                  company.owner = nil
                  @log << "#{player.name} chose #{company.name}"
                else
                  company.owner = player
                  player.companies << company
                  price = company.min_bid
                  player.spend(price, @game.bank) if price.positive?

                  float_minor(company)

                  @log << "#{player.name} buys #{company.name} for #{@game.format_currency(price)}"
                end
              end
            end
          end

          def float_minor(company)
            return unless (minor = @game.minors.find { |m| m.id == company.id })

            minor.owner = company.player
            @game.bank.spend(company.treasury, minor)
            minor.float!
          end

          def committed_cash(player, show_hidden = false)
            return 0 unless show_hidden

            choices[player].sum(&:min_bid)
          end
        end
      end
    end
  end
end
