module RubyEventStore
  module ROM
    module Memory
      class UnitOfWork < ROM::UnitOfWork
        def self.mutex
          @mutex ||= Mutex.new
        end

        def commit!(_gateway, changesets, **_options)
          self.class.mutex.synchronize do
            committed = []

            begin
              until changesets.empty?
                changeset = changesets.shift
                relation = env.container.relations[changeset.relation.name]

                committed << [changeset, relation]

                changeset.commit
              end
            rescue StandardError
              committed.reverse_each do |c, r|
                r.restrict(id: c.to_a.map { |e| e[:id] }).command(:delete, result: :many).call
              end

              raise
            end
          end
        end
      end
    end
  end
end
