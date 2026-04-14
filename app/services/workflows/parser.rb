module Workflows
  class Parser
    def initialize(workflow)
      @workflow = workflow
      @nodes = Array(workflow.json_data["nodes"])
      @edges = Array(workflow.json_data["edges"])
      @errors = []
    end

    def call
      validate_presence
      return result(false) if @errors.any?

      trigger = find_trigger
      conditions = find_nodes_by_type("condition")
      actions = find_nodes_by_type("action")

      validate_single_trigger(trigger)
      validate_actions_present(actions)
      validate_edges_reference_existing_nodes
      validate_trigger_connected(trigger)

      return result(false) if @errors.any?

      result(true, {
        workflow_id: @workflow.id,
        workflow_name: @workflow.name,
        trigger: serialize_node(trigger),
        conditions: conditions.map { |n| serialize_node(n) },
        actions: actions.map { |n| serialize_node(n) },
        edges: @edges
      })
    end

    private

    def validate_presence
      @errors << "Workflow has no nodes" if @nodes.empty?
    end

    def find_trigger
      triggers = find_nodes_by_type("trigger")
      triggers.first
    end

    def find_nodes_by_type(type)
      @nodes.select { |node| node["type"] == type }
    end

    def validate_single_trigger(trigger)
      triggers = find_nodes_by_type("trigger")

      if triggers.empty?
        @errors << "Workflow must have one trigger node"
      elsif triggers.size > 1
        @errors << "Workflow cannot have more than one trigger node"
      end
    end

    def validate_actions_present(actions)
      @errors << "Workflow must have at least one action node" if actions.empty?
    end

    def validate_edges_reference_existing_nodes
      node_ids = @nodes.map { |n| n["id"].to_s }

      @edges.each do |edge|
        unless node_ids.include?(edge["source"].to_s)
          @errors << "Edge #{edge['id']} has invalid source"
        end

        unless node_ids.include?(edge["target"].to_s)
          @errors << "Edge #{edge['id']} has invalid target"
        end
      end
    end

    def validate_trigger_connected(trigger)
      return if trigger.nil?

      connected = @edges.any? { |edge| edge["source"].to_s == trigger["id"].to_s }
      @errors << "Trigger node must connect to the workflow" unless connected
    end

    def serialize_node(node)
      {
        id: node["id"],
        type: node["type"],
        label: node.dig("data", "label"),
        position: node["position"]
      }
    end

    def result(success, data = nil)
      {
        success: success,
        errors: @errors,
        parsed_workflow: data
      }
    end
  end
end