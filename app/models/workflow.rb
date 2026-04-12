class Workflow < ApplicationRecord
  validates :name, :trigger, presence: true
  validates :status, inclusion: { in: %w[active inactive] }

  has_many :execution_logs, dependent: :destroy

  scope :active, -> { where(status: "active") }
end