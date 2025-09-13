class LoadPolicy < ApplicationPolicy
  # index on a class-level record: allow any signed-in driver
  def index? = user.present?


  def show?       = owns_record?
  def create?     = user.present?
  def update?     = owns_record?
  def destroy?    = owns_record?


  def preplan?     = owns_record?
  def add_stops?   = owns_record?
  def remove_stop? = owns_record?
  def start?       = owns_record?
  def deliver?     = owns_record?
  def drop?        = owns_record?
  def regeocode?   = owns_record?

  class Scope < Scope
    def resolve
      scope.where(driver_id: user.id)
    end
  end

  private

  def owns_record?
    user.present? && record.driver_id == user.id
  end
end
