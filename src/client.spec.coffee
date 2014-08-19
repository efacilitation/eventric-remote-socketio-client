chai   = require 'chai'
expect = chai.expect
sinon  = require 'sinon'

describe 'SocketIORemoteService', ->
  socketIORemoteClient = null
  sandbox = null
  socketIOClientStub = null

  beforeEach ->
    sandbox = sinon.sandbox.create()
    socketIOClientStub = sandbox.stub()
    socketIOClientStub.on = sandbox.stub()
    socketIOClientStub.emit = sandbox.stub()
    socketIOClientStub.removeListener = sandbox.stub()
    socketIORemoteClient = require './client'


  afterEach ->
    sandbox.restore()


  describe '#initialize', ->
    it 'should register a callback for RPC_Response which makes use of setTimeout', ->
      socketIOClientStub.on.yields()
      sandbox.stub(global, 'setTimeout')
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub
      expect(socketIOClientStub.on.calledWith 'RPC_Response', sinon.match.func).to.be.true
      expect(global.setTimeout.calledOnce).to.be.true


  describe '#rpc', ->
    it 'should emit the given payload as rpc request over socket.io-client', ->
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub
      rpcPayload =
        some: 'payload'
      socketIORemoteClient.rpc rpcPayload, ->
      expect(socketIOClientStub.emit.calledWith 'RPC_Request', rpcPayload).to.be.true


    it 'should execute the given callback upon an RPC_Response with the correct rpc id', ->
      sandbox.stub(global, 'setTimeout').yields()
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub

      callback = sandbox.spy()
      payload = {}
      socketIORemoteClient.rpc payload, callback

      responseStub =
        rpcId: payload.rpcId
        err: null
        data: {}

      rpcResponseHandler = socketIOClientStub.on.firstCall.args[1]
      rpcResponseHandler responseStub
      expect(callback.calledWith responseStub.err, responseStub.data).to.be.true


  describe '#subscribe', ->
    handler = null

    beforeEach ->
      handler = ->
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub
      socketIORemoteClient.subscribe 'context/event/id', handler


    it 'should join the given channel', ->
      expect(socketIOClientStub.emit.calledWith 'JoinRoom', 'context/event/id').to.be.true


    it 'should subscribe to the given event', ->
      expect(socketIOClientStub.on.calledWith 'context/event/id', handler).to.be.true


  describe '#unsubscribe', ->
    handler = null

    beforeEach ->
      handler = ->
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub


    it 'should unsubscribe to the given event', ->
      socketIORemoteClient.subscribe 'context/event/id', handler
      socketIORemoteClient.unsubscribe 'context/event/id', handler
      expect(socketIOClientStub.removeListener.calledWith 'context/event/id', handler).to.be.true


    describe 'given there are no more handlers for this event', ->
      it 'should leave the given channel', ->
        socketIORemoteClient.subscribe 'context/event/id', handler
        socketIORemoteClient.unsubscribe 'context/event/id', handler
        expect(socketIOClientStub.emit.calledWith 'LeaveRoom', 'context/event/id').to.be.true


    describe 'given there are still handlers for this event', ->
      it 'should not leave the given channel', ->
        anotherHandler = ->
        socketIORemoteClient.subscribe 'context/event/id', handler
        socketIORemoteClient.subscribe 'context/event/id', anotherHandler
        socketIORemoteClient.unsubscribe 'context/event/id', handler
        expect(socketIOClientStub.emit.calledWith 'LeaveRoom').not.to.be.true