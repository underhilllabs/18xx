# frozen_string_literal: true

require_relative 'entities'
require_relative 'map'
require_relative 'meta'
require_relative '../base'
require_relative '../g_1846/step/dividend'

module Engine
  module Game
    module G18Neb
      class Game < Game::Base
        include_meta(G18Neb::Meta)
        include G18Neb::Entities
        include G18Neb::Map

        register_colors(black: '#37383a',
                        orange: '#f48221',
                        brightGreen: '#76a042',
                        red: '#d81e3e',
                        turquoise: '#00a993',
                        blue: '#0189d1',
                        brown: '#7b352a')

        CURRENCY_FORMAT_STR = '$%d'

        BANK_CASH = 6000

        CERT_LIMIT = { 2 => 21, 3 => 15, 4 => 13 }.freeze

        STARTING_CASH = { 2 => 650, 3 => 450, 4 => 350 }.freeze

        CAPITALIZATION = :incremental
        # However 10-share corps that start in round 5: if their 5th share purchase
        #  - get 5x starting value
        #  - the remaining 5 shares are placed in bank pool

        MUST_SELL_IN_BLOCKS = true

        SELL_BUY_ORDER = :sell_buy
        # is this first to pass: first, second: second.. yes
        NEXT_SR_PLAYER_ORDER = :first_to_pass
        MIN_BID_INCREMENT = 5

        TILE_TYPE = :lawson

        MARKET = [
          %w[82 90 100 110 122 135 150 165 180 200 220 270 300 330 360 400],
          %w[75 82 90 100p 110 122 135 150 165 180 200 220 270 300 330 360],
          %w[70 75 82 90p 100 110 122 135 150 165 180 200 220],
          %w[65 70 75 82p 90 100 110 122 135 150 165],
          %w[60 65 70 75p 82 90 100 110],
          %w[50 60 65 70p 75 82],
          %w[40 50 60 65 70],
          %w[30 40 50 60],
        ].freeze

        PHASES = [
          {
            name: '2',
            train_limit: 4,
            tiles: [:yellow],
            operating_rounds: 2,
            status: ['can_buy_morison'],
          },
          {
            name: '3',
            on: '3+3',
            train_limit: 4,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '4',
            on: '4+4',
            train_limit: 3,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '5',
            on: '5/7',
            train_limit: 3,
            tiles: %i[yellow green brown],
            operating_rounds: 2,
          },
          {
            name: '6',
            on: '6/8',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
          {
            name: 'D',
            on: '4D',
            train_limit: 2,
            tiles: %i[yellow green brown gray],
            operating_rounds: 3,
          },
        ].freeze

        LAYOUT = :flat

        EBUY_PRES_SWAP = false # allow presidential swaps of other corps when ebuying
        EBUY_OTHER_VALUE = false # allow ebuying other corp trains for up to face
        HOME_TOKEN_TIMING = :float # not :operating_round
        # Two tiles can be laid, only one upgrade
        TILE_LAYS = [{ lay: true, upgrade: true }, { lay: true, cost: 20, upgrade: :not_if_upgraded }].freeze

        def setup
          @corporations, @future_corporations = @corporations.partition { |corporation| corporation.type != :local }
        end

        def omaha_upgrade(to, from)
          return to == '229' if from == 'yellow'
          return to == '230' if from == 'green'
          return to == '231' if from == 'brown'
        end

        def denver_upgrade(to, from)
          return to == '407' if from == :yellow
          return to == '234' if from == :green
          return to == '116' if from == :brown
        end

        def upgrades_to?(from, to, special = false)
          case from.hex.name
          when OMAHA_HEX
            return omaha_upgrade(to.name, from.color)
          when DENVER_HEX
            return denver_upgrade(to.name, from.color)
          when LINCOLN_HEX
            return GREEN_CITIES.include?(to.name) if from.color == :yellow
            return to.name == '233' if from.color == :green
            return to.name == '409' if from.color == :brown
          when CHADRON_HEX
            return GREEN_CITIES.include?(to.name) if from.color == :yellow
            return to.name == '233' if from.color == :green
            return to.name == '192' if from.color == :brown
          else
            return GREEN_CITIES.include?(to.name) if YELLOW_TOWNS.include? from.hex.tile.name
            return BROWN_CITIES.include?(to.name) if GREEN_CITIES.include? from.hex.tile.name
            return GRAY_CITIES.include?(to.name) if BROWN_CITIES.include? from.hex.tile.name
          end

          super
        end

        def all_potential_upgrades(tile, tile_manifest: false)
          upgrades = super
          return upgrades unless tile_manifest

          upgrades |= GREEN_CITIES if YELLOW_TOWNS.include?(tile.name)
          upgrades
        end

        # borrowed from 1846 for initial reverse corporation order
        def operating_order
          corporations = @corporations.select(&:floated?)
          if @turn == 1 && (@round_num || 1) == 1
            corporations.sort_by! do |c|
              sp = c.share_price
              [sp.price, sp.corporations.find_index(c)]
            end
          else
            corporations.sort!
          end
          corporations
        end

        def event_local_railroads_available!
          @log << 'Local railroads are now available!'

          @corporations += @future_corporations
          @future_corporations = []
        end

        def init_round
          Round::Auction.new(self, [
            Engine::Step::CompanyPendingPar,
            G18Neb::Step::PriceFindingAuction,
          ])
        end

        def stock_round
          Round::Stock.new(self, [
            Engine::Step::DiscardTrain,
            Engine::Step::Exchange,
            Engine::Step::HomeToken,
            Engine::Step::SpecialTrack,
            Engine::Step::BuySellParShares,
          ])
        end

        def operating_round(round_num)
          Round::Operating.new(self, [
            Engine::Step::Bankrupt,
            Engine::Step::Exchange,
            Engine::Step::BuyCompany,
            Engine::Step::Track,
            Engine::Step::Token,
            Engine::Step::Route,
            # Engine::Step::Dividend,
            G1846::Step::Dividend,
            Engine::Step::DiscardTrain,
            Engine::Step::BuyTrain,
            [Engine::Step::BuyCompany, blocks: true],
          ], round_num: round_num)
        end
      end
    end
  end
end
