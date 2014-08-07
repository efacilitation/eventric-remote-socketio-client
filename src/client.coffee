class SocketIORemoteServiceClient

  initialize: ([options]..., callback=->) ->
    options ?= {}

    @_callbacks = {}

    if options.ioClientInstance
      @_io_socket = options.ioClientSocket
      @_initializeRPCResponseListener callback
    else
      @_io_socket = require('socket.io-client')('http://localhost:3000')
      @_io_socket.on 'connect', =>
        @_initializeRPCResponseListener callback


  _initializeRPCResponseListener: (callback) ->
    @_io_socket.on 'RPC_Response', (response) =>
      if not response.rpcId
        throw new Error 'Missing rpcId in RPC Response'

      if response.rpcId not of @_callbacks
        throw new Error "No callback registered for id #{response.rpcId}"

      @_callbacks[response.rpcId] response.err, response.data
      delete @_callbacks[response.rpcId]

    callback()


  rpc: (payload, callback = ->) ->
    rpcId = @_generateUid()
    payload.rpcId = rpcId
    @_callbacks[rpcId] = callback
    @_io_client.emit 'RPC_Request', payload


  _handleRpcResponse: (response) ->
    if not response.rpcId
      throw new Error 'Missing rpcId in RPC Response'
    if response.rpcId not of @_callbacks
      throw new Error "No callback registered for id #{response.rpcId}"
    @_callbacks[response.rpcId] response.err, response.data
    delete @_callbacks[response.rpcId]


  _generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


module.exports = new SocketIORemoteServiceClient
