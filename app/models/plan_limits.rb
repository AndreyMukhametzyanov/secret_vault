class PlanLimits
  FREE_TIER = :free
  PRO_TIER = :pro

  EXPIRES_IN = {
    "1h" => 1.hour,
    "24h" => 24.hours,
    "7d" => 7.days
  }.freeze

  MAX_READS_CHOICES = [ 1, 3, 5 ].freeze
  PRO_EXPIRES_IN_KEYS = %w[1h 24h 7d].freeze
  DEFAULT_EXPIRES_IN_KEY = "24h"

  def self.for(user = nil)
    tier = user&.pro? ? PRO_TIER : FREE_TIER
    new(tier)
  end

  attr_reader :tier

  def initialize(tier = FREE_TIER)
    @tier = tier
  end

  def pro?
    tier == PRO_TIER
  end

  def allowed_expires_in_keys
    pro? ? PRO_EXPIRES_IN_KEYS : %w[24h]
  end

  def allowed_max_reads_values
    pro? ? MAX_READS_CHOICES : [ 1 ]
  end

  def expires_in_enabled?(key)
    allowed_expires_in_keys.include?(key.to_s)
  end

  def max_reads_enabled?(value)
    allowed_max_reads_values.include?(value.to_i)
  end

  def resolve_expires_at(expires_in_key)
    key = expires_in_key.to_s.presence || default_expires_in_key
    key = default_expires_in_key unless expires_in_enabled?(key)
    Time.current + EXPIRES_IN.fetch(key)
  end

  def resolve_max_reads(value)
    choice = value.to_i
    choice = 1 if choice < 1
    return choice if max_reads_enabled?(choice)

    allowed_max_reads_values.max
  end

  def default_expires_in_key
    return DEFAULT_EXPIRES_IN_KEY if expires_in_enabled?(DEFAULT_EXPIRES_IN_KEY)

    allowed_expires_in_keys.first
  end

  def default_max_reads
    allowed_max_reads_values.first
  end
end
