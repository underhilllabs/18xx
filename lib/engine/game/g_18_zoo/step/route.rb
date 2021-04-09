# frozen_string_literal: true

require_relative 'choose_ability_on_or'

module Engine
  module Game
    module G18ZOO
      module Step
        class Route < Engine::Step::Route
          include Engine::Game::G18ZOO::ChooseAbilityOnOr

          def actions(entity)
            return ['choose_ability'] if entity.company? && can_choose_ability?(entity)

            super
          end

          def process_run_routes(action)
            super

            # Clean the 'A spoonful of sugar' usage
            ability = @game.abilities(action.entity, :increase_distance_for_train)
            action.entity.remove_ability(ability) if ability

            return unless @game.two_barrels.all_abilities.empty?

            # Close 'Two Barrels' if used and no more usage
            @game.two_barrels.close!
            @log << "'#{@game.two_barrels.name}' is closed"
          end

          def train_name(entity, train)
            additional_distance = entity && @game.abilities(entity, :increase_distance_for_train)&.distance || 0

            train.name + (additional_distance.positive? ? " (+#{additional_distance})" : '')
          end

          def chart(entity)
            threshold = @game.threshold(entity)
            bonus_hold = chart_price(entity.share_price)
            bonus_pay = chart_price(@game.share_price_updated(entity, threshold))
            [
              ["Threshold#{nbsp(4)}Move", 'Bonus'],
              ["withhold#{nbsp(6)}1 ←", ''],
              ["< #{threshold}#{nbsp(13)}", bonus_hold.to_s],
              ["≥ #{threshold}#{nbsp(6)}1 →", bonus_pay.to_s],
            ]
          end

          private

          def chart_price(share_price)
            bonus_share = @game.bonus_payout_for_share(share_price)
            bonus_president = @game.bonus_payout_for_president(share_price)
            "#{@game.format_currency(bonus_share)}"\
              "#{bonus_president.positive? ? '+' + @game.format_currency(bonus_president) : ''}"
          end

          # TODO: check if other solution with three columns
          def nbsp(time)
            ' ' * time
          end

          def can_choose_ability?(company)
            entity = @game.current_entity
            return false unless entity.corporation?

            return true if @game.can_choose_two_barrels?(entity, company)
            return true if @game.can_choose_sugar?(entity, company)

            false
          end
        end
      end
    end
  end
end
