require "ReferralCode/version"
require "uuidtools"

class ReferralCode

  # Constructor
  # Params: redis instance
  def initialize(redis)
    @redis = redis
  end

  ################################################################
  # Create a referral code for a person
  ################################################################
  def create_person_code(person_id)
    existing_code = @redis.get person_code_key(person_id)
    if existing_code.nil?
      code = UUIDTools::UUID.random_create.hexdigest[0..5]
      @redis.set person_code_key(person_id), code
      set_code_list(person_id, code)
      return code
    end
    return existing_code
  end

  # Method creating the reverse lookup between a user and a referral code
  def set_code_list(person_id, code)
    p_id = person_id.to_i
    @redis.set code_person_key(code), p_id
  end
  ################################################################

  ################################################################
  # Retrieve the referral code for a person
  ################################################################
  def get_person_code(person_id)
    p_id = person_id.to_i
    @redis.get person_code_key(p_id)
  end
  ################################################################

  ################################################################
  # Retrieve the person ID associated with the referral code
  ################################################################
  def get_person_with_code(code)
    id = @redis.get code_person_key(code)
    if id
      id = id.to_i
    end
    id
  end
  ################################################################

  ################################################################
  # Add a person to a set where the set contains all the persons using the same referral code
  ################################################################
  def add_person_to_referral_list(person_id, code)
    p_id = person_id.to_i
    owner_code_id = get_person_with_code(code)
    if owner_code_id != p_id
      @redis.sadd list_referral_code_key(code), p_id
      @redis.sadd codes_with_credits_key, code
      #set_referral_code_owner_used(owner_code_id, person_id)
      return true
    end
    return false
  end
  ################################################################

  ################################################################
  # Associate two owners to each other through their referral codes
  ################################################################
  def associate_people(first_owner, second_owner)
    first_code    = get_person_code(first_owner)
    second_code   = get_person_code(second_owner)
    do_association(first_code, first_owner, second_code, second_owner)
  end

  def associate_codes(first_code, second_code)
    first_owner   = get_person_with_code(first_code)
    second_owner  = get_person_with_code(second_code)
    do_association(first_code, first_owner, second_code, second_owner)
  end

  def do_association(first_code, first_owner, second_code, second_owner)
    if first_code && second_code && first_owner && second_owner && (first_owner != second_owner)
      @redis.sadd list_referral_code_key(first_code),   second_owner
      @redis.sadd list_referral_code_key(second_code),  first_owner
      @redis.sadd codes_with_credits_key, first_code
      @redis.sadd codes_with_credits_key, second_code
      return true
    else
      return false
    end
  end
  ################################################################

  ################################################################
  # Retrieve the list of persons who have used a specific referral code
  ################################################################
  def get_list_referral_code(code)
    m = @redis.smembers list_referral_code_key(code)
    if m
      m.collect! do |id|
        id = id.to_i
      end
    end
    m
  end
  ################################################################

  ################################################################
  # Get and set bonus credits
  #################################################################
  def get_bonus_credits(code)
    ((@redis.get code_bonus_key(code)) || 0).to_i
  end

  def add_bonus_credits(code, amt = 0)
    amt = amt.to_i + get_bonus_credits(code)
    @redis.set code_bonus_key(code), amt
    @redis.sadd codes_with_credits_key, code
    return true
  end

  def add_bonus_credits_id(id, amt = 0)
    c = get_person_code(id)
    unless c
      return false
    end
    add_bonus_credits(c, amt)
  end
  ################################################################

  ################################################################
  # Add the length of the code's referral list to the code's bonus credits
  ################################################################
  def get_referral_credits(code)
    list  = get_list_referral_code(code)
    bonus = get_bonus_credits(code)

    list  = list  ? list.length : 0
    bonus = bonus ? bonus : 0
    return (list + bonus)
  end

  def get_referral_credits_id(id)
    c = get_person_code(id)
    unless c
      return false
    end
    get_referral_credits(c)
  end
  ################################################################

  def get_codes_with_credits
    @redis.smembers(codes_with_credits_key)
  end

  def get_high_credit_users(min_credits = 1)
    if min_credits < 1
      min_credits = 1
    end
    list = []

    all_code_keys = get_codes_with_credits
    all_code_keys.each do |k|
      code = k
      item          = {
        :code           => code,
        :tc_uid         => get_person_with_code(code),
        :referrals      => get_list_referral_code(code),
        :bonus_credits  => get_bonus_credits(code)
      }

      item[:referral_credits] = item[:referrals].length
      item[:total_credits]    = item[:referral_credits] + item[:bonus_credits]

      if item[:total_credits] >= min_credits
        list << item
      end
    end
    list.sort! do |a, b|
      b[:total_credits] <=> a[:total_credits]
    end
    return list
  end

  # Key where each user has one code associated with his ID
  def person_code_key(person_id)
    "offers:person:code:#{person_id}"
  end

  # Key to retrieve the user ID with a code
  def code_person_key(code)
    "offers:code:person:#{code}"
  end

  # Key where are stored the users who used someone's code (Referral)
  def list_referral_code_key(code)
    "offers:list:referral:code:#{code}"
  end

  def code_bonus_key(code)
    "offers:code:bonus:#{code}"
  end

  def codes_with_credits_key
    "offers:codes_with_credits"
  end

end
