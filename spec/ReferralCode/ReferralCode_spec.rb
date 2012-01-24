# -*- encoding: utf-8 -*-
require File.expand_path("../../spec_helper", __FILE__)
require "ReferralCode"

describe "ReferralCodeTest" do

  before do
    $redis.flushdb
    @rc = ReferralCode.new($redis)
    @person_id  = rand(10000000).to_s
    @user_id    = rand(10000000).to_s
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

  it "should return an integer for the amount of bonus points for a new code" do
    code = @rc.create_person_code(@person_id)
    @rc.get_bonus_points(code).must_equal(0)
  end

  it "should return the same number for get_list_referral_code and get_referral_points if the code has no bonus" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    @rc.associate_people(@person_id, @user_id).must_equal(true)
    @rc.get_list_referral_code(first_code).size.must_equal(1)
    @rc.get_list_referral_code(first_code).first.must_equal(@user_id)
    @rc.get_referral_points(first_code).must_equal(1)
  end

  it "should be able to add an arbitrary number to bonus points" do
    c = rand(200) - 100
    code = @rc.create_person_code(@person_id)
    @rc.get_bonus_points(code).must_equal(0)
    @rc.add_bonus_points(code, c)
    @rc.get_bonus_points(code).must_equal(c)
  end

  it "should be able to decrement bonus points" do
    code = @rc.create_person_code(@person_id)
    @rc.get_bonus_points(code).must_equal(0)
    @rc.add_bonus_points(code, 5)
    @rc.get_bonus_points(code).must_equal(5)
    @rc.add_bonus_points(code, -1)
    @rc.get_bonus_points(code).must_equal(4)
  end

  it "should return bonus points included in get_referral_points" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    @rc.associate_people(@person_id, @user_id).must_equal(true)
    @rc.get_list_referral_code(first_code).size.must_equal(1)
    @rc.get_list_referral_code(first_code).first.must_equal(@user_id)
    @rc.get_referral_points(first_code).must_equal(1)

    c = rand(200) - 100
    @rc.get_bonus_points(first_code).must_equal(0)
    @rc.add_bonus_points(first_code, c)
    @rc.get_bonus_points(first_code).must_equal(c)
    @rc.get_referral_points(first_code).must_equal(c + 1)
  end

  it "should return false if it can't find a code for a given ID in the get_referral_points_id wrapper" do
    @rc.add_bonus_points_id(@person_id, 4).must_equal(false)
  end

  it "should find a code when given an ID for the get_referral_points_id wrapper" do
    c = rand(200) - 100
    code = @rc.create_person_code(@person_id)
    @rc.get_bonus_points(code).must_equal(0)
    @rc.add_bonus_points_id(@person_id, c).must_equal("OK")
    @rc.get_bonus_points(code).must_equal(c)
  end

  it "should return false if it can't find a code for a given ID in the add_bonus_points_id wrapper" do
    @rc.get_referral_points_id(@person_id).must_equal(false)
  end

  it "should find a code when given an ID for the add_bonus_points_id wrapper" do
    first_code  = @rc.create_person_code(@person_id)
    second_code = @rc.create_person_code(@user_id)
    @rc.associate_people(@person_id, @user_id).must_equal(true)
    @rc.get_list_referral_code(first_code).size.must_equal(1)
    @rc.get_list_referral_code(first_code).first.must_equal(@user_id)
    @rc.get_referral_points_id(@person_id).must_equal(1)
  end

end

