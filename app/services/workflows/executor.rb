module Workflows
  class Executor
    def initialize(workflow)
      @workflow = workflow
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
          execution_log: nil
        }
      end

      parsed = @parser_result[:parsed_workflow]
      trigger = parsed[:trigger]
      conditions = parsed[:conditions]
      actions = parsed[:actions]

      @trace << step("workflow_loaded", @workflow.id)
      @trace << step("trigger_found", trigger)
      @trace << step("conditions_found", conditions)
      @trace << step("actions_found", actions)

      execution_log = ExecutionLog.create!(
        workflow_id: @workflow.id,
        event_type: "workflow_run",
        event_payload: {
          trigger: trigger,
          conditions: conditions,
          actions: actions,
          trace: @trace
        },
        condition_passed: true,
        action_executed: actions.first && actions.first[:id] ? actions.first[:id] : nil
      )

      {
        success: true,
        errors: [],
        trace: @trace,
        execution_log: execution_log
      }
    rescue StandardError => e
      {
        success: false,
        errors: [e.message],
        trace: @trace,
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
  end
end