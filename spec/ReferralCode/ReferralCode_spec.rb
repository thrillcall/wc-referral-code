# -*- encoding: utf-8 -*-
require File.expand_path("../../spec_helper", __FILE__)
require "ReferralCode"

describe "ReferralCodeTest" do

  before do
    $redis.flushdb
    @rc = ReferralCode.new($redis)
    @person_id  = rand(10000000)
    @user_id    = rand(10000000)
  end

  it "should have a clean redis database" do
    $redis.keys.size.must_equal(0)
  end

  it "should raise an exception when no argument is passed" do
    lambda { ReferralCode.new }.must_raise(ArgumentError)
  end

  it "should instantiate a ReferralCode object" do
    @rc.must_be_instance_of ReferralCode
  end

  it "should create a referral code" do
    @rc.create_person_code(@person_id).wont_be_empty
  end

  it "should not create a new referral code for a person who has already one" do
    code  = @rc.create_person_code(@person_id)
    new_c = @rc.create_person_code(@person_id).must_equal(code)
  end

  it "should create the reverse lookup for the referral code" do
    code = @rc.create_person_code(@person_id)
    @rc.get_person_with_code(code).must_equal(@person_id)
  end

  it "should retrieve the referral code of a person" do
    code  = @rc.create_person_code(@person_id)
    new_c = @rc.get_person_code(@person_id)
    new_c.wont_be_empty
    new_c.must_equal(code)
  end

  it "should retrieve the ID of a person with the referral code" do
    code = @rc.create_person_code(@person_id)
    @rc.get_person_with_code(code).must_equal(@person_id)
  end

  it "should add a person to the list of persons who have used the same referral code" do
    code = @rc.create_person_code(@person_id)
    @rc.add_person_to_referral_list(@user_id, code).must_equal(true)
  end

  it "should not add the person to the list if he is the owner of the referral code" do
    code = @rc.create_person_code(@person_id)
    @rc.add_person_to_referral_list(@person_id, code).must_equal(false)
  end

  it "should get the list of persons who have used a referral code" do
    code = @rc.create_person_code(@person_id)
    @rc.add_person_to_referral_list(@user_id, code)
    @rc.get_list_referral_code(code).size.must_equal(1)
  end

  it "should set up a reciprocal referral" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    first_code.wont_equal(second_code)
    @rc.associate_codes(first_code, second_code).must_equal(true)
    @rc.get_list_referral_code(first_code).size.must_equal(1)
    @rc.get_list_referral_code(first_code).first.must_equal(@user_id)
    @rc.get_list_referral_code(second_code).size.must_equal(1)
    @rc.get_list_referral_code(second_code).first.must_equal(@person_id)
  end

  it "should add the codes involved in a reciprocal referral to the list of codes that have credits" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    first_code.wont_equal(second_code)
    @rc.associate_codes(first_code, second_code).must_equal(true)
    list = @rc.get_codes_with_credits
    list.wont_be_empty
    list.must_be_instance_of Array
    list.length.must_equal(2)
    (list.include? first_code).must_equal(true)
    (list.include? second_code).must_equal(true)
  end

  it "should not set up reciprocal referral if given the same codes" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = first_code
    @rc.associate_codes(first_code, second_code).must_equal(false)
    @rc.get_list_referral_code(first_code).size.must_equal(0)
  end

  it "should not set up reciprocal referral if given invalid arguments" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)

    @rc.associate_codes(first_code, nil).must_equal(false)
    @rc.get_list_referral_code(first_code).size.must_equal(0)

    @rc.associate_codes(first_code, second_code.reverse).must_equal(false)
    @rc.get_list_referral_code(first_code).size.must_equal(0)
    @rc.get_list_referral_code(second_code).size.must_equal(0)
  end

  it "should set up a reciprocal referral using only user ids" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    @rc.associate_people(@person_id, @user_id).must_equal(true)
    @rc.get_list_referral_code(first_code).size.must_equal(1)
    @rc.get_list_referral_code(first_code).first.must_equal(@user_id)
    @rc.get_list_referral_code(second_code).size.must_equal(1)
    @rc.get_list_referral_code(second_code).first.must_equal(@person_id)
  end

  it "should return an integer for the amount of bonus credits for a new code" do
    code = @rc.create_person_code(@person_id)
    @rc.get_bonus_credits(code).must_equal(0)
  end

  it "should return the same number for get_list_referral_code and get_referral_credits if the code has no bonus" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    @rc.associate_people(@person_id, @user_id).must_equal(true)
    @rc.get_list_referral_code(first_code).size.must_equal(1)
    @rc.get_list_referral_code(first_code).first.must_equal(@user_id)
    @rc.get_referral_credits(first_code).must_equal(1)
  end

  it "should be able to add an arbitrary number to bonus credits" do
    c = rand(200) - 100
    code = @rc.create_person_code(@person_id)
    @rc.get_bonus_credits(code).must_equal(0)
    @rc.add_bonus_credits(code, c)
    @rc.get_bonus_credits(code).must_equal(c)
  end

  it "should be able to decrement bonus credits" do
    code = @rc.create_person_code(@person_id)
    @rc.get_bonus_credits(code).must_equal(0)
    @rc.add_bonus_credits(code, 5)
    @rc.get_bonus_credits(code).must_equal(5)
    @rc.add_bonus_credits(code, -1)
    @rc.get_bonus_credits(code).must_equal(4)
  end

  it "should return bonus credits included in get_referral_credits" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    @rc.associate_people(@person_id, @user_id).must_equal(true)
    @rc.get_list_referral_code(first_code).size.must_equal(1)
    @rc.get_list_referral_code(first_code).first.must_equal(@user_id)
    @rc.get_referral_credits(first_code).must_equal(1)

    c = rand(200) - 100
    @rc.get_bonus_credits(first_code).must_equal(0)
    @rc.add_bonus_credits(first_code, c)
    @rc.get_bonus_credits(first_code).must_equal(c)
    @rc.get_referral_credits(first_code).must_equal(c + 1)
  end

  it "should add a code with bonus credits to the list of codes that have credits" do
    c = rand(200) - 100
    code = @rc.create_person_code(@person_id)
    @rc.add_bonus_credits(code, c)
    list = @rc.get_codes_with_credits
    list.wont_be_empty
    list.must_be_instance_of Array
    list.length.must_equal(1)
    (list.include? code).must_equal(true)
  end

  it "should return false if it can't find a code for a given ID in the get_referral_credits_id wrapper" do
    @rc.add_bonus_credits_id(@person_id, 4).must_equal(false)
  end

  it "should find a code when given an ID for the get_referral_credits_id wrapper" do
    c = rand(200) - 100
    code = @rc.create_person_code(@person_id)
    @rc.get_bonus_credits(code).must_equal(0)
    @rc.add_bonus_credits_id(@person_id, c).must_equal(true)
    @rc.get_bonus_credits(code).must_equal(c)
  end

  it "should return false if it can't find a code for a given ID in the add_bonus_credits_id wrapper" do
    @rc.get_referral_credits_id(@person_id).must_equal(false)
  end

  it "should find a code when given an ID for the add_bonus_credits_id wrapper" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    @rc.associate_people(@person_id, @user_id).must_equal(true)
    @rc.get_list_referral_code(first_code).size.must_equal(1)
    @rc.get_list_referral_code(first_code).first.must_equal(@user_id)
    @rc.get_referral_credits_id(@person_id).must_equal(1)
  end

  it "should provide a list of all the users above a certain number of referral credits, ordered by credits descending" do
    third_id    = rand(100000)
    fourth_id   = rand(100000)
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    third_code  = @rc.create_person_code(third_id)
    fourth_code = @rc.create_person_code(fourth_id)

    #ary = [[first_code, @person_id], [second_code, @user_id], [third_code, third_id], [fourth_code, fourth_id]]
    #ary.each_index do |i|
    #  puts "#{i}: code: #{ary[i][0]}, id: #{ary[i][1]}"
    #end

    @rc.associate_people(@person_id, @user_id).must_equal(true)
    @rc.associate_people(@person_id, third_id).must_equal(true)
    @rc.associate_people(@person_id, fourth_id).must_equal(true)
    @rc.associate_people(third_id, @user_id).must_equal(true)

    @rc.add_bonus_credits_id(@person_id, 1)
    @rc.add_bonus_credits_id(@user_id, 1)

    list = @rc.get_high_credit_users(3)
    list.wont_be_empty
    list.must_be_instance_of Array
    list.length.must_equal(2)

    list[0][:code].must_equal(first_code)
    list[0][:tc_uid].must_equal(@person_id)
    (list[0][:referrals].include? (@user_id)).must_equal(true)
    (list[0][:referrals].include? (third_id)).must_equal(true)
    (list[0][:referrals].include? (fourth_id)).must_equal(true)

    list[0][:referral_credits].must_equal(list[0][:referrals].length)
    list[0][:bonus_credits].must_equal(1)

    list[0][:total_credits].must_equal(list[0][:referrals].length + 1)

    list[1][:code].must_equal(second_code)
    list[1][:tc_uid].must_equal(@user_id)
    (list[1][:referrals].include? (@person_id)).must_equal(true)
    (list[1][:referrals].include? (third_id)).must_equal(true)
    list[1][:bonus_credits].must_equal(1)
    list[1][:referral_credits].must_equal(2)
    list[1][:total_credits].must_equal(3)
  end
end

