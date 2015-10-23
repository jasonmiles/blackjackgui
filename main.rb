require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
  def calculate_total(cards) # cards is [["H", "3"], ["D", "J"], ... ]
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    #correct for Aces
    arr.select{|element| element == "A"}.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end
end

before do
  @show_hit_or_stay_buttons = true
  @player_stay = false
  @show_dealer_button = false
  @dealer_hit = false
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  player_name = params[:player_name]

  player_name.each_char do |char| 
    if /[a-zA-Z0-9]/.match(char) == false
      @error = "Name contains illegal characters. Please enter valid name."
      halt erb(:new_player)
    end
  end  

  if player_name.empty?
    @error = "Name cannot be empty. Please enter valid name."
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle! # [ ['H', '9'], ['C', 'K'] ... ]

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  if session[:player_cards] == 21
    @success = "#{session[:player_name]} got blackjack. #{session[:player_name]} wins!"
    @show_hit_or_stay_buttons = false
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  
  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = "Congratulations! #{session[:player_name]} hit blackjack!"
    @show_hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "Sorry, it looks like #{session[:player_name]} busted."
    @show_hit_or_stay_buttons = false
  end

  erb :game, layout:false
end


get '/game/dealer/turn' do
  @player_stay = true
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])
  player_name = session[:player_name]
  if dealer_total > 21
    @success = "Dealer is bust. #{player_name} wins!"
  elsif dealer_total == 21 && player_total < 21
    @error = "Dealer got blackjack. Dealer wins!"
  elsif dealer_total >= 17 && dealer_total > player_total
    @error = "Dealer has #{dealer_total} and #{player_name} has #{player_total}. Dealer wins!"
  elsif dealer_total >= 17 && dealer_total < player_total
    @error = "Dealer has #{dealer_total} and #{player_name} has #{player_total}. #{player_name} wins!"
  elsif dealer_total >= 17 && dealer_total == player_total
    @success = "Dealer and #{player_name} both have #{dealer_total}. It's a tie!"
  elsif dealer_total < 17
    @show_dealer_button = true
  end
  erb :game 
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer/turn'
end

