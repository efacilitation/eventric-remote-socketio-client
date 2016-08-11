require('es6-promise').polyfill()

chai     = require 'chai'
expect   = chai.expect
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


    it 'should emit an eventric:rpcRequest event with the given payload', ->
      rpcPayload =
        some: 'payload'
      socketIORemoteClient.rpc rpcPayload
      expect(socketIOClientStub.emit.calledWith 'eventric:rpcRequest', rpcPayload).to.be.true


    it 'should resolve with the correct response data given a rpc response', (done) ->
      payload = {}
      socketIORemoteClient.rpc payload
      .then (responseData) ->
        expect(responseData).to.equal responseStub.data
        done()

      responseStub =
        rpcId: payload.rpcId
        data: {}

      rpcResponseHandler = socketIOClientStub.on.firstCall.args[1]
      rpcResponseHandler responseStub


    it 'should reject with an error given a rpc response with an error', ->
      payload = {}
      socketIORemoteClient.rpc payload
      .catch (error) ->
        expect(error).to.be responseStub.error
        done()

      responseStub =
        rpcId: payload.rpcId
        error: new Error 'The error message'

      rpcResponseHandler = socketIOClientStub.on.firstCall.args[1]
      rpcResponseHandler responseStub


    it 'should reject with an error given a rpc response with an error like object', (done) ->
      payload = {}
      socketIORemoteClient.rpc payload
      .catch (error) ->
        expect(error instanceof Error).to.be.true
        expect(error.name).to.equal 'SomeError'
        expect(error.message).to.equal 'The error message'
        done()

      responseStub =
        rpcId: payload.rpcId
        error:
          name: 'SomeError'
          message: 'The error message'

      rpcResponseHandler = socketIOClientStub.on.firstCall.args[1]
      rpcResponseHandler responseStub


    it 'should preserve all custom properties given a rpc response with an error like object with custom properties', (done) ->
      payload = {}
      socketIORemoteClient.rpc payload
      .catch (error) ->
        expect(error instanceof Error).to.be.true
        expect(error.customProperty).to.equal 'customValue'
        done()

      responseStub =
        rpcId: payload.rpcId
        error:
          name: 'SomeError'
          message: 'The error message'
          customProperty: 'customValue'

      rpcResponseHandler = socketIOClientStub.on.firstCall.args[1]
      rpcResponseHandler responseStub


  describe '#subscribe', ->
    handler = null

    beforeEach ->
      handler = ->
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub

    it 'should return an unique subscriber id', ->
      socketIORemoteClient.subscribe 'context', handler
      .then (subscriberId1) ->
        expect(subscriberId1).to.be.a 'number'
        socketIORemoteClient.subscribe 'context', handler
        .then (subscriberId2) ->
          expect(subscriberId2).to.be.a 'number'
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
