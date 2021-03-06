module Von
  module Counters
    class Current
      include Commands

      # Initialize a new Counter
      #
      # field - counter field name
      def initialize(field, periods = nil)
        @field   = field.to_sym
        @periods = periods || []
      end

      # Returns the Redis hash key used for storing counts for this Counter
      def hash_key
        "#{Von.config.namespace}:counters:currents:#{@field}"
      end

      def current_timestamp(time_unit)
        hget("#{hash_key}:#{time_unit}", 'timestamp')
      end

      def increment(by=1, at=Time.now)
        return if @periods.empty?

        @periods.each do |period|
          if period.timestamp(at) != current_timestamp(period.time_unit)
            hset("#{hash_key}:#{period.time_unit}", 'total', by)
            hset("#{hash_key}:#{period.time_unit}", 'timestamp', period.timestamp(at))
          else
            hincrby("#{hash_key}:#{period.time_unit}", 'total', by)
          end
        end
      end

      def count(time_unit)
        count = hget("#{hash_key}:#{time_unit}", 'total')
        count.nil? ? 0 : count.to_i
      end

    end
  end
end
