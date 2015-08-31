require('es6-promise').polyfill()

chai     = require 'chai'
expect   = chai.expect
eventric = require 'eventric'
sinon    = require 'sinon'

describe 'Remote SocketIO Client', ->
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

    it 'should register a callback for eventric:rpcResponse which makes use of setTimeout', ->
      socketIOClientStub.on.yields()
      sandbox.stub global, 'setTimeout'
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub
      expect(socketIOClientStub.on.calledWith 'eventric:rpcResponse', sinon.match.func).to.be.true
      expect(global.setTimeout.calledOnce).to.be.true


  describe '#rpc', ->

    beforeEach ->
      sandbox.stub(global, 'setTimeout').yields()
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub


    it 'should emit the given payload as rpc request over socket.io-client', ->
      rpcPayload =
        some: 'payload'
      socketIORemoteClient.rpc rpcPayload, ->
      expect(socketIOClientStub.emit.calledWith 'eventric:rpcRequest', rpcPayload).to.be.true


    it 'should reject the promise given an error instance in the rpc response', (done) ->
      payload = {}
      socketIORemoteClient.rpc payload
      .catch (error) ->
        expect(error instanceof Error).to.be.true
        expect(error.message).to.contain 'The error message'
        done()

      responseStub =
        rpcId: payload.rpcId
        error: new Error 'The error message'

      rpcResponseHandler = socketIOClientStub.on.firstCall.args[1]
      rpcResponseHandler responseStub


    it 'should reject the promise and convert error objects to error instances given an error object in the rpc response', (done) ->
      payload = {}
      socketIORemoteClient.rpc payload
      .catch (error) ->
        expect(error instanceof Error).to.be.true
        expect(error.message).to.contain 'The error message'
        done()

      responseStub =
        rpcId: payload.rpcId
        error: message: 'The error message'

      rpcResponseHandler = socketIOClientStub.on.firstCall.args[1]
      rpcResponseHandler responseStub


    it 'should resolve the promise upon a rpc response with the correct rpc id', (done) ->
      payload = {}
      socketIORemoteClient.rpc payload
      .then ->
        done()

      responseStub =
        rpcId: payload.rpcId
        data: {}

      rpcResponseHandler = socketIOClientStub.on.firstCall.args[1]
      rpcResponseHandler responseStub


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
        expect(socketIOClientStub.emit.calledWith 'eventric:joinRoom', 'context').to.be.true


      it 'should subscribe to the correct event', ->
        expect(socketIOClientStub.on.calledWith 'context', handler).to.be.true


    describe 'given a context name and event name', ->

      beforeEach ->
        socketIORemoteClient.subscribe 'context', 'EventName', handler


      it 'should join the correct channel', ->
        expect(socketIOClientStub.emit.calledWith 'eventric:joinRoom', 'context/EventName').to.be.true


      it 'should subscribe to the correct event', ->
        expect(socketIOClientStub.on.calledWith 'context/EventName', handler).to.be.true


    describe 'given a context name, event name and aggregate id', ->

      beforeEach ->
        socketIORemoteClient.subscribe 'context', 'EventName', '12345', handler


      it 'should join the correct channel', ->
        expect(socketIOClientStub.emit.calledWith 'eventric:joinRoom', 'context/EventName/12345').to.be.true


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
          expect(socketIOClientStub.emit.calledWith 'eventric:leaveRoom', 'context/EventName/12345').to.be.true


    describe 'given there are still handlers for this event', ->

      it 'should not leave the given channel', ->
        subscriberId1Promise = socketIORemoteClient.subscribe 'context', 'EventName', '12345', handler
        subscriberId2Promise = socketIORemoteClient.subscribe 'context', 'EventName', '12345', handler
        Promise.all [subscriberId1Promise, subscriberId2Promise]
        .then (subscriberIds) ->
          socketIORemoteClient.unsubscribe subscriberIds[1]
          expect(socketIOClientStub.emit.calledWith 'eventric:leaveRoom').not.to.be.true
