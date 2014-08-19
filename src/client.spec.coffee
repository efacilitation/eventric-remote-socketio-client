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
    socketIOClientStub.join = sandbox.stub()
    socketIOClientStub.on = sandbox.stub()
    socketIOClientStub.emit = sandbox.stub()
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
      socketIORemoteClient.subscribe 'channel/event/id', 'event', handler


    it 'should join the given channel', ->
      expect(socketIOClientStub.join.calledWith 'channel/event/id').to.be.true


    it 'should subscribe to the given event', ->
      expect(socketIOClientStub.on.calledWith 'event', handler).to.be.true

