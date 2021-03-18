# frozen_string_literal: true

require_relative '../../../step/assign'

module Engine
  module Game
    module G18Neb
      module Step
        class Assign < Engine::Step::Assign
          def available_hex(entity, hex)
            if entity == @game.cattle_company
              assigned_hexes = @game.hexes.select { |h| h.assigned?(entity.id) }

              return assigned_hexes.include?(hex) unless assigned_hexes.empty?
            end

            super
          end

          def process_assign(action)
            entity = action.entity
            hex = action.target

            if hex.assigned?(entity.id) && entity == @game.cattle_company
              hex.remove_assignment!('AC')
              hex.assign!('AC', entity.owner)

              entity.owner.remove_assignment!('AC')
              entity.owner.assign!('AC')
              entity.close!

              @log << 'The cattle token is now closed'
            else
              super
              @log << 'The cattle token is open. To close the cattle token use the ability again' if entity == @game.cattle_company
            end
          end
        end
      end
    end
  end
end
