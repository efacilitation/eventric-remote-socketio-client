chai     = require 'chai'
expect   = chai.expect
eventric = require 'eventric'
sinon    = require 'sinon'

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

    it 'should return an unique subscriber id', ->
      subscriberId1 = socketIORemoteClient.subscribe 'context', handler
      subscriberId2 = socketIORemoteClient.subscribe 'context', handler
      expect(subscriberId1).to.be.a 'object'
      expect(subscriberId2).to.be.a 'object'
      expect(subscriberId1).not.to.equal subscriberId2


    describe 'given only a context name', ->
      beforeEach ->
        socketIORemoteClient.subscribe 'context', handler


      it 'should join the correct channel', ->
        expect(socketIOClientStub.emit.calledWith 'JoinRoom', 'context').to.be.true


      it 'should subscribe to the correct event', ->
        expect(socketIOClientStub.on.calledWith 'context', handler).to.be.true


    describe 'given a context name and event name', ->
      beforeEach ->
        socketIORemoteClient.subscribe 'context', 'EventName', handler


      it 'should join the correct channel', ->
        expect(socketIOClientStub.emit.calledWith 'JoinRoom', 'context/EventName').to.be.true


      it 'should subscribe to the correct event', ->
        expect(socketIOClientStub.on.calledWith 'context/EventName', handler).to.be.true


    describe 'given a context name, event name and aggregate id', ->
      beforeEach ->
        socketIORemoteClient.subscribe 'context', 'EventName', '12345', handler


      it 'should join the correct channel', ->
        expect(socketIOClientStub.emit.calledWith 'JoinRoom', 'context/EventName/12345').to.be.true


      it 'should subscribe to the correct event', ->
        expect(socketIOClientStub.on.calledWith 'context/EventName/12345', handler).to.be.true


  describe '#unsubscribe', ->
    handler = null

    beforeEach ->
      handler = ->
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub


    it 'should unsubscribe from the given event', ->
      socketIORemoteClient.subscribe 'context/EventName/12345', handler
      .then (subscriberId) ->
        socketIORemoteClient.unsubscribe subscriberId
        expect(socketIOClientStub.removeListener.calledWith 'context/EventName/12345', handler).to.be.true


    describe 'given there are no more handlers for this event', ->
      it 'should leave the given channel', ->
        socketIORemoteClient.subscribe 'context', 'EventName', '12345', handler
        .then (subscriberId1) ->
          socketIORemoteClient.unsubscribe subscriberId1
          expect(socketIOClientStub.emit.calledWith 'LeaveRoom', 'context/EventName/12345').to.be.true


    describe 'given there are still handlers for this event', ->
      it 'should not leave the given channel', ->
        subscriberId1Promise = socketIORemoteClient.subscribe 'context', 'EventName', '12345', handler
        subscriberId2Promise = socketIORemoteClient.subscribe 'context', 'EventName', '12345', handler
        Promise.all [subscriberId1Promise, subscriberId2Promise]
        .then (subscriberIds) ->
          socketIORemoteClient.unsubscribe subscriberIds[1]
          expect(socketIOClientStub.emit.calledWith 'LeaveRoom').not.to.be.true
