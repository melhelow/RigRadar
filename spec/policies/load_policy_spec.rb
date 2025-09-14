
require "rails_helper"

RSpec.describe LoadPolicy do
  let(:driver) { Driver.create!(email: "a@b.com", password: "password123") }
  let(:other)  { Driver.create!(email: "x@y.com", password: "password123") }
  let(:load)   { driver.loads.create!(commodity: "Steel", weight_lbs: 40000, pickup_location: "Dallas", dropoff_location: "Omaha") }

  it "permits owner" do
    policy = described_class.new(driver, load)
    expect(policy.show?).to be(true)
    expect(policy.update?).to be(true)
    expect(policy.destroy?).to be(true)
  end

  it "forbids non-owner" do
    policy = described_class.new(other, load)
    expect(policy.show?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end
end
