class ApplicationController < ActionController::API
    # 200 Success
    def response_success(class_name, action_name, data = "No contents")
        render status: 200, pretty_json: { status: 200, message: "Success! #{class_name}##{action_name}", data: data }
    end

    # 400 Bad Request
    def response_bad_request(data = "No contents")
        render status: 400, pretty_json: { status: 400, message: 'Bad Request', data: data }
    end

    # 401 Unauthorized
    def response_unauthorized
        render status: 401, pretty_json: { status: 401, message: 'Unauthorized' }
    end

    # 404 Not Found
    def response_not_found(class_name = 'page')
        render status: 404, pretty_json: { status: 404, message: "#{class_name.capitalize} Not Found" }
    end

    # 409 Conflict
    def response_conflict(class_name, data = "No contents")
        render status: 409, pretty_json: { status: 409, message: "#{class_name.capitalize} Conflict", data: data }
    end

    # 500 Internal Server Error
    def response_internal_server_error(data = "No contents")
        render status: 500, pretty_json: { status: 500, message: 'Internal Server Error', data: data }
    end

end
