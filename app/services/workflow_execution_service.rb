class WorkflowExecutionService
  def initialize(event_type, payload)
    @event_type = event_type
    @payload = payload
  end

  def call
    workflows = Workflow.active.where(trigger: @event_type)
    results = []

    workflows.find_each do |workflow|
      passed = evaluate_condition(workflow.condition, @payload)
      
      action_result = passed ? execute_action(workflow.action) : "Skipped - condition failed"

      log = ExecutionLog.create!(
        workflow: workflow,
        event_type: @event_type,
        event_payload: @payload,
        condition_passed: passed,
        action_executed: action_result
      )

      results << {
        id: log.id,
        workflow_name: workflow.name,
        condition_passed: passed,
        action_executed: action_result
      }
    end

    results
  end

  private

  def evaluate_condition(condition, payload)
    return false unless condition.is_a?(Hash)

    field = condition['field']
    operator = condition['operator']
    value = condition['value']

    return false unless payload[field] && operator && value

    payload_value = payload[field]

    case operator
    when '>'
      payload_value.to_f > value.to_f
    when '<'
      payload_value.to_f < value.to_f
    when '==', '='
      payload_value.to_s == value.to_s
    else
      false
    end
  end

  def execute_action(action)
    return 'No action' unless action&.dig('type')

    case action['type']
    when 'send_email'
      "✅ Email sent: #{action['template']}"
    when 'send_discount'
      "✅ Discount code: SAVE20%"
    else
      "✅ Action '#{action['type']}' executed"
    end
  end
end