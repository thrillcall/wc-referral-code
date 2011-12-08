# -*- encoding: utf-8 -*-
require File.expand_path("../../spec_helper", __FILE__)
require "ReferralCode"

PERSON_ID = "1"
USER_ID = "2"

describe "ReferralCodeTest" do

  before do
    $redis.flushdb
    @rc = ReferralCode.new($redis)
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
    @rc.create_person_code(PERSON_ID).must_equal("OK")
  end

  it "should not create a referral code for a person who has already one" do
    @rc.create_person_code(PERSON_ID)
    @rc.create_person_code(PERSON_ID).must_be_nil
  end

  it "should create the reverse lookup for the referral code" do
    @rc.create_person_code(PERSON_ID)
    code = @rc.get_person_code(PERSON_ID)
    @rc.get_person_with_code(code).must_equal(PERSON_ID)
  end

  it "should retrieve the referral code of a person" do
    @rc.create_person_code(PERSON_ID)
    @rc.get_person_code(PERSON_ID).wont_be_empty
  end

  it "should retrieve the ID of a person with the referral code" do
    @rc.create_person_code(PERSON_ID)
    code = @rc.get_person_code(PERSON_ID)
    @rc.get_person_with_code(code).must_equal(PERSON_ID)
  end

  it "should add a person to the list of persons who have used the same referral code" do
    @rc.create_person_code(PERSON_ID)
    code = @rc.get_person_code(PERSON_ID)
    @rc.add_person_to_referral_list(USER_ID, code).must_equal("OK")
  end

  it "should not add the person to the list if he is the owner of the referral code" do
    @rc.create_person_code(PERSON_ID)
    code = @rc.get_person_code(PERSON_ID)
    @rc.add_person_to_referral_list(PERSON_ID, code).must_be_nil
  end

  it "should create the reverse lookup to determine who is the owner of the referral code the user has used" do
    @rc.create_person_code(PERSON_ID)
    code = @rc.get_person_code(PERSON_ID)
    @rc.add_person_to_referral_list(USER_ID, code)
    @rc.set_referral_code_owner_used(PERSON_ID, USER_ID).must_equal("OK")
  end

  it "should get the list of persons who have used a referral code" do
    @rc.create_person_code(PERSON_ID)
    code = @rc.get_person_code(PERSON_ID)
    @rc.add_person_to_referral_list(USER_ID, code)
    @rc.get_list_referral_code(code).size.must_equal(1)
  end

  it "should get the owner of the referral code a person has used" do
    @rc.create_person_code(PERSON_ID)
    code = @rc.get_person_code(PERSON_ID)
    @rc.add_person_to_referral_list(USER_ID, code)
    @rc.get_referral_code_owner_used(USER_ID).must_equal(PERSON_ID)
  end

end

