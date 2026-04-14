module Workflows
  class Executor
    def initialize(workflow, input_payload = {})
      @workflow = workflow
      @input_payload = input_payload
      @parser_result = nil
      @trace = []
    end

    def call
      @parser_result = Workflows::Parser.new(@workflow).call

      unless @parser_result[:success]
        return {
          success: false,
          errors: @parser_result[:errors],
          trace: @trace,
          condition_passed: false,
          execution_log: nil
        }
      end

      parsed = @parser_result[:parsed_workflow]
      trigger = parsed[:trigger]
      conditions = parsed[:conditions]
      actions = parsed[:actions]

      @trace << step("workflow_loaded", @workflow.id)
      @trace << step("trigger_found", trigger)
      @trace << step("input_received", @input_payload)

      condition_passed = true

      if conditions.any?
        first_condition = conditions.first
        expression = first_condition[:label]
        condition_passed = evaluate_condition(expression, @input_payload)

        @trace << step("condition_evaluated", {
          expression: expression,
          result: condition_passed
        })
      end

      executed_action = nil

      if condition_passed
        @trace << step("actions_found", actions)
        executed_action = actions.first
        @trace << step("action_executed", executed_action)
      else
        @trace << step("execution_stopped", "Condition failed")
      end

      execution_log = ExecutionLog.create!(
        workflow_id: @workflow.id,
        event_type: "workflow_run",
        event_payload: @input_payload,
        condition_passed: condition_passed,
        action_executed: executed_action ? executed_action[:label] : nil
      )

      {
        success: true,
        errors: [],
        trace: @trace,
        condition_passed: condition_passed,
        execution_log: execution_log
      }
    rescue StandardError => e
      {
        success: false,
        errors: [e.message],
        trace: @trace,
        condition_passed: false,
        execution_log: nil
      }
    end

    private

    def step(name, payload = nil)
      {
        step: name,
        payload: payload
      }
    end

    def evaluate_condition(expression, payload)
      return false if expression.nil? || expression.strip.empty?

      match = expression.strip.match(/\A([a-zA-Z_]\w*)\s*(>=|<=|==|>|<)\s*(\d+(?:\.\d+)?)\z/)
      return false unless match

      field = match[1]
      operator = match[2]
      expected_value = match[3].to_f

      actual_value = payload[field] || payload[field.to_sym]
      return false if actual_value.nil?

      actual_value = actual_value.to_f

      case operator
      when ">"
        actual_value > expected_value
      when "<"
        actual_value < expected_value
      when ">="
        actual_value >= expected_value
      when "<="
        actual_value <= expected_value
      when "=="
        actual_value =s= expected_value
      else
        false
      end
    end
  end
end