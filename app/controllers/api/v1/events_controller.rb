class Api::V1::EventsController < ApplicationController
  before_action :validate_event_params

  def create
    result = WorkflowExecutionService.new(
      params[:event_type], 
      params[:payload]
    ).call

    render json: {
      success: true,
      message: "Workflows executed",
      executions: result
    }, status: :ok
  end

  private

  def validate_event_params
    unless params[:event_type] && params[:payload]
      render json: { error: "Missing event_type or payload" }, 
             status: :bad_request
    end
  end
end