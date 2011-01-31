# encoding: utf-8
require "em-beanstalk"
require "uuid"
require "qrpc/general"

##
# General QRPC module.
#

module QRPC
    
    ##
    # Queue RPC client.
    # @since 0.2.0
    #
    
    class Client
    
        ##
        # Indicates timeout for results pooling throttling in secconds.
        #
        
        RESULTS_POOLING_THROTTLING_TIMEOUT = 4
    
        ##
        # Holds locator of the target queue.
        #
        
        @locator
        
        ##
        # Holds client session ID.
        #
        
        @id
        
        ##
        # Holds input queue name.
        #
        
        @input_name
        
        ##
        # Holds input queue instance.
        #
        
        @input_queue
        
        ##
        # Holds output queue name.
        #
        
        @output_name
        
        ##
        # Holds output queue instance.
        #
        
        @output_queue
        
        ##
        # Indicates, results pooling is ran.
        #
        
        @pooling
        
        ##
        # Holds clients for finalizing.
        #
        
        @@clients = { }
        
        
        ##
        # Constructor.
        #
        
        def initialize(locator)
            @locator = locator
            @pooling = false
        
            # Destructor
            ObjectSpace.define_finalizer(self, self.class.method(:finalize).to_proc)
            @@clients[self.object_id] = self
        end
        
        ##
        # Finalizer handler.
        # @param [Integer] id id of finalized instance
        #
        
        def self.finalize(id)
            if @@clients.has_key? id
                @@clients[id].finalize!
            end
        end
        
        ##
        # Destructor.
        #
        
        def finalize!
            if not @input_queue.nil?
                @input_queue.watch("default") do
                    @input_queue.ignore(@input_name) do
                        @input_queue.close
                    end
                end
            end
            
            if not @output_queue.nil?
                @output_queue.use("default") do
                    @output_queue.close
                end
            end
        end
        
        ##
        # Handles call to RPC. (*********)
        #
        # Be warn, arguments will be serialized to JSON, so they should
        # be serializable nativelly or implement +#to_json+ method.
        #
        
        def method_missing(name, *args, &block)
            self.put(self.create_job(name, args, &block))
        end
        
        ##
        # Creates job associated to this client session.
        #
        
        def create_job(name, args, priority = QRPC::DEFAULT_PRIORITY, &block)
            Client::Job::new(self.id, name, args, priority, &block)
        end
        
        ##
        # Puts job to client.
        #
        
        def put(job)
            if not job.notification?
                @jobs[job.id] = job
            end
            
            self.output_queue do |queue|
                queue.put(job.to_json)
            end
            
            if (not @pooling) and (@jobs.length > 0)
                self.pool!
            end
        end
        
        ##
        # Starts input (results) pooling.
        #
        
        def pool!
            
            # Results processing logic
            processor = Proc::new do |job|
                
            end
            
            # Runs processor for each job, if no job available
            #   and any results came, terminates pooling. In 
            #   otherwise restarts pooling.

            worker = EM.spawn do                
                self.input_queue do |queue|
                    queue.each_job(self.class::RESULTS_POOLING_THROTTLING_TIMEOUT, &processor).on_error do |error|
                        if error == :timed_out
                            if @jobs.length > 0
                                self.pool!
                            else
                                @pooling = false
                            end
                        else
                            raise Exception::new("Beanstalk error: " << error.to_s)
                        end
                    end
                end
            end
            
            ##
            
            worker.run
            @pooling = true
            
        end
        
        ##
        # Returns input name.
        #
        
        def input_name
            if @input_name.nil?
                @input_name = (QRPC::QUEUE_PREFIX.dup << "-" << self.id << "-" << QRPC::QUEUE_POSTFIX_OUTPUT).to_sym
            end
            
            return @input_name
        end
        
        ##
        # Returns input queue.
        # (Callable from EM only.)
        #
        # @return [EM::Beanstalk] input queue Beanstalk connection
        #
        
        def input_queue(&block)
            if @input_queue.nil?
                @input_queue = EM::Beanstalk::new(:host => @locator.host, :port => @locator.port)
                @input_queue.watch(self.input_name.to_s) do
                    @input_queue.ignore("default") do
                        block.call(@input_queue)
                    end
                end
            else
                block.call(@input_queue)
            end
        end
        
        ##
        # Returns output name.
        #
        
        def output_name
            if @output_name.nil?
                @output_name = (QRPC::QUEUE_PREFIX.dup << "-" << @locator.queue << "-" << QRPC::QUEUE_POSTFIX_INPUT).to_sym
            end
            
            return @output_name
        end
        
        ##
        # Returns output queue.
        # (Callable from EM only.)
        #
        # @return [EM::Beanstalk] output queue Beanstalk connection
        #
        
        def output_queue(&block)
            if @output_queue.nil?
                @output_queue = EM::Beanstalk::new(:host => @locator.host, :port => @locator.port)
                @output_queue.use(self.output_name.to_s) do
                    block.call(@output_queue)
                end
            else
                block.call(@output_queue)
            end
        end
        
        ##
        # Returns client (or maybe session is better) ID.
        #
        
        def id
            if @id.nil?
                @id = UUID.generate
            end
            
            return @id
        end
                
    end
end