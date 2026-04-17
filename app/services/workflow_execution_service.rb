class WorkflowExecutionService
  def initialize(event_type, payload)
    @event_type = event_type
    @payload = payload
  end

  def call
    workflows = Workflow.active.where(trigger: @event_type)
    results = []

    workflows.find_each do |workflow|
      execution = Workflows::Executor.new(workflow, @payload).call

      Rails.logger.debug "SERVICE RESULT for workflow #{workflow.id} (#{workflow.name}): #{execution.inspect}"

      results << {
        id: execution[:execution_log]&.id,
        workflow_id: workflow.id,
        workflow_name: workflow.name,
        condition_passed: execution[:condition_passed] == true,
        action_executed: format_action_result(execution[:action_result], execution[:condition_passed]),
        trace: execution[:trace],
        errors: execution[:errors]
      }
    end

    # Rails.logger.debug "FINAL SERVICE RESULTS: #{results.inspect}"
    results
  end

  private

  def format_action_result(action_result, condition_passed)
    return "Skipped - condition failed" unless condition_passed

    if action_result.is_a?(Hash)
      action_result[:message] || action_result["message"] || action_result[:action] || action_result["action"] || "Action executed"
    else
      action_result || "Action executed"
    end
  end
end