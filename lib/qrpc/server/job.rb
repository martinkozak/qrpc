# encoding: utf-8
require "eventmachine"
require "json-rpc-objects/request"
require "json-rpc-objects/response"
require "json-rpc-objects/error"
require "qrpc/general"
require "qrpc/protocol/qrpc-object"
require "qrpc/protocol/exception-data"


##
# General QRPC module.
#

module QRPC
    class Server

        ##
        # Queue RPC job.
        #
        
        class Job
            include EM::Deferrable
            
            ##
            # Indicates default priority.
            # @deprecated (since 0.2.0)
            #
            
            DEFAULT_PRIORITY = QRPC::DEFAULT_PRIORITY
            
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
            # Indicates API methods synchronicity.
            # @since 0.4.0
            #
            
            @synchronicity
            
            ##
            # Holds data serializer.
            # @since 0.4.0
            #
            
            @serializer
            
            ##
            # Constructor.
            #
            # @param [Object] object which will serve as API
            # @param [Symbol] synchronicity  API methods synchronicity
            # @param [EM::Beanstalk::Job] job beanstalk job
            # @param [JsonRpcObjects::Serializer] serializer data serializer
            #
            
            def initialize(api, synchronicity, job, serializer = QRPC::default_serializer)
                @api = api
                @synchronicity = synchronicity
                @job = job
                @serializer = serializer
            end
            
            ##
            # Starts processing.
            #
            
            def process!
                result = nil
                error = nil
                request = self.request
                
                finalize = Proc::new do
                    response = request.class::version.response::create(result, error, :id => request.id)
                    response.serializer = @serializer
                    response.qrpc = QRPC::Protocol::QrpcObject::create.output
                    self.set_deferred_status(:succeeded, response.serialize)
                end

                
                if @synchronicity == :synchronous
                    begin
                        result = @api.send(request.method, *request.params)
                    rescue ::Exception => e
                        error = self.generate_error(request, e)
                    end

                    finalize.call()
                else                
                    begin
                        @api.send(request.method, *request.params) do |res|
                            result = res
                            finalize.call()
                        end
                    rescue ::Exception => e
                        error = self.generate_error(request, e)
                        finalize.call()
                    end                    
                end
            end

            ##
            # Returns job in request form.
            # @return [JsonRpcObjects::Generic::Object] request associated to job
            #
            
            def request
                if @request.nil?
                    @request = JsonRpcObjects::Request::parse(@job, :wd, @serializer)
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
                    priority = QRPC::DEFAULT_PRIORITY
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
                data = QRPC::Protocol::ExceptionData::create(exception)
                request.class::version.error::create(100, "exception raised during processing the request", :error => data.output)
            end
              
        end
    end
end
