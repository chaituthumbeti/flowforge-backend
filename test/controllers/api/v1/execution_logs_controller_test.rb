require "test_helper"

class Api::V1::ExecutionLogsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_execution_logs_index_url
    assert_response :success
  end
end
