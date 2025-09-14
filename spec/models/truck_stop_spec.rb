
require "rails_helper"

RSpec.describe TruckStop, type: :model do
  it "requires name" do
    ts = described_class.new
    expect(ts).not_to be_valid
    expect(ts.errors[:name]).to be_present
  end
end
