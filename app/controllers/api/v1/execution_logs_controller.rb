module Api
  module V1
    class ExecutionLogsController < ApplicationController
      before_action :set_execution_log, only: [:show]

      def index
        logs = ExecutionLog.order(id: :desc).limit(20)

        render json: logs.map { |log|
          {
            id: log.id,
            workflow_id: log.workflow_id,
            event_type: log.event_type,
            condition_passed: log.condition_passed,
            action_executed: log.action_executed,
            created_at: log.created_at
          }
        }
      end

      def show
        render json: {
          id: @execution_log.id,
          workflow_id: @execution_log.workflow_id,
          event_type: @execution_log.event_type,
          event_payload: @execution_log.event_payload,
          condition_passed: @execution_log.condition_passed,
          action_executed: @execution_log.action_executed,
          created_at: @execution_log.created_at,
          updated_at: @execution_log.updated_at
        }
      end

      private

      def set_execution_log
        @execution_log = ExecutionLog.find(params[:id])
      end
    end
  end
end