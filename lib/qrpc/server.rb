# encoding: utf-8
require "qrpc/job"
require "qrpc/dispatcher"
require "qrpc/locator"
require "em-beanstalk"
require "eventmachine"
require "base64"

module QRPC
    
    ##
    # Queue RPC server.
    #
    
    class Server
    
        ##
        # Prefix for handled queues.
        #
        
        QRPC_PREFIX = "qrpc"
        
        ##
        # Input queue postfix.
        #
        
        QRPC_POSTFIX_INPUT = "input"
        
        ##
        # Output queue postfix.
        #
        
        QRPC_POSTFIX_OUTPUT = "output"

        ##
        # Holds API instance.
        #
        
        @api
        
        ##
        # Holds input locator.
        #
        
        @locator
        
        ##
        # Holds output queue name.
        #
        
        @output_name
        
        ##
        # Holds input queue instance.
        #
        
        @input_queue
        
        ##
        # Holds output queue instance.
        #
        
        @output_queue
        
        ##
        # Holds job dispatcher.
        #
        
        @dispatcher
        
        ##
        # Cache of output names.
        #
        
        @output_name_cache
        
        ##
        # Holds servers for finalizing.
        #
        
        @@servers = { }

        ##
        # Constructor.
        #
        
        def initialize(api)
            @api = api
            @output_name_cache = { }
            
            # Destructor
            ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)
            @@servers[self.object_id] = self
        end
        
        ##
        # Finalizer handler.
        #
        
        def self.finalize(id)
            if @@servers.has_key? id
                @@servers[id].finalize!
            end
        end
        
        ##
        # Destructor
        #
        
        def finalize!
            if @input_queue
                @input_queue.watch("default") do
                    @input_queue.ignore(@input_name) do
                        @input_queue.close
                    end
                end
            end
            
            if @output_queue
                @output_queue.use("default") do
                    @output_queue.close
                end
            end
        end
        

        ##
        # Listens to the queue.
        # (Blocking call which starts eventmachine.)
        #

        def listen!(locator, opts = { })
            EM.run do
                self.start_listening(locator, opts)
            end
        end
        
        ##
        # Starts listening to the queue.
        # (Blocking queue which expect, eventmachine is started.)
        #
        
        def start_listening(locator, opts)
            @locator = locator
            @locator.queue = self.class::QRPC_PREFIX.dup << "-" << @locator.queue << "-" << self.class::QRPC_POSTFIX_INPUT
            @dispatcher = QRPC::Server::Dispatcher::new(opts[:max_jobs])
            
            # Cache cleaning dispatcher
            EM.add_periodic_timer(20) do
                @output_name_cache.clear
            end

            # Process input queue
            self.input_queue do |queue|
                queue.each_job do |job|
                    self.process_job(job)
                end
            end
        end
        
        ##
        #
        
        ##
        # Returns input queue.
        # (Callable from EM only.)
        #
        
        def input_queue(&block)
            if not @input_queue
                @input_queue = EM::Beanstalk::new(:host => @locator.host, :port => @locator.port)
                @input_queue.watch(@locator.queue) do
                    @input_queue.ignore("default") do
                        block.call(@input_queue)
                    end
                end
            end
            
            block.call(@input_queue)
        end
        
        ##
        # Returns output queue.
        # (Callable from EM only.)
        #
        
        def output_queue
            if not @output_queue
                @output_queue = EM::Beanstalk::new(:host => @locator.host, :port => @locator.port)
            end
            
            return @output_queue
        end
        
        ##
        # Returns output name for client name.
        #
        # @param [String, Symbol] client  client identifier
        # @return [Symbol] output name
        #
        
        def output_name(client)
            client_index = client.to_sym
            
            if not @output_name_cache.include? client_index
               output_name = self.class::QRPC_PREFIX.dup << "-" << client.to_s << "-" << self.class::QRPC_POSTFIX_OUTPUT
               @output_name_cache[client_index] = output_name.to_sym
            else
                output_name = @output_name_cache[client_index]
            end
               
            return output_name
        end
        
        
        protected
        
        ##
        # Process one job.
        #
        
        def process_job(job)
            our_job = QRPC::Server::Job::new(@api, job) 
            our_job.callback do |result|
                call = Proc::new { self.output_queue.put(result[:output]) }
                output_name = self.output_name(result[:client])
                
                self.output_queue.list(:used) do |used|
                    if used.to_sym != output_name 
                        self.output_queue.use(output_name.to_s, &call)
                    else
                        call.call
                    end
                end
            end
            
            @dispatcher.put(our_job)
        end
        
    end
end
