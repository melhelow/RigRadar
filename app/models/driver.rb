# == Schema Information
#
# Table name: drivers
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_drivers_on_email                 (email) UNIQUE
#  index_drivers_on_reset_password_token  (reset_password_token) UNIQUE
#
class Driver < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  has_many :loads, dependent: :nullify
end

