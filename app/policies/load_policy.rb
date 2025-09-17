class LoadPolicy < ApplicationPolicy
  # index on a class-level record: allow any signed-in driver
  def index?
    user.present?
  end

  def show?
    owns_record?
  end

  def create?
    user.present?
  end

  def update?
    owns_record?
  end

  def destroy?
    owns_record?
  end

  def preplan?
    owns_record?
  end

  def add_stops?
    owns_record?
  end

  def remove_stop?
    owns_record?
  end

  def start?
    owns_record?
  end

  def deliver?
    owns_record?
  end

  def drop?
    owns_record?
  end

  def regeocode?
    owns_record?
  end

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
