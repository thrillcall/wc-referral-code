# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ReferralCode/version"

Gem::Specification.new do |s|
  s.name        = "ReferralCode"
  s.version     = Referralcode::VERSION
  s.authors     = ["Eddy Kang"]
  s.email       = ["eddy@thrillcall.com"]
  s.homepage    = "https://github.com/thrillcall/wc-referral-code"
  s.summary     = %q{Wrapper to access referral codes for users stored in redis.}
  s.description = %q{Wrapper to access referral codes for users stored in redis.}

  s.rubyforge_project = "ReferralCode"

  s.add_development_dependency  "redis", "2.2.2"
  s.add_development_dependency  "redis-namespace", "1.0.3"
  s.add_development_dependency  "uuidtools", "2.1.2"
  s.add_development_dependency  "rake"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
