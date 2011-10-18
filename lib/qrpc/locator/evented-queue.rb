# encoding: utf-8
# (c) 2011 Martin Kozák (martinkozak@martinkozak.net)

require "hash-utils/array"
require "unified-queues"
require "evented-queue"
require "priority_queue"

##
# General QRPC module.
#

module QRPC
    
    ##
    # Resource locators.
    #
    
    module Locator
      
        ##
        # Locator for 'evented-queue' queue type.
        # @see https://github.com/martinkozak/evented-queue
        # 
        
        class EventedQueueLocator
  
            ##
            # Contains queue instance.
            # @return [EventedQueue::Recurring]
            #
    
            attr_accessor :queue
            @queue
            
            ##
            # Constructor.
            # @param [EventedQueue::Recurring] queue  recurring evented queue instance
            #
            
            def initialize(queue = self.default_queue)
                @queue = queue
            end
            
            ##
            # Returns the default evented queue type.
            #
            
            def default_queue 
                UnifiedQueues::Multi::new UnifiedQueues::Single, ::EventedQueue::Recurring, UnifiedQueues::Single::new(CPriorityQueue)
            end
            
            alias :input_queue :queue
            alias :output_queue :queue
            
        end
    end
end

=begin
q = QRPC::Locator::EventedQueue::new
q.input_queue.use(:xyz)
q.queue.push(:x, 2)
q.queue.push(:y, 3)
q.queue.subscribe(:xyz)
q.queue.pop do |i|
    p i
end
q.queue.push(:z, 1)
=end