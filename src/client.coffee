class SocketIORemoteServiceClient

  initialize: (options = {}) ->
    @_subscribers = {}
    @_promises = {}

    @_initializeSocketIo options


  _initializeSocketIo: (options) ->  new Promise (resolve, reject) =>
    if options.ioClientInstance
      @_io_socket = options.ioClientInstance
      @_initializeRPCResponseListener()
      resolve()
    else
      @_io_socket = require('socket.io-client')('http://localhost:3000')
      @_io_socket.on 'connect', =>
        @_initializeRPCResponseListener()
        resolve()


  _initializeRPCResponseListener: ->
    @_io_socket.on 'RPC_Response', @_handleRpcResponse
    @_io_socket.on 'RPS_Response', @_handleRpsResponse
    @_io_socket.on 'RPS_Publish',  @_handleRpsPublish


  subscribe: (payload, subscriber) ->  new Promise (resolve, reject) =>
    if not subscriber.fn
      throw new Error 'Missing subscriber function'
    @_subscribers[subscriber.id] = subscriber.fn
    rpsId = @_generateUid()
    payload.rpsId = rpsId
    payload.subscriberId = subscriber.id
    @_promises[rpsId] =
      resolve: resolve
      reject: reject
    @_io_socket.emit 'RPS_Request', payload


  unsubscribe: (subscriberId) ->  new Promise (resolve, reject) =>
    # TODO: remove subscriber on context too
    delete @_subscribers[subscriberId]
    resolve()


  rpc: (payload) ->  new Promise (resolve, reject) =>
    rpcId = @_generateUid()
    payload.rpcId = rpcId
    @_promises[rpcId] =
      resolve: resolve
      reject: reject
    @_io_socket.emit 'RPC_Request', payload


  _handleRpcResponse: (response) =>
    if not response.rpcId
      throw new Error 'Missing rpcId in RPC Response'
    if response.rpcId not of @_promises
      throw new Error "No promise registered for id #{response.rpcId}"
    if response.err
      @_promises[response.rpcId].reject response.err
    else
      @_promises[response.rpcId].resolve response.data
    delete @_promises[response.rpcId]


  _handleRpsResponse: (response) =>
    if not response.rpsId
      throw new Error 'Missing rpsId in RPS Response'
    if response.rpsId not of @_promises
      throw new Error "No promise registered for id #{response.rpsId}"
    if response.err
      @_promises[response.rpsId].reject response.err
    else
      @_promises[response.rpsId].resolve response.data
    delete @_promises[response.rpsId]


  _handleRpsPublish: (publish) =>
    if not publish.subscriberId
      throw new Error 'Missing subscriberId in RPS Publish'
    if publish.subscriberId not of @_subscribers
      throw new Error "No subscriber registered for id #{publish.subscriberId}"
    @_subscribers[publish.subscriberId] publish.payload


  _generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


  disconnect: ->
    @_io_socket.disconnect()


module.exports = new SocketIORemoteServiceClient
