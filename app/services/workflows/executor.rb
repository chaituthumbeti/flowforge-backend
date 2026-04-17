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
          action_result: nil,
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

      action_result = nil
      executed_action_name = nil

      if condition_passed
        executed_action = actions.first
        executed_action_name = executed_action ? executed_action[:label] : nil

        @trace << step("actions_found", actions)

        if executed_action
          action_result = execute_action(executed_action)
          @trace << step("action_executed", action_result)
        else
          @trace << step("execution_stopped", "No action node found")
        end
      else
        @trace << step("execution_stopped", "Condition failed")
      end

      execution_log = ExecutionLog.create!(
        workflow_id: @workflow.id,
        event_type: "workflow_run",
        event_payload: {
          input: @input_payload,
          trace: @trace,
          action_result: action_result
        },
        condition_passed: condition_passed,
        action_executed: executed_action_name
      )

      {
        success: true,
        errors: [],
        trace: @trace,
        condition_passed: condition_passed,
        action_result: action_result,
        execution_log: execution_log
      }
    rescue StandardError => e
      {
        success: false,
        errors: [e.message],
        trace: @trace,
        condition_passed: false,
        action_result: nil,
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

      data = payload["payload"] || payload[:payload] || payload
      actual_value = data[field] || data[field.to_sym]
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
        actual_value == expected_value
      else
        false
      end
    end

    def evaluate_condition(expression, payload)
      # Rails.logger.debug "=== EVALUATE CONDITION START ==="
      # Rails.logger.debug "Expression: #{expression.inspect}"
      # Rails.logger.debug "Payload: #{payload.inspect}"

      return false if expression.nil? || expression.strip.empty?

      match = expression.strip.match(/\A([a-zA-Z_]\w*)\s*(>=|<=|==|>|<)\s*(\d+(?:\.\d+)?)\z/)
      # Rails.logger.debug "Regex match: #{match.inspect}"
      return false unless match

      field = match[1]
      operator = match[2]
      expected_value = match[3].to_f

      # Rails.logger.debug "Field: #{field}"
      # Rails.logger.debug "Operator: #{operator}"
      # Rails.logger.debug "Expected value: #{expected_value}"

      data = payload["payload"] || payload[:payload] || payload
      # Rails.logger.debug "Data used for evaluation: #{data.inspect}"

      actual_value = data[field] || data[field.to_sym]
      # Rails.logger.debug "Actual raw value: #{actual_value.inspect}"

      return false if actual_value.nil?

      actual_value = actual_value.to_f
      # Rails.logger.debug "Actual numeric value: #{actual_value}"

      result =
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
          actual_value == expected_value
        else
          false
        end

      # Rails.logger.debug "Condition result: #{result}"
      # Rails.logger.debug "=== EVALUATE CONDITION END ==="

      result
    end

    def execute_action(action_node)
      label = action_node[:label].to_s.strip

      case label
      when "Send Discount"
        {
          action: label,
          status: "executed",
          message: "Discount action simulated successfully"
        }
      when "Send Welcome Email"
        {
          action: label,
          status: "executed",
          message: "Welcome email action simulated successfully"
        }
      when "Notify Team"
        {
          action: label,
          status: "executed",
          message: "Team notification simulated successfully"
        }
      else
        {
          action: label,
          status: "executed",
          message: "Generic action simulated successfully"
        }
      end
    end
  end
end