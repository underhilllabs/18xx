# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module G18Rhl
      module Meta
        include Game::Meta

        DEV_STAGE = :prealpha

        GAME_DESIGNER = 'Wolfram Janish'
        GAME_INFO_URL = 'https://github.com/tobymao/18xx/wiki/18Rhl'
        GAME_LOCATION = 'Rhineland Province'
        GAME_PUBLISHER = :marflow_games
        GAME_RULES_URL = 'https://18xx-marflow-games.de/english-new/games/18rhl.html'

        PLAYER_RANGE = [3, 6].freeze
      end
    end
  end
end
