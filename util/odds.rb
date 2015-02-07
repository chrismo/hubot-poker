#!/usr/bin/ruby

# I started over the weekend trying to do a proper probability analysis,
# based on this: http://en.wikipedia.org/wiki/Poker_probability
#
# But I didn't trust myself to get it right, and I realized it would be
# fairly easy to just enumerate all million possible hands and count 'em
# up.
#
# -- glv

def groupings(digits)
  digits.group_by{|d| d}.map{|k,a| a.size}.sort.reverse.join
end

def intervals(digits)
  sorted_digits = digits.sort
  pairs = sorted_digits[0,5].zip(sorted_digits[1,5])
  pairs.map{|a,b| b - a}.join
end

def group_hands(digits)
  case groupings(digits)
  when "111111" then :snowflake
  when "21111"  then :one_pair
  when "2211"   then :two_pair
  when "222"    then :three_pair
  when "3111"   then :one_triple
  when "33"     then :two_triples
  when "321"    then :crowded_house
  when "411"    then :four_of_a_kind
  when "42"     then :full_house
  when "51"     then :five_of_a_kind
  when "6"      then :six_of_a_kind
  end
end

def straight_hands(digits)
  case digits.sort.join
    # Since 0 behaves as an ace, these two cases are special:
  when "056789" then :six_straight
  when /0.6789/ then :five_straight
  else
    case intervals(digits)
    when "11111" then :six_straight
    when /1111/  then :five_straight
    end
  end
end

tally = Hash.new{|h,k| h[k] = []}

$capture_f = File.open('captured.txt', 'w')

0.upto(999_999) do |n|
  $stderr.print '.' if n.divmod(50_000)[1] == 0
  n6 = "%06d" % n
  digits = n6.split(//).map(&:to_i)
  raise "only #{digits.length} digits" if digits.length != 6

  straight_hand = straight_hands(digits)
  tally[straight_hand] << n6 and next if straight_hand

  group_hand = group_hands(digits)
  tally[group_hand] << n6 if group_hand
end

sorted_keys = tally.keys.sort_by{|k| tally[k].size}
sorted_keys.each do |k|
  v = tally[k]
  puts "#{k}: #{v.size}"
end

puts "total: #{tally.values.inject(0){|sum, v| sum + v.size}}"
