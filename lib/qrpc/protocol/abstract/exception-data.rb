# encoding: utf-8
# (c) 2011 Martin Kozák (martinkozak@martinkozak.net)

require "abstract"
require "qrpc/general"
require "qrpc/protocol/abstract/object"

##
# General QRPC module.
#

module QRPC
    
    ##
    # Protocols helper module.
    # @since 0.9.0
    #
    
    module Protocol

        ##
        # Abstract protocol implementation.
        # @since 0.9.0
        #
        
        class Abstract
        
            ##
            # Abstract exception data object implementation.
            #
            # @since 0.9.0
            # @abstract
            #
            
            class ExceptionData < Object
              
                ##
                # Constructor.
                #
                # @param [Hash] init  initial options
                # @abstract
                #
                
                def initialize(init = { })
                    super(init)
                    if self.instance_of? QrpcObject
                        not_implemented
                    end
                end

            end
        end
    end
end