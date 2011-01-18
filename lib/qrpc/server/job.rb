# encoding: utf-8

require "eventmachine"
require "json-rpc-objects/request"
require "json-rpc-objects/response"
require "json-rpc-objects/error"

module QRPC
    class Server

        ##
        # Queue RPC job.
        #
        
        class Job
            include EM::Deferrable
            
            ##
            # Indicates default priority.
            #
            
            DEFAULT_PRIORITY = 50
            
            ##
            # Holds beanstalk job.
            #
            
            @job
            
            ##
            # Holds JSON-RPC request.
            #
            
            @request
            
            ##
            # Holds API object.
            #
            
            @api
            
            ##
            # Constructor.
            #
            # @param [Object] object which will serve as API
            # @param [EM::Beanstalk::Job] job beanstalk job
            #
            
            def initialize(api, job)
                @api = api
                @job = job
            end
            
            ##
            # Starts processing.
            #
            
            def process!
                result = nil
                error = nil
                request = self.request
                
                begin
                    result = @api.send(request.method, *request.params)
                rescue ::Exception => e
                    error = self.generate_error(request, e)
                end

                response = request.class::version.response::create(result, error, :id => request.id)
                response.qrpc = { :version => :"1.0" }
                
                @job.delete()
                self.set_deferred_status(:succeeded, response.to_json)
            end
            
            ##
            # Returns job in request form.
            # @return [JsonRpcObjects::Generic::Object] request associated to job
            #
            
            def request
                if @request.nil?
                    @request = JsonRpcObjects::Request::parse(@job.body)
                end
                
                return @request
            end
            
            ##
            # Returns job priority according to request.
            #
            # Default priority is 50. You can scale up and down according
            # to your needs in fact without limits.
            #
            # @return [Integer] priority level
            #
            
            def priority
                priority = self.request.qrpc["priority"]
                if priority.nil?
                    priority = self.class::DEFAULT_PRIORITY
                else
                    priority = priority.to_i
                end
                
                return priority
            end
            
            ##
            # Returns client identifier.
            # @return [String] client identifier
            #
            
            def client
                self.request.qrpc["client"]
            end
            
            
            protected
            
            ##
            # Generates error from exception.
            #
            
            def generate_error(request, exception)
                data = {
                    :name => exception.class.name,
                    :message => exception.message,
                    :backtrace => exception.backtrace.map { |s| Base64.encode64(s) },
                    :dump => {
                        :raw => Base64.encode64(Marshal.dump(exception)),
                        :format => :Ruby,
                    }
                }
                
                request.class::version.error::create(100, "exception raised during processing the request", :error => data)
            end
              
        end
    end
end