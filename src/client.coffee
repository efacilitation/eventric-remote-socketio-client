class SocketIORemoteServiceClient

  initialize: (options = {}) ->
    @_subscriberId = 0
    @_rpcId = 0
    @_subscribers = []
    @_promises = {}

    @_initializeSocketIo options


  _initializeSocketIo: ({ioClientInstance}) ->
    new Promise (resolve, reject) =>
      @_io_socket = ioClientInstance
      @_initializeRPCResponseListener()
      resolve()


  _initializeRPCResponseListener: ->
    @_io_socket.on 'eventric:rpcResponse', (response) =>
      setTimeout =>
        @_handleRpcResponse response
      , 0


  rpc: (payload) ->
    new Promise (resolve, reject) =>
      rpcId = @_getNextRpcId()
      payload.rpcId = rpcId
      @_promises[rpcId] =
        resolve: resolve
        reject: reject
      @_io_socket.emit 'eventric:rpcRequest', payload


  _getNextRpcId: ->
    @_rpcId++


  _handleRpcResponse: (response) ->
    if not response.rpcId?
      throw new Error 'Missing rpcId in RPC Response'
    if response.rpcId not of @_promises
      throw new Error "No promise registered for id #{response.rpcId}"
    if response.err
      @_promises[response.rpcId].reject response.err
    else
      @_promises[response.rpcId].resolve response.data
    delete @_promises[response.rpcId]


  subscribe: (context, [domainEventName, aggregateId]..., subscriberFn) ->
    new Promise (resolve, reject) =>
      fullEventName = @_getFullEventName context, domainEventName, aggregateId
      subscriber =
        eventName: fullEventName
        subscriberFn: subscriberFn
        subscriberId: @_getNextSubscriberId()
      @_io_socket.emit 'JoinRoom', fullEventName
      @_io_socket.on fullEventName, subscriberFn
      @_subscribers.push subscriber
      resolve subscriber.subscriberId


  unsubscribe: (subscriberId) ->
    new Promise (resolve, reject) =>
      matchingSubscriber = @_subscribers.filter((x) ->
        x.subscriberId is subscriberId
      )[0]
      @_subscribers = @_subscribers.filter (x) ->
        x isnt matchingSubscriber
      @_io_socket.removeListener matchingSubscriber.eventName, matchingSubscriber.subscriberFn
      othersHaveSubscribedToThisEvent = @_subscribers.some (x) ->
        x.eventName is matchingSubscriber.eventName
      if not othersHaveSubscribedToThisEvent
        @_io_socket.emit 'LeaveRoom', matchingSubscriber.eventName
      resolve()


  _getNextSubscriberId: ->
    @_subscriberId++


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
