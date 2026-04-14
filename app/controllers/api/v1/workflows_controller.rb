module Api
  module V1
    class WorkflowsController < ApplicationController
      before_action :set_workflow, only: [:show, :update, :destroy, :parse, :run]

      def index
        workflows = Workflow.all.order(created_at: :desc)
        render json: workflows.map { |w| { id: w.id, name: w.name } }
      end

      def create
        workflow = Workflow.new(workflow_params)

        if workflow.save
          render json: workflow, status: :created
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

      def destroy
        @workflow.destroy
        head :no_content
      end

      def parse
        result = Workflows::Parser.new(@workflow).call

        if result[:success]
          render json: result
        else
          render json: result, status: :unprocessable_entity
        end
      end

      def run
        input_payload = request.request_parameters
        result = Workflows::Executor.new(@workflow, input_payload).call
        if result[:success]
          render json: {
            success: true,
            trace: result[:trace],
            condition_passed: result[:condition_passed],
            action_result: result[:action_result],
            execution_log_id: result[:execution_log].id
          }
        else
          render json: {
            success: false,
            errors: result[:errors],
            trace: result[:trace]
          }, status: :unprocessable_entity
        end
      end
      
      private

      def set_workflow
        @workflow = Workflow.find(params[:id])
      end

      def workflow_params
        permitted = params.require(:workflow).permit(:name, :status, :trigger)
        permitted[:json_data] = params[:workflow][:json_data] if params[:workflow][:json_data]
        permitted
      end
    end
  end
end