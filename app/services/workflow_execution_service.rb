class WorkflowExecutionService
  def initialize(event_type, payload)
    @event_type = event_type
    @payload = payload
  end

  def call
    workflows = Workflow.where(trigger: @event_type).active
    results = []

    workflows.each do |workflow|
      passed = evaluate_condition(workflow.condition, @payload)
      
      action_result = if passed
        execute_action(workflow.action)
      else
        "Skipped - condition failed"
      end

      ExecutionLog.create!(
        workflow: workflow,
        event_type: @event_type,
        event_payload: @payload,
        condition_passed: passed,
        action_executed: action_result
      )

      results << {
        workflow_id: workflow.id,
        workflow_name: workflow.name,
        condition_passed: passed,
        action_executed: action_result
      }
    end

    results
  end

  private

  def evaluate_condition(condition, payload)
    return false unless condition

    field = condition["field"]
    operator = condition["operator"]
    value = condition["value"]

    payload_value = payload[field]

    case operator
    when ">"
      payload_value.to_f > value.to_f
    when "<"
      payload_value.to_f < value.to_f
    when "==", "="
      payload_value.to_s == value.to_s
    else
      false
    end
  end

  def execute_action(action)
    return "No action defined" unless action

    case action["type"]
    when "send_email"
      "Email sent: #{action["template"]}"
    when "send_discount"
      "Discount code generated"
    else
      "Action executed: #{action["type"]}"
    end
  end
end