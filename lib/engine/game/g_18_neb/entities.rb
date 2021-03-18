# frozen_string_literal: true

module Engine
  module Game
    module G18Neb
      module Entities
        TRAINS = [
          {
            name: '2+2',
            distance: [{ 'nodes' => %w[town], 'pay' => 2 },
                       { 'nodes' => %w[town city offboard], 'pay' => 2 }],
            price: 100,
            rusts_on: '4+4',
            num: 5,
          },
          {
            name: '3+3',
            distance: [{ 'nodes' => %w[town], 'pay' => 3 },
                       { 'nodes' => %w[town city offboard], 'pay' => 3 }],
            price: 200,
            rusts_on: '6/8',
            num: 4,
          },
          {
            name: '4+4',
            distance: [{ 'nodes' => %w[town], 'pay' => 4 },
                       { 'nodes' => %w[town city offboard], 'pay' => 4 }],
            price: 300,
            rusts_on: '4D',
            num: 3,
          },
          {
            name: '5/7',
            distance: [{ 'nodes' => %w[city offboard town], 'pay' => 5, 'visit' => 7 }],
            price: 450,
            num: 2,
            events: [{ 'type' => 'close_companies' },
                     { 'type' => 'local_railroads_available' }],
          },
          {
            name: '6/8',
            distance: [{ 'pay' => 6, 'visit' => 8 }],
            price: 600,
            num: 2,
          },
          {
            name: '4D',
            # Can pick 4 best city or offboards, skipping smaller cities.
            distance: [{ 'nodes' => %w[city offboard], 'pay' => 4, 'visit' => 99, 'multiplier' => 2 },
                       { 'nodes' => ['town'], 'pay' => 99, 'visit' => 99 }],
            price: 900,
            num: 20,
            available_on: '6',
            discount: { '4' => 300, '5' => 300, '6' => 300 },
          },
        ].freeze

        COMPANIES = [
          {
            name: 'Denver Pacific Railroad',
            value: 20,
            revenue: 5,
            desc: 'Once per game, allows Corporation owner to lay or upgrade a tile in B8',
            sym: 'DPR',
            abilities: [
              {
                type: 'blocks_hexes',
                owner_type: 'player',
                remove: 3, # No tile may be placed on C7 until phase 3.
                hexes: ['B8'],
              },
              {
                type: 'tile_lay',
                owner_type: 'corporation',
                hexes: ['B8'],
                tiles: %w[3 4 5 80 81 82 83],
                count: 1,
                on_phase: 3,
              },
            ],
            color: nil,
          },
          {
            name: 'Morison Bridging Company',
            value: 40,
            revenue: 10,
            desc: 'Corporation owner gets two bridge discount tokens',
            sym: 'P2',
            abilities: [
              {
                type: 'tile_discount',
                discount: 60,
                terrain: 'water',
                owner_type: 'corporation',
                hexes: %w[K3 K5 K7 J8 L8 L10],
                count: 2,
                remove: 5,
              },
            ],
            color: nil,
          },
          {
            name: 'Armour and Company',
            value: 70,
            revenue: 15,
            desc: 'This company has two tokens. One represents an open cattle token and the other is a closed cattle token.'\
            ' One (but not both) of these tokens may be placed on any city or town, but not an off-board location.'\
            ' Either token increases the value of the city for the owning company by $20.'\
            ' The open cattle also increases the value of the city for all other companies by $10.'\
            ' If the president of the owning company places the closed cattle token, the private company is closed. If'\
            ' the open cattle token is placed, it may be replaced in a later operating round by the closed cattle token,'\
            ' closing the company.',
            sym: 'AC',
            abilities: [
              {
                type: 'assign_hexes',
                hexes: %w[B6 C3 C7 C9 E7 F6 G7 G11 H8 H10 I3 I5 J8 J12 K3 K7 L10],
                count: 2,
                owner_type: 'corporation',
                when: 'owning_corp_or_turn',
              },
              {
                type: 'assign_corporation',
                when: 'sold',
                count: 1,
                owner_type: 'corporation',
              },
            ],
            color: nil,
          },
          {
            name: 'Central Pacific Railroad',
            value: 100,
            revenue: 15,
            desc: 'May exchange for share in Colorado & Southern Railroad',
            sym: 'P4',
            abilities: [
                {
                  type: 'exchange',
                  corporations: ['C&S'],
                  owner_type: 'player',
                  when: 'owning_player_stock_round',
                  from: %w[ipo market],
                },
                {
                  type: 'blocks_hexes',
                  owner_type: 'player',
                  hexes: ['C7'],
                  # on_phase: 3,
                  remove: 3, # No tile may be placed on C7 until phase 3.
                },
              ],
            color: nil,
          },
          {
            name: 'Crédit Mobilier',
            value: 130,
            revenue: 5,
            desc: '$5 revenue each time ANY tile is laid or upgraded.',
            sym: 'P5',
            abilities: [
              {
                type: 'tile_income',
                income: 5,
              },
            ],
            color: nil,
          },
          {
            name: 'Union Pacific Railroad',
            value: 175,
            revenue: 25,
            desc: 'Comes with President\'s Certificate of the Union Pacific Railroad',
            sym: 'P6',
            abilities: [
              { type: 'shares', shares: 'UP_0' },
              { type: 'close', when: 'bought_train', corporation: 'UP' },
              { type: 'no_buy' },
            ],
            color: nil,
          },
        ].freeze

        CORPORATIONS = [
          {
            float_percent: 20,
            sym: 'UP',
            name: 'Union Pacific',
            logo: '18_neb/UP',
            tokens: [0, 40, 100],
            coordinates: 'K7',
            color: '#376FFF',
            always_market_price: true,
            reservation_color: nil,
          },
          {
            float_percent: 20,
            sym: 'CBQ',
            name: 'Chicago Burlington & Quincy',
            logo: '18_neb/CBQ',
            tokens: [0, 40, 100, 100],
            coordinates: 'L6',
            color: '#666666',
            always_market_price: true,
            reservation_color: nil,
          },
          {
            float_percent: 20,
            sym: 'CNW',
            name: 'Chicago & Northwestern',
            logo: '18_neb/CNW',
            tokens: [0, 40, 100],
            coordinates: 'L4',
            color: '#2C9846',
            always_market_price: true,
            reservation_color: nil,
          },
          {
            float_percent: 20,
            sym: 'DRG',
            name: 'Denver & Rio Grande',
            logo: '18_neb/DRG',
            tokens: [0, 40],
            coordinates: 'C9',
            color: '#D4AF37',
            text_color: 'black',
            always_market_price: true,
            reservation_color: nil,
          },
          {
            float_percent: 20,
            sym: 'MP',
            name: 'Missouri Pacific',
            logo: '18_neb/MP',
            tokens: [0, 40, 100],
            coordinates: 'L12',
            color: '#874301',
            reservation_color: nil,
            always_market_price: true,
          },
          {
            float_percent: 20,
            sym: 'C&S',
            name: 'Colorado & Southern',
            logo: '18_neb/CS',
            tokens: [0, 40, 100, 100],
            coordinates: 'A7',
            color: '#AE4A84',
            always_market_price: true,
            reservation_color: nil,
          },
          {
            float_percent: 40,
            sym: 'OLB',
            name: 'Omaha, Lincoln & Beatrice',
            logo: '18_neb/OLB',
            shares: [40, 20, 20, 20],
            tokens: [0, 40],
            coordinates: 'K7',
            max_ownership_percent: 100,
            color: '#F40003',
            type: 'local',
            always_market_price: true,
            reservation_color: nil,
          },
          {
            float_percent: 40,
            sym: 'NR',
            name: 'NebKota',
            logo: '18_neb/NR',
            shares: [40, 20, 20, 20],
            tokens: [0, 40],
            coordinates: 'C3',
            max_ownership_percent: 100,
            color: '#000000',
            type: 'local',
            always_market_price: true,
            reservation_color: nil,
          },
        ].freeze
      end
    end
  end
end
