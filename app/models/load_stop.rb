class LoadStop < ApplicationRecord
  belongs_to :load
  belongs_to :stoppable, polymorphic: true
end
