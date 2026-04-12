class Api::V1::ExecutionLogsController < ApplicationController
  def index
    logs = ExecutionLog.includes(:workflow)
                       .order(created_at: :desc)
                       .limit(50)
    
    render json: logs.map do |log|
      log.as_json(include: :workflow)
    end
  end
end