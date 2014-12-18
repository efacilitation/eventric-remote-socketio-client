class SocketIORemoteServiceClient

  initialize: (options = {}, callback = ->) ->
    @_subscribers = []
    @_callbacks = {}

    if options.ioClientInstance
      @_io_socket = options.ioClientInstance
      @_initializeRPCResponseListener callback
    else
      @_io_socket = require('socket.io-client')('http://localhost:3000')
      @_io_socket.on 'connect', =>
        @_initializeRPCResponseListener callback


  _initializeRPCResponseListener: (callback) ->
    @_io_socket.on 'RPC_Response', (response) =>
      setTimeout =>
        @_handleRpcResponse response
      , 0
    callback()


  _handleRPCResponse: (response) ->
    if not response.rpcId
      throw new Error 'Missing rpcId in RPC Response'

    if response.rpcId not of @_callbacks
      throw new Error "No callback registered for id #{response.rpcId}"

    @_callbacks[response.rpcId] response.err, response.data
    delete @_callbacks[response.rpcId]


  rpc: (payload, callback = ->) ->
    rpcId = @_generateUid()
    payload.rpcId = rpcId
    @_callbacks[rpcId] = callback
    @_io_socket.emit 'RPC_Request', payload


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


  subscribe: (context, [domainEventName, aggregateId]..., subscriberFn) ->
    new Promise (resolve, reject) =>
      fullEventName = @_getFullEventName context, domainEventName, aggregateId
      subscriber =
        eventName: fullEventName
        subscriberFn: subscriberFn
        subscriberId: @_generateUid()
      @_io_socket.emit 'JoinRoom', fullEventName
      @_io_socket.on fullEventName, subscriberFn
      @_subscribers.push subscriber
      resolve subscriber.subscriberId


  unsubscribe: (subscriberId) ->
    new Promise (resolve, reject) =>
      matchingSubscriber = @_subscribers.filter((x) -> x.subscriberId is subscriberId)[0]
      @_subscribers = @_subscribers.filter (x) -> x isnt matchingSubscriber
      @_io_socket.removeListener matchingSubscriber.eventName, matchingSubscriber.subscriberFn
      othersHaveSubscribedToThisEvent = @_subscribers.some (x) -> x.eventName is matchingSubscriber.eventName
      if not othersHaveSubscribedToThisEvent
        @_io_socket.emit 'LeaveRoom', matchingSubscriber.eventName


  _getFullEventName: (context, domainEventName, aggregateId) ->
    fullEventName = context
    if domainEventName
      fullEventName += "/#{domainEventName}"
    if aggregateId
      fullEventName += "/#{aggregateId}"
    fullEventName


  disconnect: ->
    @_io_socket.disconnect()


module.exports = new SocketIORemoteServiceClient
