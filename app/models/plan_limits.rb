class PlanLimits
  TIER = :free

  EXPIRES_IN = {
    "1h" => 1.hour,
    "24h" => 24.hours,
    "7d" => 7.days
  }.freeze

  MAX_READS_CHOICES = [ 1, 3, 5 ].freeze

  class << self
    def tier
      TIER
    end

    def allowed_expires_in_keys
      case tier
      when :pro then EXPIRES_IN.keys
      else %w[24h]
      end
    end

    def allowed_max_reads_values
      case tier
      when :pro then MAX_READS_CHOICES
      else [ 1 ]
      end
    end

    def expires_in_enabled?(key)
      allowed_expires_in_keys.include?(key.to_s)
    end

    def max_reads_enabled?(value)
      allowed_max_reads_values.include?(value.to_i)
    end

    def resolve_expires_at(expires_in_key)
      key = expires_in_key.to_s.presence || allowed_expires_in_keys.first
      key = allowed_expires_in_keys.first unless expires_in_enabled?(key)
      Time.current + EXPIRES_IN.fetch(key)
    end

    def resolve_max_reads(value)
      choice = value.to_i
      choice = 1 if choice < 1
      return choice if max_reads_enabled?(choice)

      allowed_max_reads_values.max
    end

    def default_expires_in_key
      allowed_expires_in_keys.first
    end

    def default_max_reads
      allowed_max_reads_values.first
    end
  end
end
