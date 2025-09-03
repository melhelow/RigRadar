# == Schema Information
#
# Table name: load_stops
#
#  id             :integer          not null, primary key
#  position       :integer
#  stoppable_type :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  load_id        :integer          not null
#  stoppable_id   :integer          not null
#
# Indexes
#
#  idx_unique_load_stoppable      (load_id,stoppable_type,stoppable_id) UNIQUE
#  index_load_stops_on_load_id    (load_id)
#  index_load_stops_on_stoppable  (stoppable_type,stoppable_id)
#
# Foreign Keys
#
#  load_id  (load_id => loads.id)
#
class LoadStop < ApplicationRecord
  belongs_to :load
  belongs_to :stoppable, polymorphic: true
    validates :load_id, uniqueness: { scope: [:stoppable_type, :stoppable_id] }

end
