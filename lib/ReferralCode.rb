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
    code = UUIDTools::UUID.random_create.hexdigest[0..5]
    if (@redis.get person_code_key(person_id)).nil?
      @redis.set person_code_key(person_id), code
      set_code_list(person_id, code)
    end
  end

  # Method creating the reverse lookup between a user and a referral code
  def set_code_list(person_id, code)
    @redis.set code_person_key(code), person_id
  end
  ################################################################

  ################################################################
  # Retrieve the referral code for a person
  ################################################################
  def get_person_code(person_id)
    @redis.get person_code_key(person_id)
  end
  ################################################################

  ################################################################
  # Retrieve the person ID associated with the referral code
  ################################################################
  def get_person_with_code(code)
    @redis.get code_person_key(code)
  end
  ################################################################

  ################################################################
  # Add a person to a set where the set contains all the persons using the same referral code
  ################################################################
  def add_person_to_referral_list(person_id, code)
    owner_code_id = get_person_with_code(code)
    if owner_code_id != person_id.to_s
      @redis.sadd list_referral_code_key(code), person_id
      set_referral_code_owner_used(owner_code_id, person_id)
    end
  end

  # Method creating the reverse lookup to determine who is the owner of the referral code a person has used
  def set_referral_code_owner_used(referral_owner_id, user_id)
    @redis.set referral_code_owner_used_key(user_id), referral_owner_id
  end
  ################################################################

  ################################################################
  # Retrieve the list of persons who have used a specific referral code
  #################################################################
  def get_list_referral_code(code)
    @redis.smembers list_referral_code_key(code)
  end
  ################################################################

  ################################################################
  # Retrieve the owner of the referral code a person has used
  #################################################################
  def get_referral_code_owner_used(person_id)
    @redis.get referral_code_owner_used_key(person_id)
  end
  #################################################################

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

  # Key to retrieve the referral code a user has used
  def referral_code_owner_used_key(person_id)
    "offers:referral:code:owner:used:#{person_id}"
  end
end
