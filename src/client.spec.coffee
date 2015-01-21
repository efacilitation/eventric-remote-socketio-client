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
    it 'should register a callback for RPC_Response which makes use of setTimeout', ->
      socketIOClientStub.on.yields()
      sandbox.stub(global, 'setTimeout')
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub
      expect(socketIOClientStub.on.calledWith 'RPC_Response', sinon.match.func).to.be.true


  describe '#rpc', ->
    beforeEach ->
      sandbox.stub(global, 'setTimeout').yields()
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub


    it 'should emit the given payload as rpc request over socket.io-client', ->
      rpcPayload =
        some: 'payload'
      socketIORemoteClient.rpc rpcPayload
      expect(socketIOClientStub.emit.calledWith 'RPC_Request', rpcPayload).to.be.true


    it 'should resolve the promise upon an RPC_Response with the correct rpc id', (done) ->
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

    beforeEach ->
      socketIORemoteClient.initialize ioClientInstance: socketIOClientStub

    it 'should emit the given payload as rps request over socket.io-client', ->
      subscriber =
        id: 1
        fn: sandbox.stub()

      rpcPayload =
        some: 'payload'
        subscriberId: subscriber.id

      socketIORemoteClient.subscribe rpcPayload, subscriber
      expect(socketIOClientStub.emit.calledWith 'RPS_Request', rpcPayload).to.be.true