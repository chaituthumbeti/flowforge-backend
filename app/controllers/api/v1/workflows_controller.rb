class Api::V1::WorkflowsController < ApplicationController
  def index
    workflows = Workflow.all.order(created_at: :desc)
    render json: workflows,status: :ok
  end

  def show
    workflow = Workflow.find(params[:id])
    render json: workflow, status: :ok
  end

  def create
    workflow=Workflow.new(workflow_params)
    if workflow.save
      render json:workflow, status: :created
    else 
      render json: {errors: workflow.errors.full_messages},status: :unprocessable_entity
    end
  end

  def destroy
    workflow=Workflow.find(params[:id])
    workflow.destroy
    render json:{ message: "Workflow deleted successfully"}, status: :ok
  end

  private
  def workflow_params
    params.require(:workflow).permit(
      :name,
      :trigger,
      :status,
      condition:{},
      action:{})
  end
end
