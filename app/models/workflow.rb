class Workflow < ApplicationRecord
  validates :name, presence: true
  validates :json_data, presence: true, if: :persisted?
  
  has_many :execution_logs, dependent: :destroy
  belongs_to :user, optional: true  # optional if no auth yet
  
  scope :active, -> { where(status: "active") }
  
  before_validation :ensure_json_data, if: :name_changed?
  
  private
  
  def ensure_json_data
    self.json_data ||= {}
  end
end