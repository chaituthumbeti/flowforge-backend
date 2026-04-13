module Api
  module V1
    class WorkflowsController < ApplicationController
      before_action :set_workflow, only: [:show, :update, :destroy]
      
      def index
        workflows = Workflow.all.order(created_at: :desc)
        render json: workflows.map { |w| { id: w.id, name: w.name } }
      end
      
      def create
        workflow = Workflow.new(workflow_params)
        if workflow.save
          render json: { id: workflow.id, name: workflow.name }, status: :created
        else
          render json: { errors: workflow.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def show
        render json: @workflow
      end
      
      def update
        if @workflow.update(workflow_params)
          render json: @workflow
        else
          render json: { errors: @workflow.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def set_workflow
        @workflow = Workflow.find(params[:id])
      end
      
      def destroy
        @workflow.destroy
        head :no_content
      end
      
      private
      
      def set_workflow
        @workflow = Workflow.find(params[:id])
      end
      
      def workflow_params
        params.require(:workflow).permit(:name, :status, :trigger, json_data: {})
      end
    end
  end
end